import { describe, expect, it } from "vitest";

import {
  createGetStudyReserveHandler,
  type RecordResult,
  type ReserveAggregate,
  type StudyReserveStore,
} from "../services/studyReserve";
import {
  StudyReserveConsumption,
  type ReserveHold,
  type StudyReserveConsumptionStore,
  type ThresholdNotifier,
} from "../services/studyReserveConsumption";
import {
  computeCurrentCycle,
  ensureCurrentStudyReserveCycle,
  parseEntitlementDocument,
  parsePlanConfig,
  type StudentEntitlement,
  type StudyReservePlanConfig,
  type StudyReserveProvisioningStore,
} from "../services/studyReserveProvisioning";

const DAY = 24 * 60 * 60 * 1000;
const JUNE_1 = Date.UTC(2026, 5, 1);
const NOW = JUNE_1 + 10 * DAY; // 11 juin

class MemoryProvisioningStore implements StudyReserveProvisioningStore {
  entitlements = new Map<string, StudentEntitlement>();
  plans = new Map<string, StudyReservePlanConfig>();
  aggregates = new Map<string, ReserveAggregate>();
  provisionCalls = 0;

  async resolveEntitlement(studentId: string) {
    return this.entitlements.get(studentId) ?? null;
  }
  async planConfig(offerId: string) {
    return this.plans.get(offerId) ?? null;
  }
  async readAggregate(studentId: string) {
    return this.aggregates.get(studentId) ?? null;
  }
  async provisionCycle(studentId: string, fresh: ReserveAggregate) {
    this.provisionCalls++;
    const current = this.aggregates.get(studentId);
    if (current && current.cycleId === fresh.cycleId && current.allowanceInternal > 0) {
      return current;
    }
    this.aggregates.set(studentId, { ...fresh });
    return fresh;
  }
  async updateCurrentCycle(
    studentId: string,
    cycleId: string,
    terms: { allowanceInternal: number; cycleEnd: string },
  ) {
    const current = this.aggregates.get(studentId);
    if (!current || current.cycleId !== cycleId) return current ?? null;
    const updated = { ...current, ...terms };
    this.aggregates.set(studentId, updated);
    return updated;
  }
}

const entitlement = (over: Partial<StudentEntitlement> = {}): StudentEntitlement => ({
  offerId: "school-a",
  windowStartMs: JUNE_1,
  windowEndMs: JUNE_1 + 30 * DAY,
  active: true,
  ...over,
});

const plan = (over: Partial<StudyReservePlanConfig> = {}): StudyReservePlanConfig => ({
  allowanceInternal: 100_000,
  cycleDays: null,
  ...over,
});

