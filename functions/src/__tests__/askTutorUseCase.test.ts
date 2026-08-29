import { describe, expect, it } from "vitest";

import {
  AskTutorUseCase,
  lessonBelongsToTutorScope,
  resolveTutorAcademicScope,
  type AuthorizedTutorContext,
  type TutorContextStore,
} from "../services/askTutorUseCase";
import type { AskTutorCallableInput } from "../utils/validation";

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
    const useCase = new AskTutorUseCase(
      new FixedContextStore({
        scope: { classLevel: "Terminale", establishmentId: "school-a" },
        text: "CONTENU_AUTORISE_SCHOOL_A",
      }),
      async ({ prompt }) => {
        prompts.push(prompt);
        return "Réponse sûre";
      },
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
  });
});

class FixedContextStore implements TutorContextStore {
  constructor(private readonly context: AuthorizedTutorContext) {}

  async loadAuthorizedContext(): Promise<AuthorizedTutorContext> {
    return this.context;
  }
}

function validInput(): AskTutorCallableInput {
  return {
    classLevel: "Terminale",
    userMessage: "Explique-moi cette notion.",
    history: [],
    tutor: {
      name: "Nova",
      specialty: "Sciences",
      personality: "Bienveillante",
      motto: "On avance ensemble.",
    },
  };
}
