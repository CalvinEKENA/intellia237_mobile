import { describe, expect, it } from "vitest";

import {
  crossedThreshold,
  remainingPercent,
  type ReserveAggregate,
  type ReserveThreshold,
} from "../services/studyReserve";
import {
  STUDY_RESERVE_EXHAUSTED_REASON,
  StudyReserveConsumption,
  billableFromUsage,
  studyReserveExhaustedError,
  studyReserveNotificationText,
  type CommitResult,
  type ProviderUsage,
  type ReserveHold,
  type StudyReserveConsumptionStore,
  type ThresholdNotifier,
} from "../services/studyReserveConsumption";
import type { StudyReserveProvisioningStore } from "../services/studyReserveProvisioning";
import { CurrentCycleProvisioning } from "./support/currentCycleProvisioning";

/** Aucun entitlement ni plan : la réserve est « unavailable ». */
class NoopProvisioningStore implements StudyReserveProvisioningStore {
  async resolveEntitlement() {
    return null;
  }
  async planConfig() {
    return null;
  }
  async updateCurrentCycle() {
    return null;
  }
  async readAggregate() {
    return null;
  }
  async provisionCycle(_studentId: string, fresh: ReserveAggregate) {
    return fresh;
  }
}

const noopProvisioning = new NoopProvisioningStore();

/** L'agrégat scellé dans le store est le cycle en cours d'un abonnement actif. */
const currentCycle = (store: MemoryConsumptionStore) =>
  new CurrentCycleProvisioning(async (id) => store.view(id));

interface Agg {
  allowance: number;
  consumed: number;
  cycleId: string;
  latestThresholdEmitted: ReserveThreshold | null;
  holds: Record<string, number>;
  ledger: Set<string>;
}

/** Réplique en mémoire de la logique réserve/commit/release. */
class MemoryConsumptionStore implements StudyReserveConsumptionStore {
  aggs = new Map<string, Agg>();
  parents = new Map<string, string[]>();

  seed(studentId: string, allowance: number, cycleId = "2026-06") {
    this.aggs.set(studentId, {
      allowance,
      consumed: 0,
      cycleId,
      latestThresholdEmitted: null,
      holds: {},
      ledger: new Set(),
    });
  }

  async view(studentId: string): Promise<ReserveAggregate | null> {
    const agg = this.aggs.get(studentId);
    if (!agg) return null;
    return {
      allowanceInternal: agg.allowance,
      consumed: agg.consumed,
      cycleId: agg.cycleId,
      cycleStart: null,
      cycleEnd: null,
      latestThresholdEmitted: agg.latestThresholdEmitted,
    };
  }

  private held(agg: Agg): number {
    return Object.values(agg.holds).reduce((s, v) => s + v, 0);
  }

  async reserve(p: { studentId: string; requestId: string; estimateUnits: number }): Promise<ReserveHold> {
    const agg = this.aggs.get(p.studentId);
    if (!agg || agg.allowance <= 0) return { configured: false, reserved: false };
    const remaining = agg.allowance - agg.consumed - this.held(agg);
    // L'estimation doit tenir dans le restant : pas de surconsommation possible.
    if (remaining < p.estimateUnits) {
      throw studyReserveExhaustedError();
    }
    agg.holds[p.requestId] = p.estimateUnits;
    return { configured: true, reserved: true };
  }

  async commit(p: {
    studentId: string;
    requestId: string;
    provider: string;
    model: string;
    usage: ProviderUsage;
  }): Promise<CommitResult> {
    const agg = this.aggs.get(p.studentId)!;
    delete agg.holds[p.requestId];
    const key = `${agg.cycleId}__${p.requestId}`;
    if (agg.ledger.has(key)) {
      return { duplicate: true, thresholdEvent: null, cycleId: agg.cycleId };
    }
    const prev = remainingPercent(agg.allowance, agg.consumed);
    agg.consumed += Math.max(0, p.usage.billableUnits);
    const next = remainingPercent(agg.allowance, agg.consumed);
    const event = crossedThreshold(prev, next, agg.latestThresholdEmitted);
    if (event !== null) agg.latestThresholdEmitted = event;
    agg.ledger.add(key);
    return { duplicate: false, thresholdEvent: event, cycleId: agg.cycleId };
  }