describe("ensureCurrentStudyReserveCycle — entitlement & cycle", () => {
  it("auto-provisions an existing entitled student who has no study_reserve doc", async () => {
    const store = new MemoryProvisioningStore();
    store.entitlements.set("s1", entitlement());
    store.plans.set("school-a", plan());
    const agg = await ensureCurrentStudyReserveCycle("s1", store, NOW);
    expect(agg).toMatchObject({ allowanceInternal: 100_000, consumed: 0, latestThresholdEmitted: null });
    expect(agg!.cycleStart).toBe(new Date(JUNE_1).toISOString());
    expect(agg!.cycleEnd).toBe(new Date(JUNE_1 + 30 * DAY).toISOString());
  });

  it("same cycle: ordinary requests never reset consumption", async () => {
    const store = new MemoryProvisioningStore();
    store.entitlements.set("s1", entitlement());
    store.plans.set("school-a", plan());
    await ensureCurrentStudyReserveCycle("s1", store, NOW);
    store.aggregates.get("s1")!.consumed = 40_000;
    store.aggregates.get("s1")!.latestThresholdEmitted = 75;
    const again = await ensureCurrentStudyReserveCycle("s1", store, NOW + DAY);
    expect(again!.consumed).toBe(40_000);
    expect(again!.latestThresholdEmitted).toBe(75);
    expect(store.provisionCalls).toBe(1);
  });

  it("expired cycle renewal: a new paid window resets to a fresh cycle", async () => {
    const store = new MemoryProvisioningStore();
    store.plans.set("school-a", plan());
    store.entitlements.set("s1", entitlement());
    await ensureCurrentStudyReserveCycle("s1", store, NOW);
    store.aggregates.get("s1")!.consumed = 99_000;
    store.aggregates.get("s1")!.latestThresholdEmitted = 5;
    // Fenêtre suivante (après expiration puis nouveau paiement).
    const july = JUNE_1 + 31 * DAY;
    store.entitlements.set("s1", entitlement({ windowStartMs: july, windowEndMs: july + 30 * DAY }));
    const renewed = await ensureCurrentStudyReserveCycle("s1", store, july + DAY);
    expect(renewed).toMatchObject({ consumed: 0, latestThresholdEmitted: null });
  });

  it("configured cadence slices a long paid window into consecutive cycles", async () => {
    const store = new MemoryProvisioningStore();
    // Paiement long (90 j) et cadence décidée par le propriétaire (30 j).
    store.entitlements.set("s1", entitlement({ windowEndMs: JUNE_1 + 90 * DAY }));
    store.plans.set("school-a", plan({ cycleDays: 30 }));
    const first = await ensureCurrentStudyReserveCycle("s1", store, JUNE_1 + 5 * DAY);
    store.aggregates.get("s1")!.consumed = 60_000;
    const second = await ensureCurrentStudyReserveCycle("s1", store, JUNE_1 + 35 * DAY);
    expect(second!.cycleId).not.toBe(first!.cycleId);
    expect(second!.consumed).toBe(0);
    // La dernière tranche est bornée par la fin de la fenêtre payée.
    const cycle = computeCurrentCycle(entitlement({ windowEndMs: JUNE_1 + 70 * DAY }), 30, JUNE_1 + 65 * DAY);
    expect(cycle.endMs).toBe(JUNE_1 + 70 * DAY);
  });

  it("30-day boundaries: last millisecond stays in cycle 0, the 30th day opens cycle 1, then cycle 2", async () => {
    const store = new MemoryProvisioningStore();
    const offerId = "lycee-bilingue-etoug-ebe";
    store.entitlements.set("s1", entitlement({ offerId, windowEndMs: JUNE_1 + 90 * DAY }));
    store.plans.set(offerId, { allowanceInternal: 600_000, cycleDays: 30 });

    const c0 = await ensureCurrentStudyReserveCycle("s1", store, JUNE_1);
    store.aggregates.get("s1")!.consumed = 450_000;
    const lastMs = await ensureCurrentStudyReserveCycle("s1", store, JUNE_1 + 30 * DAY - 1);
    expect(lastMs).toMatchObject({ cycleId: c0!.cycleId, consumed: 450_000 });

    const c1 = await ensureCurrentStudyReserveCycle("s1", store, JUNE_1 + 30 * DAY);
    expect(c1).toMatchObject({
      cycleId: `${offerId}_${JUNE_1}_1`,
      consumed: 0,
      cycleStart: new Date(JUNE_1 + 30 * DAY).toISOString(),
      cycleEnd: new Date(JUNE_1 + 60 * DAY).toISOString(),
    });
    const c2 = await ensureCurrentStudyReserveCycle("s1", store, JUNE_1 + 60 * DAY);
    expect(c2).toMatchObject({ cycleId: `${offerId}_${JUNE_1}_2`, consumed: 0 });
    expect(store.provisionCalls).toBe(3); // aucun cycle dupliqué
  });

  it("early renewal during a short final slice extends its end without resetting consumption", async () => {
    const store = new MemoryProvisioningStore();
    const offerId = "lycee-bilingue-etoug-ebe";
    store.plans.set(offerId, { allowanceInternal: 600_000, cycleDays: 30 });
    // Offre de 45 jours : tranche 1 = jours 30 → 45 (tranche finale courte).
    store.entitlements.set("s1", entitlement({ offerId, windowEndMs: JUNE_1 + 45 * DAY }));
    const short = await ensureCurrentStudyReserveCycle("s1", store, JUNE_1 + 35 * DAY);
    expect(short!.cycleEnd).toBe(new Date(JUNE_1 + 45 * DAY).toISOString());
    store.aggregates.get("s1")!.consumed = 200_000;

    // Renouvellement anticipé : startsAt conservé, endsAt repoussé de 45 jours.
    store.entitlements.set("s1", entitlement({ offerId, windowEndMs: JUNE_1 + 90 * DAY }));
    const extended = await ensureCurrentStudyReserveCycle("s1", store, JUNE_1 + 40 * DAY);
    expect(extended).toMatchObject({
      cycleId: short!.cycleId,
      consumed: 200_000,
      cycleEnd: new Date(JUNE_1 + 60 * DAY).toISOString(),
    });
    expect(store.provisionCalls).toBe(1);
  });

  it("plan change opens a new cycle with the new allowance", async () => {
    const store = new MemoryProvisioningStore();
    store.plans.set("school-a", plan());
    store.plans.set("school-b", plan({ allowanceInternal: 250_000 }));
    store.entitlements.set("s1", entitlement());
    await ensureCurrentStudyReserveCycle("s1", store, NOW);
    store.aggregates.get("s1")!.consumed = 80_000;
    store.entitlements.set("s1", entitlement({ offerId: "school-b" }));
    const changed = await ensureCurrentStudyReserveCycle("s1", store, NOW);
    expect(changed).toMatchObject({ allowanceInternal: 250_000, consumed: 0 });
  });

  it("allowance edited mid-cycle updates the allowance without resetting consumption", async () => {
    const store = new MemoryProvisioningStore();
    store.entitlements.set("s1", entitlement());
    store.plans.set("school-a", plan());
    await ensureCurrentStudyReserveCycle("s1", store, NOW);
    store.aggregates.get("s1")!.consumed = 30_000;
    store.plans.set("school-a", plan({ allowanceInternal: 120_000 }));
    const adjusted = await ensureCurrentStudyReserveCycle("s1", store, NOW);
    expect(adjusted).toMatchObject({ allowanceInternal: 120_000, consumed: 30_000 });
  });

  it("inactive subscription grants nothing", async () => {
    const store = new MemoryProvisioningStore();
    store.entitlements.set("s1", entitlement({ active: false }));
    store.plans.set("school-a", plan());
    expect(await ensureCurrentStudyReserveCycle("s1", store, NOW)).toBeNull();
    expect(store.provisionCalls).toBe(0);
  });

  it("missing entitlement grants nothing", async () => {
    const store = new MemoryProvisioningStore();
    store.plans.set("school-a", plan());
    expect(await ensureCurrentStudyReserveCycle("s1", store, NOW)).toBeNull();
  });

  it("an existing aggregate becomes unavailable (untouched) when the plan config is removed or malformed", async () => {
    const store = new MemoryProvisioningStore();
    store.entitlements.set("s1", entitlement());
    store.plans.set("school-a", plan({ allowanceInternal: 600_000, cycleDays: 30 }));
    await ensureCurrentStudyReserveCycle("s1", store, NOW);
    store.aggregates.get("s1")!.consumed = 300_000;
    store.plans.delete("school-a"); // absente, ou rejetée par parsePlanConfig
    expect(await ensureCurrentStudyReserveCycle("s1", store, NOW)).toBeNull();
    expect(store.aggregates.get("s1")).toMatchObject({ consumed: 300_000, allowanceInternal: 600_000 });
    expect(store.provisionCalls).toBe(1);
  });

  it("an expired subscription never presents its last cycle as a live reserve", async () => {
    const store = new MemoryProvisioningStore();
    store.entitlements.set("s1", entitlement());
    store.plans.set("school-a", plan());
    await ensureCurrentStudyReserveCycle("s1", store, NOW);
    store.entitlements.set("s1", entitlement({ active: false }));
    expect(await ensureCurrentStudyReserveCycle("s1", store, JUNE_1 + 31 * DAY)).toBeNull();
    expect(store.aggregates.get("s1")).toBeDefined(); // ledger et agrégat conservés
  });

  it("missing plan allowance never invents a number", async () => {
    const store = new MemoryProvisioningStore();
    store.entitlements.set("s1", entitlement());
    expect(await ensureCurrentStudyReserveCycle("s1", store, NOW)).toBeNull();
    expect(store.provisionCalls).toBe(0);
  });

  it("V1 standard contract: auto-provisions 600,000 units and 30-day cycle without manual creation", async () => {
    const store = new MemoryProvisioningStore();
    // En production, offerId === establishmentId (mobileMoneyCallables).
    store.entitlements.set("student-v1", entitlement({
      offerId: "lycee-bilingue-etoug-ebe",
      windowStartMs: JUNE_1,
      windowEndMs: JUNE_1 + 30 * DAY,
    }));
    store.plans.set("lycee-bilingue-etoug-ebe", { allowanceInternal: 600_000, cycleDays: 30 });

    const agg = await ensureCurrentStudyReserveCycle("student-v1", store, NOW);
    expect(agg).not.toBeNull();
    expect(agg!.allowanceInternal).toBe(600_000);
    expect(agg!.consumed).toBe(0);
    expect(agg!.latestThresholdEmitted).toBeNull();
    expect(agg!.cycleId).toBe(`lycee-bilingue-etoug-ebe_${JUNE_1}_0`);
    expect(agg!.cycleStart).toBe(new Date(JUNE_1).toISOString());
    expect(agg!.cycleEnd).toBe(new Date(JUNE_1 + 30 * DAY).toISOString());
  });

  it("Mobile Money early renewal: preserves startsAt, extends endsAt, slices into 30 days without mid-slice reset", async () => {
    const store = new MemoryProvisioningStore();
    const offerId = "establishment-cm-1";
    store.plans.set(offerId, { allowanceInternal: 600_000, cycleDays: 30 });

    // Initial 30-day entitlement: June 1 -> July 1
    store.entitlements.set("student-renewal", entitlement({
      offerId,
      windowStartMs: JUNE_1,
      windowEndMs: JUNE_1 + 30 * DAY,
    }));

    // Day 10: initial provisioning and usage
    const day10 = JUNE_1 + 10 * DAY;
    const initial = await ensureCurrentStudyReserveCycle("student-renewal", store, day10);
    expect(initial!.cycleId).toBe(`${offerId}_${JUNE_1}_0`);
    store.aggregates.get("student-renewal")!.consumed = 250_000;
    store.aggregates.get("student-renewal")!.latestThresholdEmitted = 75;

    // Day 20: Early Mobile Money renewal extends endsAt to 60 days (August 1) while keeping startsAt (June 1)
    store.entitlements.set("student-renewal", entitlement({
      offerId,
      windowStartMs: JUNE_1,
      windowEndMs: JUNE_1 + 60 * DAY,
    }));

    // Still in slice 0 (day 20): consumed is NOT reset
    const day20 = JUNE_1 + 20 * DAY;
    const midSlice = await ensureCurrentStudyReserveCycle("student-renewal", store, day20);
    expect(midSlice!.cycleId).toBe(`${offerId}_${JUNE_1}_0`);
    expect(midSlice!.consumed).toBe(250_000);
    expect(midSlice!.latestThresholdEmitted).toBe(75);

    // Day 31: Transition into slice 1 (next 30-day cycle). Consumed resets to 0!
    const day31 = JUNE_1 + 31 * DAY;
    const slice1 = await ensureCurrentStudyReserveCycle("student-renewal", store, day31);
    expect(slice1!.cycleId).toBe(`${offerId}_${JUNE_1}_1`);
    expect(slice1!.consumed).toBe(0);
    expect(slice1!.latestThresholdEmitted).toBeNull();
    expect(slice1!.allowanceInternal).toBe(600_000);
    expect(slice1!.cycleStart).toBe(new Date(JUNE_1 + 30 * DAY).toISOString());
    expect(slice1!.cycleEnd).toBe(new Date(JUNE_1 + 60 * DAY).toISOString());
  });

  it("multi-child storage independence: Parent P with Child A and Child B maintains two independent study_reserve documents", async () => {
    const store = new MemoryProvisioningStore();
    const offerId = "college-la-retraite";
    store.plans.set(offerId, { allowanceInternal: 600_000, cycleDays: 30 });

    // Single family entitlement shared by Parent P
    const familyEntitlement = entitlement({
      offerId,
      windowStartMs: JUNE_1,
      windowEndMs: JUNE_1 + 60 * DAY,
    });
    store.entitlements.set("child-a", familyEntitlement);
    store.entitlements.set("child-b", familyEntitlement);

    // Provision Child A
    const aggA = await ensureCurrentStudyReserveCycle("child-a", store, JUNE_1 + 5 * DAY);
    expect(aggA!.allowanceInternal).toBe(600_000);
    expect(store.aggregates.has("child-a")).toBe(true);
    expect(store.aggregates.has("child-b")).toBe(false);

    // Provision Child B
    const aggB = await ensureCurrentStudyReserveCycle("child-b", store, JUNE_1 + 5 * DAY);
    expect(aggB!.allowanceInternal).toBe(600_000);
    expect(store.aggregates.has("child-b")).toBe(true);

    // Child A consumes 300,000 units
    store.aggregates.get("child-a")!.consumed = 300_000;
    expect(store.aggregates.get("child-a")!.consumed).toBe(300_000);
    expect(store.aggregates.get("child-b")!.consumed).toBe(0); // Child B untouched

    // Advance Child A to next cycle (Day 35)
    const renewedA = await ensureCurrentStudyReserveCycle("child-a", store, JUNE_1 + 35 * DAY);
    expect(renewedA!.cycleId).toBe(`${offerId}_${JUNE_1}_1`);
    expect(renewedA!.consumed).toBe(0);

    // Child B still in slice 0 with its own distinct state
    const currentB = await store.readAggregate("child-b");
    expect(currentB!.cycleId).toBe(`${offerId}_${JUNE_1}_0`);
    expect(currentB!.consumed).toBe(0);
  });
});

