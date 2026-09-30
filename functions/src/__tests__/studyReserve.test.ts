import { describe, expect, it } from "vitest";

import {
  createGetStudyReserveHandler,
  crossedThreshold,
  remainingPercent,
  statusForPercent,
  type ReserveAggregate,
  type ReserveThreshold,
  type StudyReserveStore,
  type UsageRecord,
  type RecordResult,
} from "../services/studyReserve";
import { CurrentCycleProvisioning } from "./support/currentCycleProvisioning";

/** Réserve en mémoire, appliquant la même logique que l'implémentation
 * Firestore (idempotence + franchissement de seuil), sans base. */
class MemoryStudyReserveStore implements StudyReserveStore {
  roles = new Map<string, string>();
  links = new Set<string>(); // `${parentId}_${studentId}`
  aggregates = new Map<string, ReserveAggregate>();
  ledger = new Set<string>(); // `${studentId}:${cycleId}:${requestId}`

  seed(studentId: string, allowance: number, cycleId = "2026-06") {
    this.aggregates.set(studentId, {
      allowanceInternal: allowance,
      consumed: 0,
      cycleId,
      cycleStart: "2026-06-01T00:00:00.000Z",
      cycleEnd: "2026-07-01T00:00:00.000Z",
      latestThresholdEmitted: null,
    });
  }

  users = new Map<string, Record<string, unknown>>();
  async readUser(uid: string) {
    const role = this.roles.get(uid);
    return this.users.get(uid) ?? (role === undefined ? undefined : { role });
  }
  async isLinkedChild(parentId: string, studentId: string) {
    return this.links.has(`${parentId}_${studentId}`);
  }
  async getAggregate(studentId: string) {
    return this.aggregates.get(studentId) ?? null;
  }

  async recordUsage(record: UsageRecord): Promise<RecordResult> {
    const key = `${record.studentId}:${record.cycleId}:${record.requestId}`;
    const aggregate =
      this.aggregates.get(record.studentId) ?? {
        allowanceInternal: 0,
        consumed: 0,
        cycleId: record.cycleId,
        cycleStart: null,
        cycleEnd: null,
        latestThresholdEmitted: null,
      };
    if (this.ledger.has(key)) {
      return { aggregate, thresholdEvent: null, duplicate: true };
    }
    const prev = remainingPercent(aggregate.allowanceInternal, aggregate.consumed);
    const consumed = aggregate.consumed + Math.max(0, record.billableUnits);
    const next = remainingPercent(aggregate.allowanceInternal, consumed);
    const event = crossedThreshold(prev, next, aggregate.latestThresholdEmitted);
    this.ledger.add(key);
    const updated: ReserveAggregate = {
      ...aggregate,
      consumed,
      latestThresholdEmitted: event ?? aggregate.latestThresholdEmitted,
    };
    this.aggregates.set(record.studentId, updated);
    return { aggregate: updated, thresholdEvent: event, duplicate: false };
  }
}

function usage(over: Partial<UsageRecord> & { studentId: string; requestId: string; billableUnits: number }): UsageRecord {
  return {
    cycleId: "2026-06",
    provider: "vertex-ai",
    model: "gemini",
    inputUnits: 10,
    outputUnits: 10,
    ...over,
  };
}

describe("study reserve pure logic", () => {
  it("computes remaining percent and status", () => {
    expect(remainingPercent(100, 0)).toBe(100);
    expect(remainingPercent(100, 50)).toBe(50);
    expect(remainingPercent(100, 100)).toBe(0);
    expect(remainingPercent(0, 0)).toBe(0);
    expect(statusForPercent(100)).toBe("healthy");
    expect(statusForPercent(40)).toBe("warning");
    expect(statusForPercent(20)).toBe("low");
    expect(statusForPercent(4)).toBe("critical");
    expect(statusForPercent(0)).toBe("depleted");
  });

  it("emits each threshold once, lowest reached wins", () => {
    // 100 -> 40 franchit 75 et 50 : on émet le plus bas atteint (50).
    expect(crossedThreshold(100, 40, null)).toBe(50);
    // déjà émis 50 -> ne réémet pas 50/75, mais 25 si atteint
    expect(crossedThreshold(40, 20, 50)).toBe(25);
    // pas de nouveau seuil
    expect(crossedThreshold(60, 55, null)).toBeNull();
    // dépletion
    expect(crossedThreshold(10, 0, 25)).toBe(0);
  });
});

