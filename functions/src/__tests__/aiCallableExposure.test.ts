import { readFileSync } from "node:fs";
import { join } from "node:path";
import { describe, expect, it } from "vitest";

/**
 * Aucune callable qui atteint Gemini ne doit être ouverte à tout compte
 * connecté sans rôle ni quota. Ce contrat lit la source des exports.
 */
const source = readFileSync(join(__dirname, "..", "index.ts"), "utf8");
const exported = [...source.matchAll(/^export const (\w+)\s*=/gm)].map((match) => match[1]);

/** Callables IA autorisées, chacune avec sa garde. */
const guardedAiCallables: Record<string, string> = {
  askTutor: "student profile + daily quota + Study Reserve",
  importCoursePages: "staff role + daily page quota",
};

describe("AI callable exposure", () => {
  it("no longer exposes the unguarded quiz and summary generators", () => {
    expect(exported).not.toContain("generateQuiz");
    expect(exported).not.toContain("generateSummary");
  });

  it("never reintroduces legacy unguarded AI endpoints", () => {
    for (const legacy of ["generateExercises", "gradeAnswer", "chatWithDavid"]) {
      expect(exported).not.toContain(legacy);
    }
  });

  it("keeps each remaining AI callable behind a documented guard", () => {
    for (const name of Object.keys(guardedAiCallables)) {
      expect(exported).toContain(name);
    }
  });
});