describe("legacy / malformed data", () => {
  const ts = (ms: number) => ({ toMillis: () => ms });

  it("parses a well-formed Mobile Money entitlement", () => {
    const parsed = parseEntitlementDocument(
      { status: "active", startsAt: ts(JUNE_1), endsAt: ts(JUNE_1 + 30 * DAY), offerId: "school-a" },
      "school-a",
      NOW,
    );
    expect(parsed).toMatchObject({ offerId: "school-a", active: true });
  });

  it("rejects malformed legacy entitlements instead of granting reserve", () => {
    // Fin absente, fin illisible, début après la fin.
    expect(parseEntitlementDocument({ status: "active", startsAt: ts(JUNE_1) }, "s", NOW)).toBeNull();
    expect(parseEntitlementDocument({ status: "active", startsAt: ts(JUNE_1), endsAt: "demain" }, "s", NOW)).toBeNull();
    expect(
      parseEntitlementDocument({ status: "active", startsAt: ts(JUNE_1 + 40 * DAY), endsAt: ts(JUNE_1 + 30 * DAY) }, "s", NOW),
    ).toBeNull();
    // Statut non actif ou fenêtre expirée → inactif.
    expect(
      parseEntitlementDocument({ status: "revoked", startsAt: ts(JUNE_1), endsAt: ts(JUNE_1 + 30 * DAY) }, "s", NOW)!.active,
    ).toBe(false);
    expect(
      parseEntitlementDocument({ status: "active", startsAt: ts(JUNE_1 - 60 * DAY), endsAt: ts(JUNE_1 - 30 * DAY) }, "s", NOW)!.active,
    ).toBe(false);
  });

  it("falls back to the establishment offer when a legacy entitlement has no offerId", () => {
    const parsed = parseEntitlementDocument(
      { status: "active", startsAt: ts(JUNE_1), endsAt: ts(JUNE_1 + 30 * DAY) },
      "school-a",
      NOW,
    );
    expect(parsed!.offerId).toBe("school-a");
  });

  it("rejects invalid plan configuration rather than guessing", () => {
    expect(parsePlanConfig({ allowanceInternal: 100_000 })).toEqual({ allowanceInternal: 100_000, cycleDays: null });
    expect(parsePlanConfig({ allowanceInternal: 100_000, cycleDays: 30 })).toEqual({ allowanceInternal: 100_000, cycleDays: 30 });
    expect(parsePlanConfig(undefined)).toBeNull();
    expect(parsePlanConfig({})).toBeNull();
    expect(parsePlanConfig({ allowanceInternal: 0 })).toBeNull();
    expect(parsePlanConfig({ allowanceInternal: "100000" })).toBeNull();
    expect(parsePlanConfig({ allowanceInternal: 12.5 })).toBeNull();
    expect(parsePlanConfig({ allowanceInternal: 100_000, cycleDays: 0 })).toBeNull();
    expect(parsePlanConfig({ allowanceInternal: 100_000, cycleDays: "30" })).toBeNull();
  });
});

