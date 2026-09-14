import { describe, expect, it } from "vitest";

import type { ReserveAggregate } from "../services/studyReserve";
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
  async updateAllowance(studentId: string, cycleId: string, allowanceInternal: number) {
    const current = this.aggregates.get(studentId);
    if (!current || current.cycleId !== cycleId) return current ?? null;
    const updated = { ...current, allowanceInternal };
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

  it("missing plan allowance never invents a number", async () => {
    const store = new MemoryProvisioningStore();
    store.entitlements.set("s1", entitlement());
    expect(await ensureCurrentStudyReserveCycle("s1", store, NOW)).toBeNull();
    expect(store.provisionCalls).toBe(0);
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