  async release(p: { studentId: string; requestId: string }): Promise<void> {
    const agg = this.aggs.get(p.studentId);
    if (agg) delete agg.holds[p.requestId];
  }

  async listLinkedParents(studentId: string): Promise<string[]> {
    return this.parents.get(studentId) ?? [];
  }
}

class RecordingNotifier implements ThresholdNotifier {
  events: { studentId: string; parentIds: string[]; threshold: ReserveThreshold }[] = [];
  async emit(p: { studentId: string; parentIds: string[]; cycleId: string; threshold: ReserveThreshold }) {
    this.events.push({ studentId: p.studentId, parentIds: p.parentIds, threshold: p.threshold });
  }
}

const usage = (billable: number): ProviderUsage => ({
  inputUnits: Math.floor(billable / 2),
  outputUnits: Math.ceil(billable / 2),
  billableUnits: billable,
});

describe("billableFromUsage", () => {
  it("uses real provider totals, not an estimate", () => {
    expect(billableFromUsage({ promptTokenCount: 120, candidatesTokenCount: 80, totalTokenCount: 205 }))
      .toEqual({ inputUnits: 120, outputUnits: 80, billableUnits: 205 });
    // Sans total : somme entrée+sortie.
    expect(billableFromUsage({ promptTokenCount: 10, candidatesTokenCount: 5 }).billableUnits).toBe(15);
  });
});