describe("dual entry-point auto-provisioning (no manual aggregate creation)", () => {
  class MockConsumptionStore implements StudyReserveConsumptionStore {
    constructor(private readonly prov: MemoryProvisioningStore) {}
    async reserve(params: { studentId: string; requestId: string; estimateUnits: number }): Promise<ReserveHold> {
      const agg = await this.prov.readAggregate(params.studentId);
      if (!agg || agg.allowanceInternal <= 0) return { configured: false, reserved: false };
      return { configured: true, reserved: true };
    }
    async commit() {
      return { duplicate: false, thresholdEvent: null, cycleId: "c1" };
    }
    async release() {}
    async listLinkedParents() {
      return [];
    }
  }

  class MockReserveStore implements StudyReserveStore {
    constructor(private readonly prov: MemoryProvisioningStore) {}
    async readRole() {
      return "student";
    }
    async isLinkedChild() {
      return true;
    }
    async getAggregate(studentId: string) {
      return this.prov.readAggregate(studentId);
    }
    async recordUsage(): Promise<RecordResult> {
      throw new Error("not used in view");
    }
  }

  class NoopNotifier implements ThresholdNotifier {
    async emit() {}
  }

  it("A. getStudyReserve auto-provisions an uninitialized student aggregate from active entitlement", async () => {
    const provStore = new MemoryProvisioningStore();
    provStore.entitlements.set("student-ep-a", entitlement({ offerId: "lycee-leclerc" }));
    provStore.plans.set("lycee-leclerc", { allowanceInternal: 600_000, cycleDays: 30 });

    expect(await provStore.readAggregate("student-ep-a")).toBeNull();

    const handler = createGetStudyReserveHandler(new MockReserveStore(provStore), provStore);
    const view = await handler({ auth: { uid: "student-ep-a" }, data: {} } as never);

    expect(view.status).toBe("healthy");
    expect(view.percentRemaining).toBe(100);
    expect(provStore.aggregates.get("student-ep-a")).toMatchObject({
      allowanceInternal: 600_000,
      consumed: 0,
    });
  });

  it("B. StudyReserveConsumption.run auto-provisions an uninitialized student aggregate before reserving", async () => {
    const provStore = new MemoryProvisioningStore();
    provStore.entitlements.set("student-ep-b", entitlement({ offerId: "lycee-leclerc" }));
    provStore.plans.set("lycee-leclerc", { allowanceInternal: 600_000, cycleDays: 30 });

    expect(await provStore.readAggregate("student-ep-b")).toBeNull();

    const consumption = new StudyReserveConsumption(
      new MockConsumptionStore(provStore),
      new NoopNotifier(),
      provStore,
    );

    let executed = false;
    await consumption.run(
      { studentId: "student-ep-b", requestId: "req-1", provider: "vertex-ai", model: "gemini", estimateUnits: 1000 },
      async () => {
        executed = true;
        return { result: "ok", usage: { inputUnits: 10, outputUnits: 10, billableUnits: 20 } };
      },
    );

    expect(executed).toBe(true);
    expect(provStore.aggregates.get("student-ep-b")).toMatchObject({
      allowanceInternal: 600_000,
      consumed: 0,
    });
  });
});
