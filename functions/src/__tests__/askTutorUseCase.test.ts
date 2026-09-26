import { describe, expect, it } from "vitest";

import {
  AskTutorUseCase,
  lessonBelongsToTutorScope,
  resolveTutorAcademicScope,
  type AuthorizedTutorContext,
  type TutorContextStore,
} from "../services/askTutorUseCase";
import type {
  TutorQuotaSnapshot,
  TutorQuotaStore,
} from "../services/tutorDailyQuota";
import type { LlmTokenUsage } from "../llm/llmClient";
import { AppError } from "../utils/errors";
import {
  StudyReserveConsumption,
  studyReserveExhaustedError,
  type ReserveHold,
  type StudyReserveConsumptionStore,
  type ThresholdNotifier,
} from "../services/studyReserveConsumption";
import type {
  ReserveAggregate,
} from "../services/studyReserve";
import {
  computeCurrentCycle,
  type StudentEntitlement,
  type StudyReservePlanConfig,
  type StudyReserveProvisioningStore,
} from "../services/studyReserveProvisioning";
import type { AskTutorCallableInput } from "../utils/validation";

/** Réserve non configurée : le tuteur s'exécute sans toucher à Firestore. */
class NotConfiguredConsumptionStore implements StudyReserveConsumptionStore {
  async reserve(): Promise<ReserveHold> {
    return { configured: false, reserved: false };
  }
  async commit() {
    return { duplicate: false, thresholdEvent: null, cycleId: "" };
  }
  async release(): Promise<void> {}
  async listLinkedParents(): Promise<string[]> {
    return [];
  }
}

class NoopNotifier implements ThresholdNotifier {
  async emit(): Promise<void> {}
}

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

function passthroughStudyReserve(): StudyReserveConsumption {
  return new StudyReserveConsumption(
    new NotConfiguredConsumptionStore(),
    new NoopNotifier(),
    new NoopProvisioningStore(),
  );
}

describe("AskTutorUseCase academic isolation", () => {
  it("rejects a client class that differs from the authenticated profile", () => {
    expect(() => resolveTutorAcademicScope({
      requestedClassLevel: "Première",
      userData: {
        role: "student",
        classLevel: "Terminale",
        establishmentId: "school-a",
      },
      profileData: {
        classLevel: "Terminale",
        establishmentId: "school-a",
      },
    })).toThrowError(expect.objectContaining({ code: "permission-denied" }));
  });

  it("rejects inconsistent class and establishment data", () => {
    expect(() => resolveTutorAcademicScope({
      requestedClassLevel: "Terminale",
      userData: {
        role: "student",
        classLevel: "Terminale",
        establishmentId: "school-a",
      },
      profileData: {
        classLevel: "Première",
        establishmentId: "school-b",
      },
    })).toThrowError(expect.objectContaining({ code: "failed-precondition" }));
  });

  it("allows only published global or same-school lessons in the authorized class", () => {
    const scope = {
      classLevel: "Terminale",
      establishmentId: "school-a",
    };
    expect(lessonBelongsToTutorScope({
      status: "published",
      classLevel: "Terminale",
      title: "Cours global",
    }, scope)).toBe(true);
    expect(lessonBelongsToTutorScope({
      status: "published",
      classLevel: "Terminale",
      establishmentId: "school-a",
    }, scope)).toBe(true);
    expect(lessonBelongsToTutorScope({
      status: "published",
      classLevel: "Terminale",
      establishmentId: "school-b",
    }, scope)).toBe(false);
    expect(lessonBelongsToTutorScope({
      status: "published",
      classLevel: "Première",
    }, scope)).toBe(false);
    expect(lessonBelongsToTutorScope({
      status: "draft",
      classLevel: "Terminale",
    }, scope)).toBe(false);
    expect(lessonBelongsToTutorScope({
      status: "published",
      classLevel: "Terminale",
      visibilityScope: "establishment",
    }, scope)).toBe(false);
  });

  it("sends only the authorized context and authoritative class to the LLM", async () => {
    const prompts: string[] = [];
    const quotaStore = new FixedQuotaStore();
    const useCase = new AskTutorUseCase(
      new FixedContextStore({
        scope: { classLevel: "Terminale", establishmentId: "school-a" },
        text: "CONTENU_AUTORISE_SCHOOL_A",
      }),
      async ({ prompt }) => {
        prompts.push(prompt);
        return "Réponse sûre";
      },
      quotaStore,
      20,
      passthroughStudyReserve(),
    );

    const result = await useCase.execute({
      userId: "student-a",
      traceId: "trace-a",
      input: validInput(),
    });

    expect(result.text).toBe("Réponse sûre");
    expect(prompts).toHaveLength(1);
    expect(prompts[0]).toContain("ÉLÈVE EN CLASSE DE : Terminale");
    expect(prompts[0]).toContain("CONTENU_AUTORISE_SCHOOL_A");
    expect(prompts[0]).not.toContain("Première");
    expect(prompts[0]).not.toContain("school-b");
    expect(quotaStore.reservedTraceIds).toEqual(["trace-a"]);
    expect(quotaStore.consumedTraceIds).toEqual(["trace-a"]);
    expect(quotaStore.releasedTraceIds).toEqual([]);
  });
});