describe("StudyReserveConsumption.run", () => {
  it("records the real usage exactly once and reduces the reserve", async () => {
    const store = new MemoryConsumptionStore();
    store.seed("s1", 1000);
    const consumption = new StudyReserveConsumption(store, new RecordingNotifier(), currentCycle(store));
    const out = await consumption.run(
      { studentId: "s1", requestId: "r1", provider: "vertex-ai", model: "gemini" },
      async () => ({ result: "answer", usage: usage(250) }),
    );
    expect(out.result).toBe("answer");
    expect(store.aggs.get("s1")!.consumed).toBe(250);
  });

  it("idempotent retry does not consume twice", async () => {
    const store = new MemoryConsumptionStore();
    store.seed("s1", 1000);
    const consumption = new StudyReserveConsumption(store, new RecordingNotifier(), currentCycle(store));
    const exec = async () => ({ result: "a", usage: usage(250) });
    await consumption.run({ studentId: "s1", requestId: "r1", provider: "p", model: "m", estimateUnits: 1 }, exec);
    await consumption.run({ studentId: "s1", requestId: "r1", provider: "p", model: "m", estimateUnits: 1 }, exec);
    expect(store.aggs.get("s1")!.consumed).toBe(250);
  });

  it("concurrent reservations cannot overspend the reserve", async () => {
    const store = new MemoryConsumptionStore();
    store.seed("s1", 1000);
    // La première requête réserve le budget restant ; une seconde requête
    // simultanée voit la réservation (et non le même solde pré-consommation) et
    // est refusée — impossible de surconsommer.
    await store.reserve({ studentId: "s1", requestId: "a", estimateUnits: 1000 });
    await expect(
      store.reserve({ studentId: "s1", requestId: "b", estimateUnits: 500 }),
    ).rejects.toMatchObject({ code: "resource-exhausted" });
    // Après release de la première, une réservation redevient possible.
    await store.release({ studentId: "s1", requestId: "a" });
    await expect(
      store.reserve({ studentId: "s1", requestId: "b", estimateUnits: 500 }),
    ).resolves.toMatchObject({ reserved: true });
  });

  it("blocks a request whose estimate exceeds the remaining reserve", async () => {
    const store = new MemoryConsumptionStore();
    store.seed("s1", 1000);
    store.aggs.get("s1")!.consumed = 700; // reste 300
    await expect(
      store.reserve({ studentId: "s1", requestId: "big", estimateUnits: 1000 }),
    ).rejects.toMatchObject({ code: "resource-exhausted" });
  });

  it("tags reserve exhaustion with a stable reason distinct from the daily quota", () => {
    const error = studyReserveExhaustedError();
    expect(error.code).toBe("resource-exhausted");
    expect(error.details).toEqual({ reason: STUDY_RESERVE_EXHAUSTED_REASON });
    expect(STUDY_RESERVE_EXHAUSTED_REASON).toBe("study_reserve_exhausted");
  });

  it("two concurrent equal reservations: only one may proceed", async () => {
    const store = new MemoryConsumptionStore();
    store.seed("s1", 1500);
    await expect(
      store.reserve({ studentId: "s1", requestId: "A", estimateUnits: 1000 }),
    ).resolves.toMatchObject({ reserved: true });
    // B voit le hold de A (reste 500 < 1000) → refusé.
    await expect(
      store.reserve({ studentId: "s1", requestId: "B", estimateUnits: 1000 }),
    ).rejects.toMatchObject({ code: "resource-exhausted" });
  });

  it("actual usage below the hold releases the unused reservation", async () => {
    const store = new MemoryConsumptionStore();
    store.seed("s1", 1000);
    const consumption = new StudyReserveConsumption(store, new RecordingNotifier(), currentCycle(store));
    // Estimation 1000, usage réel 200 → seul 200 est débité, 800 libérés.
    await consumption.run(
      { studentId: "s1", requestId: "r1", provider: "p", model: "m", estimateUnits: 1000 },
      async () => ({ result: "x", usage: usage(200) }),
    );
    expect(store.aggs.get("s1")!.consumed).toBe(200);
    expect(Object.keys(store.aggs.get("s1")!.holds)).toHaveLength(0);
  });

  it("actual usage above the hold is bounded (charged once, never unbounded)", async () => {
    const store = new MemoryConsumptionStore();
    store.seed("s1", 1000);
    store.aggs.get("s1")!.consumed = 900; // reste 100
    const consumption = new StudyReserveConsumption(store, new RecordingNotifier(), currentCycle(store));
    // Réservation 100 (tient), mais l'usage réel dépasse (150) : on débite le
    // réel, l'agrégat se cape à 0 % — pas de surconsommation illimitée.
    await consumption.run(
      { studentId: "s1", requestId: "r1", provider: "p", model: "m", estimateUnits: 100 },
      async () => ({ result: "x", usage: usage(150) }),
    );
    const agg = store.aggs.get("s1")!;
    expect(agg.consumed).toBe(1050);
    expect(remainingPercent(agg.allowance, agg.consumed)).toBe(0);
  });

  it("releases the reservation when the provider call fails", async () => {
    const store = new MemoryConsumptionStore();
    store.seed("s1", 1000);
    const consumption = new StudyReserveConsumption(store, new RecordingNotifier(), currentCycle(store));
    await expect(
      consumption.run({ studentId: "s1", requestId: "r1", provider: "p", model: "m", estimateUnits: 1 }, async () => {
        throw new Error("provider down");
      }),
    ).rejects.toThrow("provider down");
    // Rien consommé, aucune réservation résiduelle.
    expect(store.aggs.get("s1")!.consumed).toBe(0);
    expect(Object.keys(store.aggs.get("s1")!.holds)).toHaveLength(0);
  });

  it("blocks the model call at zero reserve", async () => {
    const store = new MemoryConsumptionStore();
    store.seed("s1", 100);
    store.aggs.get("s1")!.consumed = 100; // épuisé
    const consumption = new StudyReserveConsumption(store, new RecordingNotifier(), currentCycle(store));
    let executed = false;
    await expect(
      consumption.run({ studentId: "s1", requestId: "r1", provider: "p", model: "m", estimateUnits: 1 }, async () => {
        executed = true;
        return { result: "x", usage: usage(1) };
      }),
    ).rejects.toMatchObject({ code: "resource-exhausted" });
    expect(executed).toBe(false); // l'appel modèle n'a jamais eu lieu
  });

  it("not-configured (no plan) runs without deducting and does not fabricate 100%", async () => {
    const store = new MemoryConsumptionStore(); // aucun seed → non configuré
    const consumption = new StudyReserveConsumption(store, new RecordingNotifier(), noopProvisioning);
    let executed = false;
    const out = await consumption.run(
      { studentId: "s1", requestId: "r1", provider: "p", model: "m", estimateUnits: 1 },
      async () => {
        executed = true;
        return { result: "answer", usage: usage(50) };
      },
    );
    expect(executed).toBe(true); // le tuteur reste gouverné par le quota quotidien
    expect(out.thresholdEvent).toBeNull();
    expect(store.aggs.get("s1")).toBeUndefined();
  });

  it("an old cycle is never debited once the entitlement or plan is unavailable", async () => {
    const store = new MemoryConsumptionStore();
    store.seed("s1", 1000);
    store.aggs.get("s1")!.consumed = 400; // cycle précédent, abonnement échu
    const consumption = new StudyReserveConsumption(store, new RecordingNotifier(), noopProvisioning);
    await consumption.run(
      { studentId: "s1", requestId: "r1", provider: "p", model: "m", estimateUnits: 1 },
      async () => ({ result: "answer", usage: usage(50) }),
    );
    expect(store.aggs.get("s1")!.consumed).toBe(400);
    expect(Object.keys(store.aggs.get("s1")!.holds)).toHaveLength(0);
  });

  it("keeps children independent", async () => {
    const store = new MemoryConsumptionStore();
    store.seed("a", 1000);
    store.seed("b", 1000);
    const consumption = new StudyReserveConsumption(store, new RecordingNotifier(), currentCycle(store));
    await consumption.run({ studentId: "a", requestId: "r1", provider: "p", model: "m", estimateUnits: 1 }, async () => ({
      result: "x",
      usage: usage(900),
    }));
    expect(store.aggs.get("a")!.consumed).toBe(900);
    expect(store.aggs.get("b")!.consumed).toBe(0);
  });

  it("emits a threshold notification once to the student and linked parents", async () => {
    const store = new MemoryConsumptionStore();
    store.seed("child-1", 1000);
    store.parents.set("child-1", ["parent-1", "parent-2"]);
    const notifier = new RecordingNotifier();
    const consumption = new StudyReserveConsumption(store, notifier, currentCycle(store));
    // 100% -> 40% franchit 50 : émission unique.
    await consumption.run({ studentId: "child-1", requestId: "r1", provider: "p", model: "m", estimateUnits: 1 }, async () => ({
      result: "x",
      usage: usage(600),
    }));
    expect(notifier.events).toHaveLength(1);
    expect(notifier.events[0].threshold).toBe(50);
    expect(notifier.events[0].parentIds).toEqual(["parent-1", "parent-2"]);
    // 40% -> 30% : ne réémet pas.
    await consumption.run({ studentId: "child-1", requestId: "r2", provider: "p", model: "m", estimateUnits: 1 }, async () => ({
      result: "x",
      usage: usage(100),
    }));
    expect(notifier.events).toHaveLength(1);
  });

  it("a single large drop notifies only the most severe level, never re-sends higher ones", async () => {
    const store = new MemoryConsumptionStore();
    store.seed("s1", 1000);
    const notifier = new RecordingNotifier();
    const consumption = new StudyReserveConsumption(store, notifier, currentCycle(store));
    // 100% -> 20% franchit 75, 50 et 25 : on n'émet QUE le plus sévère (25).
    const first = await consumption.run(
      { studentId: "s1", requestId: "r1", provider: "p", model: "m", estimateUnits: 1 },
      async () => ({ result: "x", usage: usage(800) }),
    );
    expect(first.thresholdEvent).toBe(25);
    expect(notifier.events.map((e) => e.threshold)).toEqual([25]);
    // La marque (latestThresholdEmitted=25) empêche 75/50 d'être renvoyés plus
    // tard hors ordre : 20% -> 10% n'émet rien de nouveau au-dessus.
    const second = await consumption.run(
      { studentId: "s1", requestId: "r2", provider: "p", model: "m", estimateUnits: 1 },
      async () => ({ result: "x", usage: usage(100) }),
    );
    expect(second.thresholdEvent).toBeNull();
    // 10% -> 3% émet 5 (le prochain plus sévère), jamais 75/50/25 à nouveau.
    const third = await consumption.run(
      { studentId: "s1", requestId: "r3", provider: "p", model: "m", estimateUnits: 1 },
      async () => ({ result: "x", usage: usage(70) }),
    );
    expect(third.thresholdEvent).toBe(5);
    expect(notifier.events.map((e) => e.threshold)).toEqual([25, 5]);
  });

  it("progressively emits every threshold (75, 50, 25, 5, 0) and resets watermark on new cycle", async () => {
    const store = new MemoryConsumptionStore();
    store.seed("s-thresholds", 1000); // 1000 allowance
    const notifier = new RecordingNotifier();
    const consumption = new StudyReserveConsumption(store, notifier, currentCycle(store));

    // 100% -> 75% (consumed 250) -> emits 75
    const r75 = await consumption.run(
      { studentId: "s-thresholds", requestId: "t75", provider: "p", model: "m", estimateUnits: 1 },
      async () => ({ result: "ok", usage: usage(250) }),
    );
    expect(r75.thresholdEvent).toBe(75);

    // 75% -> 50% (consumed +250 = 500) -> emits 50
    const r50 = await consumption.run(
      { studentId: "s-thresholds", requestId: "t50", provider: "p", model: "m", estimateUnits: 1 },
      async () => ({ result: "ok", usage: usage(250) }),
    );
    expect(r50.thresholdEvent).toBe(50);

    // 50% -> 25% (consumed +250 = 750) -> emits 25
    const r25 = await consumption.run(
      { studentId: "s-thresholds", requestId: "t25", provider: "p", model: "m", estimateUnits: 1 },
      async () => ({ result: "ok", usage: usage(250) }),
    );
    expect(r25.thresholdEvent).toBe(25);

    // 25% -> 5% (consumed +200 = 950) -> emits 5
    const r5 = await consumption.run(
      { studentId: "s-thresholds", requestId: "t5", provider: "p", model: "m", estimateUnits: 1 },
      async () => ({ result: "ok", usage: usage(200) }),
    );
    expect(r5.thresholdEvent).toBe(5);

    // 5% -> 0% (consumed +50 = 1000) -> emits 0
    const r0 = await consumption.run(
      { studentId: "s-thresholds", requestId: "t0", provider: "p", model: "m", estimateUnits: 1 },
      async () => ({ result: "ok", usage: usage(50) }),
    );
    expect(r0.thresholdEvent).toBe(0);

    expect(notifier.events.map((e) => e.threshold)).toEqual([75, 50, 25, 5, 0]);

    // Nouveau cycle (agrégat frais, marque nulle — cf. provisionnement) : les
    // seuils sont de nouveau émis, un par un.
    store.seed("s-thresholds", 1000, "next-cycle");
    const renewed = await consumption.run(
      { studentId: "s-thresholds", requestId: "t75", provider: "p", model: "m", estimateUnits: 1 },
      async () => ({ result: "ok", usage: usage(250) }),
    );
    expect(renewed.thresholdEvent).toBe(75);
    expect(notifier.events.map((e) => e.threshold)).toEqual([75, 50, 25, 5, 0, 75]);
  });
});

describe("studyReserveNotificationText (bilingual, never blank)", () => {
  it("produces non-empty FR and EN title/body per threshold", () => {
    for (const lang of ["fr", "en"] as const) {
      for (const threshold of [75, 50, 25, 5, 0] as const) {
        for (const audience of ["student", "parent"] as const) {
          const text = studyReserveNotificationText(lang, threshold, audience);
          expect(text.title.length).toBeGreaterThan(0);
          expect(text.body.length).toBeGreaterThan(0);
        }
      }
    }
  });

  it("uses the product-safe term and no technical wording", () => {
    const fr = studyReserveNotificationText("fr", 25, "student");
    const en = studyReserveNotificationText("en", 25, "parent");
    expect(fr.title).toContain("Réserve d’étude");
    expect(en.title).toContain("Study reserve");
    for (const banned of ["token", "XP", "credit", "crédit"]) {
      expect(`${fr.title}${fr.body}${en.title}${en.body}`).not.toContain(banned);
    }
  });

  it("0% explains the tutor rests while content stays available", () => {
    expect(studyReserveNotificationText("fr", 0, "student").body).toContain("cours");
    expect(studyReserveNotificationText("en", 0, "parent").body).toContain("Lessons");
  });
});
