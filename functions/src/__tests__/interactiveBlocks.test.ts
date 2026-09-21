import { describe, expect, it } from "vitest";

import {
  ACTIVITY_CLOSE,
  ACTIVITY_OPEN,
  BLOCK_LIMITS,
  BLOCK_TYPES,
  SUPPORTED_BLOCK_TYPES,
  activityOutcomeSchema,
  buildActivityInstructions,
  extractInteractiveBlock,
  negotiateActivityTypes,
  renderActivityOutcome,
  type BlockType,
} from "../llm/interactiveBlocks";
import { MAX_SYSTEM_PROMPT_CHARS } from "../llm/tutorBudget";
import { buildTutorSystemPrompt } from "../llm/tutorPersonas";
import {
  AskTutorUseCase,
  type AuthorizedTutorContext,
} from "../services/askTutorUseCase";
import {
  StudyReserveConsumption,
  type ReserveHold,
  type StudyReserveConsumptionStore,
} from "../services/studyReserveConsumption";
import type { StudyReserveProvisioningStore } from "../services/studyReserveProvisioning";
import type { ReserveAggregate } from "../services/studyReserve";
import type { TutorQuotaStore } from "../services/tutorDailyQuota";
import { askTutorCallableInputSchema } from "../utils/validation";

const ALL: BlockType[] = [...SUPPORTED_BLOCK_TYPES];

function reply(block: unknown, prose = "Voici l'explication.") {
  return `${prose}\n${ACTIVITY_OPEN}\n${typeof block === "string" ? block : JSON.stringify(block)}\n${ACTIVITY_CLOSE}`;
}

function counterIds() {
  let n = 0;
  return (prefix: string) => `${prefix}_${++n}`;
}

describe("interactive block registry", () => {
  it("renders only ordering today, and keeps the other families as planned architecture", () => {
    expect(ALL.sort()).toEqual(
      ["equation_order", "process_sequence", "sequence", "step_order", "timeline_order", "word_order"],
    );
    for (const planned of ["multiple_choice", "true_false", "fill_blank", "matching", "classification", "numeric_input", "diagram_labeling", "map_interaction"] as const) {
      expect(BLOCK_TYPES[planned].supported).toBe(false);
    }
  });

  it("negotiates the intersection of what the phone renders and the server validates", () => {
    expect(negotiateActivityTypes(undefined)).toEqual([]);
    expect(negotiateActivityTypes(["word_order", "multiple_choice", "html"])).toEqual(["word_order"]);
  });
});