describe("AskTutorUseCase with real StudyReserveConsumption chain", () => {
  const DAY = 24 * 60 * 60 * 1000;

  interface AggState {
    allowance: number;
    consumed: number;
    cycleId: string;
    cycleStart: string | null;
    cycleEnd: string | null;
    holds: Record<string, number>;
    ledger: Map<string, { billableUnits: number }>;
  }

  /** Une seule base en mémoire pour le provisionnement ET la consommation :
   * la vraie `ensureCurrentStudyReserveCycle` ouvre le cycle que `reserve`
   * débite ensuite (aucun provisionnement neutralisé). */
  class TestReserveStore implements StudyReserveConsumptionStore, StudyReserveProvisioningStore {
    readonly aggs = new Map<string, AggState>();
    readonly entitlements = new Map<string, StudentEntitlement>();
    readonly plans = new Map<string, StudyReservePlanConfig>();

    /** Élève couvert par un entitlement Mobile Money actif (offre = établissement)
     * et un plan V1 ; le cycle est ouvert à la première requête. */
    subscribe(studentId: string, allowance = 600_000, offerId = "lycee-bilingue-etoug-ebe") {
      const now = Date.now();
      this.entitlements.set(studentId, {
        offerId,
        windowStartMs: now - DAY,
        windowEndMs: now + 29 * DAY,
        active: true,
      });
      this.plans.set(offerId, { allowanceInternal: allowance, cycleDays: 30 });
    }

    /** Abonné dont le cycle courant est déjà ouvert (consommation à régler). */
    seed(studentId: string, allowance: number) {
      this.subscribe(studentId, allowance);
      const entitlement = this.entitlements.get(studentId)!;
      const cycle = computeCurrentCycle(entitlement, 30, Date.now());
      this.aggs.set(studentId, {
        allowance,
        consumed: 0,
        cycleId: cycle.cycleId,
        cycleStart: new Date(cycle.startMs).toISOString(),
        cycleEnd: new Date(cycle.endMs).toISOString(),
        holds: {},
        ledger: new Map(),
      });
    }

    async resolveEntitlement(studentId: string) {
      return this.entitlements.get(studentId) ?? null;
    }

    async planConfig(offerId: string) {
      return this.plans.get(offerId) ?? null;
    }

    async readAggregate(studentId: string): Promise<ReserveAggregate | null> {
      const agg = this.aggs.get(studentId);
      if (!agg) return null;
      return {
        allowanceInternal: agg.allowance,
        consumed: agg.consumed,
        cycleId: agg.cycleId,
        cycleStart: agg.cycleStart,
        cycleEnd: agg.cycleEnd,
        latestThresholdEmitted: null,
      };
    }

    async provisionCycle(studentId: string, fresh: ReserveAggregate) {
      this.aggs.set(studentId, {
        allowance: fresh.allowanceInternal,
        consumed: 0,
        cycleId: fresh.cycleId,
        cycleStart: fresh.cycleStart,
        cycleEnd: fresh.cycleEnd,
        holds: {},
        ledger: this.aggs.get(studentId)?.ledger ?? new Map(),
      });
      return fresh;
    }

    async updateCurrentCycle() {
      return null;
    }

    async reserve(params: { studentId: string; requestId: string; estimateUnits: number }): Promise<ReserveHold> {
      const agg = this.aggs.get(params.studentId);
      if (!agg || agg.allowance <= 0) return { configured: false, reserved: false };
      const held = Object.values(agg.holds).reduce((s, v) => s + v, 0);
      const remaining = agg.allowance - agg.consumed - held;
      if (remaining < params.estimateUnits) {
        throw studyReserveExhaustedError();
      }
      agg.holds[params.requestId] = params.estimateUnits;
      return { configured: true, reserved: true };
    }

    async commit(params: {
      studentId: string;
      requestId: string;
      provider: string;
      model: string;
      usage: { inputUnits: number; outputUnits: number; billableUnits: number };
    }) {
      const agg = this.aggs.get(params.studentId)!;
      delete agg.holds[params.requestId];
      const key = `${agg.cycleId}__${params.requestId}`;
      if (agg.ledger.has(key)) {
        return { duplicate: true, thresholdEvent: null, cycleId: agg.cycleId };
      }
      agg.consumed += params.usage.billableUnits;
      agg.ledger.set(key, { billableUnits: params.usage.billableUnits });
      return { duplicate: false, thresholdEvent: null, cycleId: agg.cycleId };
    }

    async release(params: { studentId: string; requestId: string }) {
      const agg = this.aggs.get(params.studentId);
      if (agg) delete agg.holds[params.requestId];
    }

    async listLinkedParents() {
      return [];
    }
  }

  const fixedContext = new FixedContextStore({
    scope: { classLevel: "Terminale", establishmentId: "school-a" },
    text: "CONTEXT",
  });

  it("provider is NOT invoked if reserve rejects before execution, and quota is released", async () => {
    const reserveStore = new TestReserveStore();
    reserveStore.seed("student-exhausted", 1000);
    // Already consumed 700, remaining 300 < default estimate 1000
    reserveStore.aggs.get("student-exhausted")!.consumed = 700;

    const studyReserve = new StudyReserveConsumption(
      reserveStore,
      new NoopNotifier(),
      reserveStore,
    );
    const quotaStore = new FixedQuotaStore();
    let providerCalled = false;

    const useCase = new AskTutorUseCase(
      fixedContext,
      async () => {
        providerCalled = true;
        return "Not reached";
      },
      quotaStore,
      20,
      studyReserve,
    );

    await expect(
      useCase.execute({
        userId: "student-exhausted",
        traceId: "trace-exhausted",
        input: validInput(),
      }),
    ).rejects.toMatchObject({
      code: "resource-exhausted",
      details: { reason: "study_reserve_exhausted" },
    });

    expect(providerCalled).toBe(false);
    // Daily quota was reserved, then released upon reserve failure
    expect(quotaStore.reservedTraceIds).toContain("trace-exhausted");
    expect(quotaStore.releasedTraceIds).toContain("trace-exhausted");
    expect(quotaStore.consumedTraceIds).toHaveLength(0);
  });

  it("commits real provider usage metadata callback to the reserve ledger", async () => {
    const reserveStore = new TestReserveStore();
    reserveStore.seed("student-active", 600_000);

    const studyReserve = new StudyReserveConsumption(
      reserveStore,
      new NoopNotifier(),
      reserveStore,
    );
    const quotaStore = new FixedQuotaStore();

    const useCase = new AskTutorUseCase(
      fixedContext,
      async ({ onUsage }) => {
        onUsage?.({ promptTokenCount: 150, candidatesTokenCount: 90, totalTokenCount: 240 });
        return "Explication claire.";
      },
      quotaStore,
      20,
      studyReserve,
    );

    const result = await useCase.execute({
      userId: "student-active",
      traceId: "trace-usage-1",
      input: validInput(),
    });

    expect(result.text).toBe("Explication claire.");
    const agg = reserveStore.aggs.get("student-active")!;
    expect(agg.consumed).toBe(240);
    expect(agg.ledger.get(`${agg.cycleId}__trace-usage-1`)?.billableUnits).toBe(240);
    expect(Object.keys(agg.holds)).toHaveLength(0);
  });

  it("provider failure releases the hold without charging usage", async () => {
    const reserveStore = new TestReserveStore();
    reserveStore.seed("student-active", 600_000);

    const studyReserve = new StudyReserveConsumption(
      reserveStore,
      new NoopNotifier(),
      reserveStore,
    );
    const quotaStore = new FixedQuotaStore();

    const useCase = new AskTutorUseCase(
      fixedContext,
      async () => {
        throw new Error("Vertex upstream unavailable");
      },
      quotaStore,
      20,
      studyReserve,
    );

    await expect(
      useCase.execute({
        userId: "student-active",
        traceId: "trace-fail",
        input: validInput(),
      }),
    ).rejects.toThrow("Vertex upstream unavailable");

    const agg = reserveStore.aggs.get("student-active")!;
    expect(agg.consumed).toBe(0);
    expect(Object.keys(agg.holds)).toHaveLength(0);
    expect(quotaStore.releasedTraceIds).toContain("trace-fail");
  });

  it("never charges the learner's reserve for a billed answer that was not delivered", async () => {
    const store = new TestReserveStore();
    store.seed("student-billed", 600_000);
    const quota = new FixedQuotaStore();
    const useCase = new AskTutorUseCase(
      fixedContext,
      async ({ onUsage }) => {
        onUsage?.({ promptTokenCount: 4000, candidatesTokenCount: 8192, totalTokenCount: 12192 });
        throw new Error("Vertex AI response validation failed.");
      },
      quota,
      20,
      new StudyReserveConsumption(store, new NoopNotifier(), store),
    );

    await expect(useCase.execute({
      userId: "student-billed",
      traceId: "trace-billed",
      input: validInput(),
    })).rejects.toThrow("Vertex AI response validation failed.");

    // Coût fournisseur ≠ débit visible par l'élève : la réservation est rendue.
    expect(store.aggs.get("student-billed")!.consumed).toBe(0);
    expect(store.aggs.get("student-billed")!.holds).toEqual({});
    expect(quota.consumedTraceIds).toEqual([]);
    expect(quota.releasedTraceIds).toEqual(["trace-billed"]);
  });

  it("idempotent retry with same traceId does not double-charge", async () => {
    const reserveStore = new TestReserveStore();
    reserveStore.seed("student-active", 600_000);

    const studyReserve = new StudyReserveConsumption(
      reserveStore,
      new NoopNotifier(),
      reserveStore,
    );
    const quotaStore = new FixedQuotaStore();

    let providerCalls = 0;
    const textGen = async ({ onUsage }: { onUsage?: (usage: LlmTokenUsage | undefined) => void }) => {
      providerCalls++;
      onUsage?.({ promptTokenCount: 100, candidatesTokenCount: 50, totalTokenCount: 150 });
      return "Réponse";
    };

    const useCase = new AskTutorUseCase(fixedContext, textGen, quotaStore, 20, studyReserve);

    await useCase.execute({
      userId: "student-active",
      traceId: "trace-idem",
      input: validInput(),
    });
    expect(reserveStore.aggs.get("student-active")!.consumed).toBe(150);

    await useCase.execute({
      userId: "student-active",
      traceId: "trace-idem",
      input: validInput(),
    });
    expect(reserveStore.aggs.get("student-active")!.consumed).toBe(150); // NOT 300
    // Le rejeu ré-exécute le fournisseur (la réponse n'est pas mise en cache),
    // mais le ledger ne débite l'identifiant qu'une seule fois.
    expect(providerCalls).toBe(2);
  });

  it("auto-provisions a subscribed student's first cycle on the tutor path, then charges real usage", async () => {
    const reserveStore = new TestReserveStore();
    reserveStore.subscribe("student-new"); // aucun agrégat study_reserve
    expect(reserveStore.aggs.has("student-new")).toBe(false);

    const useCase = new AskTutorUseCase(
      fixedContext,
      async ({ onUsage }) => {
        onUsage?.({ promptTokenCount: 400, candidatesTokenCount: 200, totalTokenCount: 600 });
        return "Première réponse";
      },
      new FixedQuotaStore(),
      20,
      new StudyReserveConsumption(reserveStore, new NoopNotifier(), reserveStore),
    );
    await useCase.execute({ userId: "student-new", traceId: "trace-first", input: validInput() });

    expect(reserveStore.aggs.get("student-new")).toMatchObject({ allowance: 600_000, consumed: 600 });
  });

  it("daily question limit exhaustion remains distinguishable from study reserve exhaustion", async () => {
    const reserveStore = new TestReserveStore();
    reserveStore.seed("student-quota", 600_000);

    class ExhaustedDailyQuotaStore extends FixedQuotaStore {
      override async reserve(): Promise<TutorQuotaSnapshot> {
        throw new AppError("resource-exhausted", "Daily question quota exceeded.", {
          limit: 20,
          remaining: 0,
        });
      }
    }

    const studyReserve = new StudyReserveConsumption(
      reserveStore,
      new NoopNotifier(),
      reserveStore,
    );

    const useCase = new AskTutorUseCase(
      fixedContext,
      async () => "Never called",
      new ExhaustedDailyQuotaStore(),
      20,
      studyReserve,
    );

    try {
      await useCase.execute({
        userId: "student-quota",
        traceId: "trace-daily",
        input: validInput(),
      });
      expect.unreachable();
    } catch (err: unknown) {
      const appErr = err as AppError;
      expect(appErr.code).toBe("resource-exhausted");
      // MUST NOT have study_reserve_exhausted reason!
      expect((appErr.details as Record<string, unknown>)?.reason).toBeUndefined();
    }
  });
});

