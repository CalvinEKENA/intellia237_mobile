import { describe, expect, it } from "vitest";

import {
  ASK_TUTOR_CALLABLE_TIMEOUT_SECONDS,
  TUTOR_IN_PROGRESS_WAIT_MS,
  TUTOR_PROVIDER_TIMEOUT_MS,
  TUTOR_SERVER_OVERHEAD_BUDGET_MS,
} from "../config/timeouts";
import {
  AskTutorUseCase,
  type AuthorizedTutorContext,
  type TutorContextStore,
} from "../services/askTutorUseCase";
import {
  StudyReserveConsumption,
  type ReserveHold,
  type StudyReserveConsumptionStore,
} from "../services/studyReserveConsumption";
import type { StudyReserveProvisioningStore } from "../services/studyReserveProvisioning";
import type { ReserveAggregate } from "../services/studyReserve";
import type { TutorQuotaSnapshot, TutorQuotaStore } from "../services/tutorDailyQuota";
import {
  TUTOR_REQUEST_MAX_EXECUTIONS,
  TUTOR_REQUEST_RETENTION_MS,
  decideTutorRequestClaim,
  tutorRequestPayloadHash,
  type CachedTutorResponse,
  type TutorRequestClaim,
  type TutorRequestLedger,
  type TutorRequestRecord,
} from "../services/tutorRequestLedger";
import { AppError } from "../utils/errors";

/** Registre en mémoire qui applique la même décision que Firestore. */
class MemoryLedger implements TutorRequestLedger {
  readonly records = new Map<string, TutorRequestRecord>();
  constructor(private readonly now: () => number = () => Date.now()) {}

  async claim(params: { userId: string; requestId: string; payloadHash: string; leaseMs: number }): Promise<TutorRequestClaim> {
    const key = `${params.userId}__${params.requestId}`;
    const { claim, next } = decideTutorRequestClaim({
      existing: this.records.get(key) ?? null,
      payloadHash: params.payloadHash,
      nowMs: this.now(),
      leaseMs: params.leaseMs,
    });
    if (next) this.records.set(key, next);
    return claim;
  }
  async complete(params: { userId: string; requestId: string; response: CachedTutorResponse }) {
    const key = `${params.userId}__${params.requestId}`;
    const record = this.records.get(key)!;
    this.records.set(key, { ...record, state: "completed", quotaCharged: true, response: params.response, leaseUntilMs: 0 });
  }
  async fail(params: { userId: string; requestId: string; quotaCharged: boolean }) {
    const key = `${params.userId}__${params.requestId}`;
    const record = this.records.get(key)!;
    this.records.set(key, { ...record, state: "failed", quotaCharged: params.quotaCharged, leaseUntilMs: 0 });
  }
  async read(params: { userId: string; requestId: string }) {
    return this.records.get(`${params.userId}__${params.requestId}`) ?? null;
  }
}

class CountingQuota implements TutorQuotaStore {
  reserved: string[] = [];
  consumed: string[] = [];
  released: string[] = [];
  used = 0;
  private readonly holds = new Set<string>();
  async reserve(params: { traceId: string; limit: number }): Promise<TutorQuotaSnapshot> {
    this.reserved.push(params.traceId);
    this.holds.add(params.traceId);
    return this.snapshot(params.limit);
  }
  async consume(params: { traceId: string; limit: number }): Promise<TutorQuotaSnapshot> {
    this.consumed.push(params.traceId);
    if (this.holds.delete(params.traceId)) this.used += 1;
    return this.snapshot(params.limit);
  }
  async release(params: { traceId: string }): Promise<void> {
    this.released.push(params.traceId);
    this.holds.delete(params.traceId);
  }
  private snapshot(limit: number): TutorQuotaSnapshot {
    return { limit, remaining: limit - this.used - this.holds.size, resetsAt: "2026-09-21T23:00:00.000Z" };
  }
}