describe("block extraction and validation", () => {
  const valid = {
    type: "word_order",
    instruction: "Put the words in the correct order.",
    sequence: ["I", "want", "to", "go"],
    trailing: ".",
    hints: ["Start with the subject."],
    explanation: "Subject, verb, then infinitive.",
    difficulty: 1,
    rationale: "Checks basic sentence order.",
    language: "en",
  };

  it("builds server-owned ids and a solution that is a permutation of them", () => {
    const { text, block } = extractInteractiveBlock(reply(valid), { allowed: ALL, language: "fr", generateId: counterIds() });
    expect(text).toBe("Voici l'explication.");
    expect(block).not.toBeNull();
    expect(block!.items.map((item) => item.text)).toEqual(["I", "want", "to", "go"]);
    expect(new Set(block!.items.map((item) => item.id)).size).toBe(4);
    expect(block!.solution).toEqual(block!.items.map((item) => item.id));
    expect(block!.layout).toBe("inline");
    expect(block!.language).toBe("en");
    expect(block!.trailing).toBe(".");
  });

  it("gives duplicate words distinct identities", () => {
    const { block } = extractInteractiveBlock(reply({ ...valid, sequence: ["I", "think", "I", "can"] }), {
      allowed: ALL,
      language: "en",
    });
    expect(block!.items.filter((item) => item.text === "I")).toHaveLength(2);
    expect(new Set(block!.items.map((item) => item.id)).size).toBe(4);
  });

  it("never lets the marker leak into the text, even when the block is rejected", () => {
    for (const bad of ["{not json", JSON.stringify({ ...valid, type: "html" })]) {
      const result = extractInteractiveBlock(reply(bad), { allowed: ALL, language: "fr" });
      expect(result.block).toBeNull();
      expect(result.text).not.toContain("ACTIVITY");
      expect(result.text).toBe("Voici l'explication.");
    }
  });

  it("rejects unknown, planned, non-negotiated and malformed blocks", () => {
    const cases: Array<[unknown, BlockType[], string]> = [
      [{ ...valid, type: "html_widget" }, ALL, "unknown_type"],
      [{ ...valid, type: "multiple_choice" }, ["multiple_choice" as BlockType, ...ALL], "type_not_rendered"],
      [valid, [], "activities_not_negotiated"],
      [valid, ["step_order"], "type_not_allowed"],
      [{ ...valid, sequence: Array.from({ length: 11 }, (_, i) => `w${i}`) }, ALL, "invalid_schema"],
      [{ ...valid, sequence: ["I", "x".repeat(BLOCK_LIMITS.inlineItemChars + 1)] }, ALL, "item_length"],
      [{ ...valid, instruction: "x".repeat(BLOCK_LIMITS.instructionChars + 1) }, ALL, "invalid_schema"],
      [{ ...valid, hints: ["a", "b", "c", "d"] }, ALL, "invalid_schema"],
      [{ ...valid, sequence: ["go", "go"] }, ALL, "not_orderable"],
      [{ ...valid, component: "Container" }, ALL, "invalid_schema"],
      [{ ...valid, route: "/admin" }, ALL, "invalid_schema"],
      [{ ...valid, type: "step_order", trailing: "." }, ALL, "trailing_on_stacked"],
    ];
    for (const [payload, allowed, reason] of cases) {
      const result = extractInteractiveBlock(reply(payload), { allowed, language: "fr" });
      expect(result.block, reason).toBeNull();
      expect(result.rejection, JSON.stringify(payload).slice(0, 60)).toBe(reason);
    }
  });

  it("rejects oversized payloads before parsing them", () => {
    const huge = JSON.stringify({ ...valid, explanation: "x".repeat(BLOCK_LIMITS.maxRawChars) });
    expect(extractInteractiveBlock(reply(huge), { allowed: ALL, language: "fr" }).rejection).toBe("too_large");
  });

  it("supports stacked ordering for other subjects (history, SVT, maths)", () => {
    const timeline = extractInteractiveBlock(reply({
      type: "timeline_order",
      instruction: "Remets ces événements dans l'ordre chronologique.",
      sequence: ["Protectorat allemand (1884)", "Indépendance du Cameroun (1960)", "Réunification (1961)"],
      difficulty: 2,
    }), { allowed: ALL, language: "fr" });
    expect(timeline.block?.layout).toBe("stacked");
    const steps = extractInteractiveBlock(reply({
      type: "equation_order",
      sequence: ["3x + 4 = 19", "3x = 15", "x = 5"],
    }), { allowed: ALL, language: "fr" });
    expect(steps.block?.type).toBe("equation_order");
  });

  it("keeps the reply untouched when no activity is proposed", () => {
    expect(extractInteractiveBlock("  Réponse simple.  ", { allowed: ALL, language: "fr" }))
      .toEqual({ text: "Réponse simple.", block: null });
  });
});

describe("activity instructions and outcomes", () => {
  it("fit in the system prompt budget for both companions and languages", () => {
    for (const id of ["kira", "leo"] as const) {
      for (const language of ["fr", "en"] as const) {
        const prompt = buildTutorSystemPrompt(id, language, {
          activityInstructions: buildActivityInstructions(ALL, language),
        });
        expect(prompt.length).toBeLessThanOrEqual(MAX_SYSTEM_PROMPT_CHARS);
        expect(prompt).toContain(ACTIVITY_OPEN);
      }
    }
    expect(buildActivityInstructions([], "fr")).toBeUndefined();
  });

  it("choose the interaction by subject, not word_order everywhere", () => {
    const fr = buildActivityInstructions(ALL, "fr")!;
    expect(fr).toContain("histoire : timeline_order");
    expect(fr).toContain("SVT : process_sequence");
    expect(fr).toContain("mathématiques : step_order ou equation_order");
    expect(fr).toContain("anglais, français, langues : word_order");
  });

  it("validates and renders an activity outcome factually", () => {
    const outcome = activityOutcomeSchema.parse({ blockId: "blk_1", type: "word_order", correct: false, attempts: 3, hintsUsed: 1 });
    expect(renderActivityOutcome(outcome, "fr")).toContain("pas encore réussie, 3 essai(s), 1 indice(s)");
    expect(activityOutcomeSchema.safeParse({ blockId: "x", type: "html", correct: true, attempts: 1, hintsUsed: 0 }).success).toBe(false);
    expect(activityOutcomeSchema.safeParse({ blockId: "blk_1", type: "word_order", correct: true, attempts: 1, hintsUsed: 0, note: "x" }).success).toBe(false);
  });
});