class FixedContextStore implements TutorContextStore {
  constructor(private readonly context: AuthorizedTutorContext) {}

  async loadAuthorizedContext(): Promise<AuthorizedTutorContext> {
    return this.context;
  }
}

class FixedQuotaStore implements TutorQuotaStore {
  readonly reservedTraceIds: string[] = [];
  readonly consumedTraceIds: string[] = [];
  readonly releasedTraceIds: string[] = [];

  async reserve(params: {
    userId: string;
    traceId: string;
    limit: number;
  }): Promise<TutorQuotaSnapshot> {
    this.reservedTraceIds.push(params.traceId);
    return quotaSnapshot(params.limit);
  }

  async consume(params: {
    userId: string;
    traceId: string;
    limit: number;
  }): Promise<TutorQuotaSnapshot> {
    this.consumedTraceIds.push(params.traceId);
    return quotaSnapshot(params.limit);
  }

  async release(params: { userId: string; traceId: string }): Promise<void> {
    this.releasedTraceIds.push(params.traceId);
  }
}

function quotaSnapshot(limit: number): TutorQuotaSnapshot {
  return {
    limit,
    remaining: limit - 1,
    resetsAt: "2026-08-30T23:00:00.000Z",
  };
}

function validInput(): AskTutorCallableInput {
  return {
    classLevel: "Terminale",
    userMessage: "Explique-moi cette notion.",
    history: [],
    tutorId: "kira",
  };
}