class NoReserveStore implements StudyReserveConsumptionStore {
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

class NoProvisioning implements StudyReserveProvisioningStore {
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

const context: TutorContextStore = {
  async loadAuthorizedContext(): Promise<AuthorizedTutorContext> {
    return { scope: { classLevel: "Terminale", establishmentId: null }, text: "", language: "fr" };
  },
};

function build(params: {
  ledger: MemoryLedger;
  quota: CountingQuota;
  generator: () => Promise<string>;
  onUsage?: boolean;
  sleep?: (ms: number) => Promise<void>;
}) {
  let providerCalls = 0;
  const useCase = new AskTutorUseCase(
    context,
    async ({ onUsage }) => {
      providerCalls += 1;
      if (params.onUsage) onUsage?.({ promptTokenCount: 1000, candidatesTokenCount: 200, totalTokenCount: 1200 });
      return params.generator();
    },
    params.quota,
    20,
    new StudyReserveConsumption(new NoReserveStore(), { emit: async () => undefined }, new NoProvisioning()),
    params.ledger,
    params.sleep ?? (async () => undefined),
  );
  return { useCase, providerCalls: () => providerCalls };
}

const input = (requestId?: string) => ({
  userMessage: "Explique les fractions.",
  classLevel: "Terminale",
  history: [],
  tutorId: "kira" as const,
  ...(requestId ? { requestId } : {}),
});

describe("askTutor idempotency", () => {
  it("returns the stored answer on a retry, without a second Gemini call or quota", async () => {
    const ledger = new MemoryLedger();
    const quota = new CountingQuota();
    const { useCase, providerCalls } = build({ ledger, quota, generator: async () => "Réponse." });

    const first = await useCase.execute({ userId: "s1", traceId: "t1", input: input("req-00000001") });
    const retry = await useCase.execute({ userId: "s1", traceId: "t2", input: input("req-00000001") });

    expect(retry).toEqual(first);
    expect(providerCalls()).toBe(1);
    expect(quota.reserved).toEqual(["req-00000001"]);
    expect(quota.used).toBe(1);
  });

  it("waits for a still-running first attempt and returns its answer", async () => {
    const ledger = new MemoryLedger();
    const quota = new CountingQuota();
    await ledger.claim({ userId: "s1", requestId: "req-running", payloadHash: tutorRequestPayloadHash(input()), leaseMs: 60_000 });
    let polls = 0;
    const { useCase, providerCalls } = build({
      ledger,
      quota,
      generator: async () => "jamais appelé",
      sleep: async () => {
        polls += 1;
        if (polls === 2) {
          await ledger.complete({
            userId: "s1",
            requestId: "req-running",
            response: { text: "Réponse finale.", limit: 20, remaining: 19, resetsAt: "x" },
          });
        }
      },
    });

    const result = await useCase.execute({ userId: "s1", traceId: "t2", input: input("req-running") });

    expect(result.text).toBe("Réponse finale.");
    expect(providerCalls()).toBe(0);
    expect(quota.reserved).toEqual([]);
  });

  it("tells the phone to come back later if the first attempt outlives the wait", async () => {
    const ledger = new MemoryLedger();
    await ledger.claim({ userId: "s1", requestId: "req-slow", payloadHash: tutorRequestPayloadHash(input()), leaseMs: 60_000 });
    const realNow = Date.now;
    let clock = realNow();
    Date.now = () => clock;
    try {
      const { useCase } = build({
        ledger,
        quota: new CountingQuota(),
        generator: async () => "x",
        sleep: async (ms) => {
          clock += ms;
        },
      });
      await expect(useCase.execute({ userId: "s1", traceId: "t", input: input("req-slow") }))
        .rejects.toMatchObject({ code: "unavailable", details: { reason: "tutor_request_in_progress" } });
    } finally {
      Date.now = realNow;
    }
  });

  it("does not charge the daily slot twice when a billed failure is retried", async () => {
    const ledger = new MemoryLedger();
    const quota = new CountingQuota();
    let attempt = 0;
    const { useCase, providerCalls } = build({
      ledger,
      quota,
      onUsage: true,
      generator: async () => {
        attempt += 1;
        if (attempt === 1) throw new Error("Vertex AI response validation failed.");
        return "Réponse après relance.";
      },
    });

    await expect(useCase.execute({ userId: "s1", traceId: "t1", input: input("req-billed") })).rejects.toThrow();
    const retry = await useCase.execute({ userId: "s1", traceId: "t2", input: input("req-billed") });

    expect(retry.text).toBe("Réponse après relance.");
    expect(providerCalls()).toBe(2);
    expect(quota.reserved).toEqual(["req-billed"]);
    expect(quota.used).toBe(1);
  });

  it("stops retrying a failing request after the execution budget", async () => {
    const ledger = new MemoryLedger();
    const { useCase, providerCalls } = build({
      ledger,
      quota: new CountingQuota(),
      generator: async () => {
        throw new AppError("unavailable", "AI service is temporarily unavailable.");
      },
    });
    for (let index = 0; index < TUTOR_REQUEST_MAX_EXECUTIONS; index++) {
      await expect(useCase.execute({ userId: "s1", traceId: `t${index}`, input: input("req-limit") })).rejects.toThrow();
    }
    await expect(useCase.execute({ userId: "s1", traceId: "tx", input: input("req-limit") }))
      .rejects.toMatchObject({ code: "failed-precondition" });
    expect(providerCalls()).toBe(TUTOR_REQUEST_MAX_EXECUTIONS);
  });

  it("refuses to reuse an identifier for a different question", async () => {
    const ledger = new MemoryLedger();
    const { useCase } = build({ ledger, quota: new CountingQuota(), generator: async () => "ok" });
    await useCase.execute({ userId: "s1", traceId: "t1", input: input("req-reused") });
    await expect(useCase.execute({
      userId: "s1",
      traceId: "t2",
      input: { ...input("req-reused"), userMessage: "Une autre question." },
    })).rejects.toMatchObject({ code: "invalid-argument" });
  });

  it("keeps each learner's identifiers separate", async () => {
    const ledger = new MemoryLedger();
    const { useCase, providerCalls } = build({ ledger, quota: new CountingQuota(), generator: async () => "ok" });
    await useCase.execute({ userId: "s1", traceId: "t1", input: input("req-shared") });
    await useCase.execute({ userId: "s2", traceId: "t2", input: input("req-shared") });
    expect(providerCalls()).toBe(2);
  });

  it("forgets a record after its retention window", () => {
    const now = 1_000_000;
    const { claim } = decideTutorRequestClaim({
      existing: {
        state: "completed",
        payloadHash: "h",
        executions: 1,
        leaseUntilMs: 0,
        quotaCharged: true,
        expireAtMs: now - 1,
        response: { text: "old", limit: 20, remaining: 19, resetsAt: "x" },
      },
      payloadHash: "other",
      nowMs: now,
      leaseMs: 1000,
    });
    expect(claim.kind).toBe("execute");
    expect(TUTOR_REQUEST_RETENTION_MS).toBe(15 * 60 * 1000);
  });

  it("keeps the legacy path (no requestId) away from the ledger", async () => {
    const ledger = new MemoryLedger();
    const { useCase } = build({ ledger, quota: new CountingQuota(), generator: async () => "ok" });
    await useCase.execute({ userId: "s1", traceId: "t1", input: input() });
    expect(ledger.records.size).toBe(0);
  });
});

describe("tutor timeout contract", () => {
  it("orders provider < callable, with room for server work and for waiting retries", () => {
    expect(TUTOR_PROVIDER_TIMEOUT_MS + TUTOR_SERVER_OVERHEAD_BUDGET_MS)
      .toBeLessThanOrEqual(ASK_TUTOR_CALLABLE_TIMEOUT_SECONDS * 1_000);
    expect(TUTOR_IN_PROGRESS_WAIT_MS + 5_000).toBeLessThan(ASK_TUTOR_CALLABLE_TIMEOUT_SECONDS * 1_000);
  });
});
