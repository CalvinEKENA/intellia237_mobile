import { describe, expect, it } from "vitest";

import { ACTIVITY_CLOSE, ACTIVITY_OPEN } from "../llm/interactiveBlocks";
import {
  AskTutorUseCase,
  MAX_TOKENS_FINISH_REASON,
  TUTOR_ANSWER_UNDELIVERED_REASON,
  withTruncationNotice,
  type AuthorizedTutorContext,
  type TutorContextStore,
} from "../services/askTutorUseCase";
import {
  StudyReserveConsumption,
  type ProviderUsage,
  type ReserveHold,
  type StudyReserveConsumptionStore,
} from "../services/studyReserveConsumption";
import {
  TUTOR_FREE_UNDELIVERED_ANSWERS_PER_DAY,
  type TutorQuotaSnapshot,
  type TutorQuotaStore,
  type TutorUndeliveredSettlement,
} from "../services/tutorDailyQuota";
import { AppError } from "../utils/errors";
import type { AskTutorCallableInput } from "../utils/validation";
import { CurrentCycleProvisioning } from "./support/currentCycleProvisioning";

/**
 * Principe propriétaire : si aucune réponse utilisable n'est livrée à
 * l'élève, sa question n'est pas traitée comme une question réussie — ni le
 * quota quotidien ni la Réserve d'étude ne sont débités (dans la limite d'un
 * plafond anti-abus). Le coût fournisseur éventuel reste un coût interne,
 * jamais un débit visible ; il n'est pas « annulé » chez Vertex AI.
 */

const USAGE = { promptTokenCount: 4000, candidatesTokenCount: 8192, totalTokenCount: 12192 };
const LIMIT = 20;