class Quota implements TutorQuotaStore {
  async reserve(params: { limit: number }) {
    return { limit: params.limit, remaining: 19, resetsAt: "x" };
  }
  async consume(params: { limit: number }) {
    return { limit: params.limit, remaining: 19, resetsAt: "x" };
  }
  async release() {}
}
class NoReserve implements StudyReserveConsumptionStore {
  async reserve(): Promise<ReserveHold> {
    return { configured: false, reserved: false };
  }
  async commit() {
    return { duplicate: false, thresholdEvent: null, cycleId: "" };
  }
  async release() {}
  async listLinkedParents() {
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
  async provisionCycle(_: string, fresh: ReserveAggregate) {
    return fresh;
  }
}

describe("askTutor with interactive blocks", () => {
  function useCase(onCall: (system: string, prompt: string) => string) {
    return new AskTutorUseCase(
      { loadAuthorizedContext: async (): Promise<AuthorizedTutorContext> => ({ scope: { classLevel: "6eme", establishmentId: null }, text: "", language: "fr" }) },
      async ({ system, prompt }) => onCall(system, prompt),
      new Quota(),
      20,
      new StudyReserveConsumption(new NoReserve(), { emit: async () => undefined }, new NoProvisioning()),
    );
  }

  it("serves a validated block only to a phone that declared it can render it", async () => {
    const answer = reply({ type: "word_order", instruction: "Remets les mots dans l'ordre.", sequence: ["I", "want", "to", "go"], trailing: "." });
    const systems: string[] = [];
    const tutor = useCase((system) => {
      systems.push(system);
      return answer;
    });
    const modern = await tutor.execute({
      userId: "s1",
      traceId: "t1",
      input: askTutorCallableInputSchema.parse({ userMessage: "Aide", classLevel: "6eme", history: [], tutorId: "kira", activities: ["word_order"] }),
    });
    expect(modern.text).toBe("Voici l'explication.");
    expect(modern.block).toMatchObject({ type: "word_order", layout: "inline" });
    expect(systems[0]).toContain("ACTIVITÉS INTERACTIVES");

    const legacy = await tutor.execute({
      userId: "s1",
      traceId: "t2",
      input: askTutorCallableInputSchema.parse({ userMessage: "Aide", classLevel: "6eme", history: [], tutorId: "kira" }),
    });
    expect(legacy.block).toBeUndefined();
    expect(legacy.text).not.toContain("ACTIVITY");
    expect(systems[1]).not.toContain("ACTIVITÉS INTERACTIVES");
  });

  it("tells the companion how the previous activity went, so it adapts", async () => {
    const prompts: string[] = [];
    await useCase((_, prompt) => {
      prompts.push(prompt);
      return "D'accord.";
    }).execute({
      userId: "s1",
      traceId: "t3",
      input: askTutorCallableInputSchema.parse({
        userMessage: "J'ai fini.",
        classLevel: "6eme",
        history: [],
        tutorId: "leo",
        activities: ["word_order"],
        activityOutcome: { blockId: "blk_1", type: "word_order", correct: true, attempts: 2, hintsUsed: 1 },
      }),
    });
    expect(prompts[0]).toContain("[Activité précédente (word_order) : réussie, 2 essai(s), 1 indice(s).");
  });
});
