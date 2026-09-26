import { describe, expect, it } from "vitest";

import { ACTIVITY_CLOSE, ACTIVITY_OPEN } from "../llm/interactiveBlocks";
import {
  AskTutorUseCase,
  MAX_TOKENS_FINISH_REASON,
  type TutorContextStore,
} from "../services/askTutorUseCase";
import { StudyReserveConsumption } from "../services/studyReserveConsumption";
import type { TutorQuotaSnapshot, TutorQuotaStore } from "../services/tutorDailyQuota";
import { askTutorCallableInputSchema } from "../utils/validation";
import { CurrentCycleProvisioning } from "./support/currentCycleProvisioning";

/**
 * Compatibilité OLD APP + NEW BACKEND.
 *
 * Charges utiles EXACTES de l'application installée (7521a94, 3.0.0+22 ;
 * identiques sur 5e4f797) : `userMessage`, `classLevel`, `history` (≤ 20
 * éléments de ≤ 4 000 caractères), `tutor { name, specialty, personality,
 * motto }` avec les textes réels de Kira et Léo. Pas de `tutorId`, pas de
 * `requestId`, pas d'`activities`.
 *
 * Réponse lue par cette version : `text` (chaîne non vide), `limit` et
 * `remaining` (nombres) ; tout autre champ est ignoré.
 */
const LEGACY_KIRA = {
  name: "Kira",
  specialty: "Méthodologie & Accompagnement",
  personality: "Patiente & Explicative",
  motto: "\"Apprenons avec calme et sérénité.\"",
};
const LEGACY_LEO = {
  name: "Léo",
  specialty: "Défis & Performance",
  personality: "Dynamique & Challengeur",
  motto: "\"Dépasse tes limites et bats tes records !\"",
};

function legacyPayload(tutor: Record<string, string>, historySize = 2) {
  return {
    userMessage: "Explique-moi les fractions",
    classLevel: "6eme",
    history: Array.from({ length: historySize }, (_, index) => ({
      role: index % 2 === 0 ? "user" : "assistant",
      text: "x".repeat(historySize === 20 ? 4000 : 20),
    })),
    tutor,
  };
}

class Quota implements TutorQuotaStore {
  async reserve(params: { limit: number }) {
    return this.snapshot(params.limit);
  }
  async consume(params: { limit: number }): Promise<TutorQuotaSnapshot> {
    return this.snapshot(params.limit);
  }
  async release(): Promise<void> {}
  private snapshot(limit: number): TutorQuotaSnapshot {
    return { limit, remaining: limit - 1, resetsAt: "2026-09-22T23:00:00.000Z" };
  }
}

const context: TutorContextStore = {
  loadAuthorizedContext: async () => ({
    scope: { classLevel: "6eme", establishmentId: null },
    text: "",
    language: "fr",
  }),
};

function useCase(generator: ConstructorParameters<typeof AskTutorUseCase>[1]) {
  return new AskTutorUseCase(
    context,
    generator,
    new Quota(),
    20,
    // Aucune Réserve configurée : seul le contrat de réponse est observé ici.
    new StudyReserveConsumption(undefined, { emit: async () => undefined }, new CurrentCycleProvisioning(async () => null)),
  );
}

/** Ce que la version installée exige de la réponse. */
function expectReadableByLegacyApp(answer: object) {
  const response = answer as Record<string, unknown>;
  expect(typeof response.text).toBe("string");
  expect((response.text as string).trim().length).toBeGreaterThan(0);
  expect(typeof response.limit).toBe("number");
  expect(typeof response.remaining).toBe("number");
  expect(response.text as string).not.toContain(ACTIVITY_OPEN);
  expect(response.text as string).not.toContain(ACTIVITY_CLOSE);
}

describe("askTutor keeps the installed app working", () => {
  it("accepts the exact Kira and Léo payloads of the installed app", () => {
    const kira = askTutorCallableInputSchema.parse(legacyPayload(LEGACY_KIRA));
    const leo = askTutorCallableInputSchema.parse(legacyPayload(LEGACY_LEO));
    expect(kira.tutorId).toBe("kira");
    expect(leo.tutorId).toBe("leo");
    expect(kira.requestId).toBeUndefined();
    expect(kira.activities).toBeUndefined();
  });

  it("accepts the largest history the installed app can send", () => {
    const parsed = askTutorCallableInputSchema.parse(legacyPayload(LEGACY_KIRA, 20));
    expect(parsed.history).toHaveLength(20);
  });

  it("still maps the historical companion names", () => {
    for (const [name, id] of [["Ethan", "leo"], ["Grâce", "kira"], ["Nathan", "leo"], ["Marianne", "kira"]] as const) {
      const parsed = askTutorCallableInputSchema.parse(legacyPayload({ ...LEGACY_KIRA, name }));
      expect(parsed.tutorId, name).toBe(id);
    }
  });

  it("never sends an activity block to an app that did not ask for one", async () => {
    const input = askTutorCallableInputSchema.parse(legacyPayload(LEGACY_KIRA));
    const answer = await useCase(async ({ onFinishReason }) => {
      onFinishReason?.("STOP");
      return `Voici.\n${ACTIVITY_OPEN}\n{"type":"word_order","sequence":["a","b"]}\n${ACTIVITY_CLOSE}`;
    }).execute({ userId: "s1", traceId: "legacy-1", input });
    expectReadableByLegacyApp(answer);
    expect(answer.block).toBeUndefined();
    expect(answer.text).toBe("Voici.");
  });

  it("a truncated answer is still a readable answer for the installed app", async () => {
    const input = askTutorCallableInputSchema.parse(legacyPayload(LEGACY_LEO));
    const answer = await useCase(async ({ onFinishReason }) => {
      onFinishReason?.(MAX_TOKENS_FINISH_REASON);
      return "Une réponse coupée au milieu";
    }).execute({ userId: "s1", traceId: "legacy-2", input });
    expectReadableByLegacyApp(answer);
    expect(answer.text).toContain("la suite");
  });

  it("an undelivered answer fails with a code the installed app already maps", async () => {
    const input = askTutorCallableInputSchema.parse(legacyPayload(LEGACY_KIRA));
    await expect(useCase(async () => "   ").execute({ userId: "s1", traceId: "legacy-3", input }))
      .rejects.toMatchObject({ code: "unavailable" });
  });
});