describe("recordUsage", () => {
  it("normal consumption reduces the reserve", async () => {
    const store = new MemoryStudyReserveStore();
    store.seed("s1", 100);
    const result = await store.recordUsage(
      usage({ studentId: "s1", requestId: "r1", billableUnits: 30 }),
    );
    expect(result.duplicate).toBe(false);
    expect(result.aggregate.consumed).toBe(30);
  });

  it("is idempotent on requestId (retry does not double-charge)", async () => {
    const store = new MemoryStudyReserveStore();
    store.seed("s1", 100);
    const record = usage({ studentId: "s1", requestId: "r1", billableUnits: 30 });
    await store.recordUsage(record);
    const retry = await store.recordUsage(record);
    expect(retry.duplicate).toBe(true);
    expect((await store.getAggregate("s1"))!.consumed).toBe(30);
  });

  it("keeps children independent (no household-shared quota)", async () => {
    const store = new MemoryStudyReserveStore();
    store.seed("child-a", 100);
    store.seed("child-b", 100);
    await store.recordUsage(
      usage({ studentId: "child-a", requestId: "r1", billableUnits: 80 }),
    );
    expect((await store.getAggregate("child-a"))!.consumed).toBe(80);
    expect((await store.getAggregate("child-b"))!.consumed).toBe(0);
  });

  it("crosses thresholds once and does not repeat the alert", async () => {
    const store = new MemoryStudyReserveStore();
    store.seed("s1", 100);
    // 100 -> 40 : émet 50
    const first = await store.recordUsage(
      usage({ studentId: "s1", requestId: "r1", billableUnits: 60 }),
    );
    expect(first.thresholdEvent).toBe(50);
    // 40 -> 30 : ne réémet pas 50
    const second = await store.recordUsage(
      usage({ studentId: "s1", requestId: "r2", billableUnits: 10 }),
    );
    expect(second.thresholdEvent).toBeNull();
    // 30 -> 20 : émet 25
    const third = await store.recordUsage(
      usage({ studentId: "s1", requestId: "r3", billableUnits: 10 }),
    );
    expect(third.thresholdEvent).toBe(25);
  });

  it("depletes to zero and emits the 0 threshold", async () => {
    const store = new MemoryStudyReserveStore();
    store.seed("s1", 100);
    const result = await store.recordUsage(
      usage({ studentId: "s1", requestId: "r1", billableUnits: 100 }),
    );
    expect(remainingPercent(result.aggregate.allowanceInternal, result.aggregate.consumed)).toBe(0);
    expect(result.thresholdEvent).toBe(0);
  });

  it("renewal/reset restores a fresh cycle", async () => {
    const store = new MemoryStudyReserveStore();
    store.seed("s1", 100);
    await store.recordUsage(
      usage({ studentId: "s1", requestId: "r1", billableUnits: 90 }),
    );
    // Nouveau cycle : nouvelle allocation, seuils réarmés.
    store.seed("s1", 100, "2026-07");
    const agg = await store.getAggregate("s1");
    expect(agg!.consumed).toBe(0);
    expect(agg!.latestThresholdEmitted).toBeNull();
    expect(remainingPercent(agg!.allowanceInternal, agg!.consumed)).toBe(100);
  });
});

describe("getStudyReserve callable (authorization + parent visibility)", () => {
  it("rejects unauthenticated callers", async () => {
    const handler = createGetStudyReserveHandler(new MemoryStudyReserveStore(), new CurrentCycleProvisioning(async () => null));
    await expect(handler({ data: {} } as never)).rejects.toMatchObject({
      code: "unauthenticated",
    });
  });

  it("returns a product-safe view for the student's own reserve", async () => {
    const store = new MemoryStudyReserveStore();
    store.seed("s1", 100);
    await store.recordUsage(
      usage({ studentId: "s1", requestId: "r1", billableUnits: 25 }),
    );
    const handler = createGetStudyReserveHandler(store, new CurrentCycleProvisioning((id) => store.getAggregate(id)));
    const view = await handler({ auth: { uid: "s1" }, data: {} } as never);
    expect(view.percentRemaining).toBe(75);
    expect(view.status).toBe("healthy");
    // Aucun compte brut de modèle n'est exposé.
    expect(Object.keys(view)).not.toContain("consumed");
    expect(Object.keys(view)).not.toContain("allowanceInternal");
  });

  it("a linked parent can read a child's reserve; a stranger cannot", async () => {
    const store = new MemoryStudyReserveStore();
    store.seed("child-1", 100);
    store.roles.set("parent-1", "parent");
    store.links.add("parent-1_child-1");

    const handler = createGetStudyReserveHandler(store, new CurrentCycleProvisioning((id) => store.getAggregate(id)));
    await expect(
      handler({ auth: { uid: "parent-1" }, data: { studentId: "child-1" } } as never),
    ).resolves.toMatchObject({ studentId: "child-1" });

    // Parent non lié → refus.
    store.roles.set("parent-2", "parent");
    await expect(
      handler({ auth: { uid: "parent-2" }, data: { studentId: "child-1" } } as never),
    ).rejects.toMatchObject({ code: "permission-denied" });
  });

  it("a teacher who is also a linked parent reads the child's reserve; a teacher alone cannot", async () => {
    const store = new MemoryStudyReserveStore();
    store.seed("child-1", 100);
    store.users.set("teacher-parent", { role: "teacher", roles: ["teacher", "parent"] });
    store.users.set("teacher-only", { role: "teacher" });
    store.links.add("teacher-parent_child-1");
    store.links.add("teacher-only_child-1");

    const handler = createGetStudyReserveHandler(store, new CurrentCycleProvisioning((id) => store.getAggregate(id)));
    await expect(
      handler({ auth: { uid: "teacher-parent" }, data: { studentId: "child-1" } } as never),
    ).resolves.toMatchObject({ studentId: "child-1" });
    await expect(
      handler({ auth: { uid: "teacher-only" }, data: { studentId: "child-1" } } as never),
    ).rejects.toMatchObject({ code: "permission-denied" });
  });
});