class Quota implements TutorQuotaStore {
  used = 0;
  undelivered = 0;
  consumed: string[] = [];
  released: string[] = [];
  settled: string[] = [];
  private readonly holds = new Set<string>();
  constructor(private readonly freeUndelivered = TUTOR_FREE_UNDELIVERED_ANSWERS_PER_DAY) {}
  async reserve(params: { traceId: string; limit: number }) {
    this.holds.add(params.traceId);
    return { ...this.snapshot(params.limit), dayKey: "2026-09-22" };
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
  async settleUndelivered(params: { traceId: string; limit: number }): Promise<TutorUndeliveredSettlement> {
    this.settled.push(params.traceId);
    let debited = false;
    if (this.holds.delete(params.traceId)) {
      debited = this.undelivered >= this.freeUndelivered;
      this.undelivered += 1;
      if (debited) this.used += 1;
    }
    return { debited, snapshot: this.snapshot(params.limit) };
  }
  private snapshot(limit: number): TutorQuotaSnapshot {
    return { limit, remaining: limit - this.used - this.holds.size, resetsAt: "2026-09-22T23:00:00.000Z" };
  }
}

class Reserve implements StudyReserveConsumptionStore {
  commits: ProviderUsage[] = [];
  releases = 0;
  async reserve(): Promise<ReserveHold> {
    return { configured: true, reserved: true };
  }
  async commit(params: { usage: ProviderUsage }) {
    this.commits.push(params.usage);
    return { duplicate: false, thresholdEvent: null, cycleId: "c1" };
  }
  async release(): Promise<void> {
    this.releases += 1;
  }
  async listLinkedParents(): Promise<string[]> {
    return [];
  }
}

/** Un cycle de Réserve actif : la réservation est réellement tenue. */
const activeCycle = () => new CurrentCycleProvisioning(async () => ({
  allowanceInternal: 600_000,
  consumed: 0,
  cycleId: "c1",
  cycleStart: "2026-09-01T00:00:00.000Z",
  cycleEnd: "2100-01-01T00:00:00.000Z",
  latestThresholdEmitted: null,
}));

const context: TutorContextStore = {
  async loadAuthorizedContext(): Promise<AuthorizedTutorContext> {
    return { scope: { classLevel: "6eme", establishmentId: null }, text: "", language: "fr" };
  },
};

function input(): AskTutorCallableInput {
  return {
    userMessage: "Explique les fractions",
    history: [],
    classLevel: "6eme",
    tutorId: "kira",
    activities: ["word_order"],
  } as AskTutorCallableInput;
}

function build(
  generator: ConstructorParameters<typeof AskTutorUseCase>[1],
  quota = new Quota(),
  reserve = new Reserve(),
) {
  const useCase = new AskTutorUseCase(
    context,
    generator,
    quota,
    LIMIT,
    new StudyReserveConsumption(reserve, { emit: async () => undefined }, activeCycle()),
  );
  return { useCase, quota, reserve };
}

const activity = (json: string) => `${ACTIVITY_OPEN}\n${json}\n${ACTIVITY_CLOSE}`;
const validActivity = activity(JSON.stringify({ type: "word_order", sequence: ["I", "want", "to", "go"], trailing: "." }));

describe("undelivered tutor answers are not successful questions", () => {
  it("an empty answer: nothing delivered, quota and reserve given back", async () => {
    const { useCase, quota, reserve } = build(async ({ onUsage, onFinishReason }) => {
      onUsage?.(USAGE);
      onFinishReason?.(MAX_TOKENS_FINISH_REASON);
      // Le client LLM lève cette erreur quand le texte est vide.
      throw new Error("Vertex AI response validation failed.");
    });
    await expect(useCase.execute({ userId: "s1", traceId: "t-empty", input: input() })).rejects.toThrow();
    expect(quota.used).toBe(0);
    expect(quota.settled).toEqual(["t-empty"]);
    expect(quota.consumed).toEqual([]);
    expect(reserve.commits).toEqual([]);
    expect(reserve.releases).toBe(1);
  });

  it("an answer made only of an invalid activity is undelivered", async () => {
    const { useCase, quota, reserve } = build(async ({ onUsage }) => {
      onUsage?.(USAGE);
      return activity("{ not json");
    });
    await expect(useCase.execute({ userId: "s1", traceId: "t-block", input: input() }))
      .rejects.toMatchObject({ code: "unavailable", details: { reason: TUTOR_ANSWER_UNDELIVERED_REASON } });
    expect(quota.used).toBe(0);
    expect(reserve.commits).toEqual([]);
  });

  it("a truncated answer is delivered with a notice and not counted", async () => {
    const { useCase, quota, reserve } = build(async ({ onUsage, onFinishReason }) => {
      onUsage?.(USAGE);
      onFinishReason?.(MAX_TOKENS_FINISH_REASON);
      return `Une fraction représente une partie d’un tout. Par exemple ${ACTIVITY_OPEN}\n{"type":"word_order","seq`;
    });
    const answer = await useCase.execute({ userId: "s1", traceId: "t-cut", input: input() });
    expect(answer.text).toContain("Une fraction représente une partie d’un tout.");
    expect(answer.text).toContain("écris « la suite »");
    expect(answer.text).not.toContain(ACTIVITY_OPEN);
    expect(answer.block).toBeUndefined();
    expect(quota.used).toBe(0);
    expect(quota.consumed).toEqual([]);
    expect(answer.remaining).toBe(LIMIT);
    expect(reserve.commits).toEqual([]);
    expect(reserve.releases).toBe(1);
  });

  it("a useful text with an invalid activity is a normal, charged answer", async () => {
    const { useCase, quota, reserve } = build(async ({ onUsage, onFinishReason }) => {
      onUsage?.(USAGE);
      onFinishReason?.("STOP");
      return `Voici l’explication.\n${activity("{ broken")}`;
    });
    const answer = await useCase.execute({ userId: "s1", traceId: "t-text", input: input() });
    expect(answer.text).toBe("Voici l’explication.");
    expect(answer.block).toBeUndefined();
    expect(quota.used).toBe(1);
    expect(reserve.commits).toHaveLength(1);
  });

  it("a complete answer with a valid activity is charged as before", async () => {
    const { useCase, quota, reserve } = build(async ({ onUsage, onFinishReason }) => {
      onUsage?.(USAGE);
      onFinishReason?.("STOP");
      return `À toi de jouer.\n${validActivity}`;
    });
    const answer = await useCase.execute({ userId: "s1", traceId: "t-ok", input: input() });
    expect(answer.block).toBeDefined();
    expect(quota.used).toBe(1);
    expect(reserve.commits[0]?.billableUnits).toBe(12192);
  });

  it("a provider timeout gives the question back", async () => {
    const { useCase, quota } = build(async () => {
      throw new AppError("deadline-exceeded", "AI service request timed out.");
    });
    await expect(useCase.execute({ userId: "s1", traceId: "t-timeout", input: input() }))
      .rejects.toMatchObject({ code: "deadline-exceeded" });
    expect(quota.used).toBe(0);
    expect(quota.settled).toEqual(["t-timeout"]);
  });

  it("beyond the daily cap, an undelivered answer is counted", async () => {
    const quota = new Quota();
    const reserve = new Reserve();
    const { useCase } = build(async ({ onUsage }) => {
      onUsage?.(USAGE);
      throw new Error("Vertex AI response validation failed.");
    }, quota, reserve);
    for (let index = 0; index < TUTOR_FREE_UNDELIVERED_ANSWERS_PER_DAY; index++) {
      await expect(useCase.execute({ userId: "s1", traceId: `free-${index}`, input: input() })).rejects.toThrow();
    }
    expect(quota.used).toBe(0);
    expect(reserve.commits).toEqual([]);

    await expect(useCase.execute({ userId: "s1", traceId: "over-cap", input: input() })).rejects.toThrow();
    expect(quota.used).toBe(1);
    // Au-delà du plafond, l'usage réel est imputé comme avant.
    expect(reserve.commits).toHaveLength(1);
  });

  it("the notice follows the learner's language", () => {
    expect(withTruncationNotice("Hello.", "en")).toBe("Hello.\n\n(My answer was cut short: type “continue” and I will go on.)");
    expect(withTruncationNotice("   ", "fr")).toBe("(Ma réponse a été coupée : écris « la suite » pour que je continue.)");
  });
});
