import { describe, expect, it } from "vitest";

import { crossedThreshold, remainingPercent, type ReserveThreshold } from "../services/studyReserve";
import {
  StudyReserveConsumption,
  billableFromUsage,
  type CommitResult,
  type ProviderUsage,
  type ReserveHold,
  type StudyReserveConsumptionStore,
  type ThresholdNotifier,
} from "../services/studyReserveConsumption";

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

  private held(agg: Agg): number {
    return Object.values(agg.holds).reduce((s, v) => s + v, 0);
  }

  async reserve(p: { studentId: string; requestId: string; estimateUnits: number }): Promise<ReserveHold> {
    const agg = this.aggs.get(p.studentId);
    if (!agg || agg.allowance <= 0) return { configured: false, reserved: false };
    const remaining = agg.allowance - agg.consumed - this.held(agg);
    if (remaining <= 0) {
      throw Object.assign(new Error("resource-exhausted"), { code: "resource-exhausted" });
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
    const consumption = new StudyReserveConsumption(store, new RecordingNotifier());
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
    const consumption = new StudyReserveConsumption(store, new RecordingNotifier());
    const exec = async () => ({ result: "a", usage: usage(250) });
    await consumption.run({ studentId: "s1", requestId: "r1", provider: "p", model: "m" }, exec);
    await consumption.run({ studentId: "s1", requestId: "r1", provider: "p", model: "m" }, exec);
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

  it("releases the reservation when the provider call fails", async () => {
    const store = new MemoryConsumptionStore();
    store.seed("s1", 1000);
    const consumption = new StudyReserveConsumption(store, new RecordingNotifier());
    await expect(
      consumption.run({ studentId: "s1", requestId: "r1", provider: "p", model: "m" }, async () => {
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
    const consumption = new StudyReserveConsumption(store, new RecordingNotifier());
    let executed = false;
    await expect(
      consumption.run({ studentId: "s1", requestId: "r1", provider: "p", model: "m" }, async () => {
        executed = true;
        return { result: "x", usage: usage(1) };
      }),
    ).rejects.toMatchObject({ code: "resource-exhausted" });
    expect(executed).toBe(false); // l'appel modèle n'a jamais eu lieu
  });

  it("not-configured (no plan) runs without deducting and does not fabricate 100%", async () => {
    const store = new MemoryConsumptionStore(); // aucun seed → non configuré
    const consumption = new StudyReserveConsumption(store, new RecordingNotifier());
    let executed = false;
    const out = await consumption.run(
      { studentId: "s1", requestId: "r1", provider: "p", model: "m" },
      async () => {
        executed = true;
        return { result: "answer", usage: usage(50) };
      },
    );
    expect(executed).toBe(true); // le tuteur reste gouverné par le quota quotidien
    expect(out.thresholdEvent).toBeNull();
    expect(store.aggs.get("s1")).toBeUndefined();
  });

  it("keeps children independent", async () => {
    const store = new MemoryConsumptionStore();
    store.seed("a", 1000);
    store.seed("b", 1000);
    const consumption = new StudyReserveConsumption(store, new RecordingNotifier());
    await consumption.run({ studentId: "a", requestId: "r1", provider: "p", model: "m" }, async () => ({
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
    const consumption = new StudyReserveConsumption(store, notifier);
    // 100% -> 40% franchit 50 : émission unique.
    await consumption.run({ studentId: "child-1", requestId: "r1", provider: "p", model: "m" }, async () => ({
      result: "x",
      usage: usage(600),
    }));
    expect(notifier.events).toHaveLength(1);
    expect(notifier.events[0].threshold).toBe(50);
    expect(notifier.events[0].parentIds).toEqual(["parent-1", "parent-2"]);
    // 40% -> 30% : ne réémet pas.
    await consumption.run({ studentId: "child-1", requestId: "r2", provider: "p", model: "m" }, async () => ({
      result: "x",
      usage: usage(100),
    }));
    expect(notifier.events).toHaveLength(1);
  });
});
