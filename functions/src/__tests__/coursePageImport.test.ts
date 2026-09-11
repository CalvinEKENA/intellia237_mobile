import { describe, expect, it } from "vitest";

import type { InlineAttachment } from "../llm/llmClient";
import {
  authorizeCoursePageImport,
  buildCoursePageImportPrompt,
  coursePageDraftSchema,
  createImportCoursePagesHandler,
  pageUnits,
  sanitizeCoursePageDraft,
  type CoursePageDraft,
  type PageImportQuotaStore,
} from "../services/coursePageImport";
import { AppError } from "../utils/errors";
import { coursePageImportInputSchema } from "../utils/validation";

const input = {
  classLevel: "Terminale",
  subjectLabel: "Mathématiques",
  chapterTitle: "Dérivées",
  storagePaths: [
    "educational_assets/global/Terminale/maths/import-1/page-1/page-01.jpg",
    "educational_assets/global/Terminale/maths/import-1/page-2/page-02.jpg",
  ],
  rightsConfirmed: true,
};

const draft: CoursePageDraft = coursePageDraftSchema.parse({
  lesson: {
    title: "Dérivée d'une fonction",
    summary: "La dérivée mesure la variation instantanée.",
    estimatedMinutes: 20,
    sections: [{ title: "Définition", body: "f′(a) est la limite du taux d'accroissement." }],
  },
  quizQuestions: [
    { prompt: "Dérivée de x² ?", options: ["2x", "x", "2"], correctOptionIndex: 0, explanation: "On abaisse l'exposant." },
    { prompt: "Question cassée", options: ["a", "b"], correctOptionIndex: 5 },
  ],
  exercises: [{ statement: "Dériver f(x) = 3x² + 2x.", solution: "f′(x) = 6x + 2." }],
  flowCards: [
    { type: "notion", title: "Tangente", insight: "La dérivée est la pente de la tangente." },
    { type: "quiz", title: "Mini-quiz", question: "Dérivée d'une constante ?", options: ["0", "1"], correctIndex: 0 },
    { type: "quiz", title: "Cassé", question: "?", options: ["a", "b"], correctIndex: 3 },
  ],
});

describe("importCoursePages", () => {
  it("accepts only confirmed rights and pages of the educational assets tree", () => {
    expect(coursePageImportInputSchema.safeParse(input).success).toBe(true);
    expect(coursePageImportInputSchema.safeParse({ ...input, rightsConfirmed: false }).success)
      .toBe(false);
    for (const storagePaths of [
      ["users/root/page.jpg"],
      ["educational_assets/global/../secrets/page.jpg"],
      Array.from({ length: 13 }, (_, i) => `educational_assets/global/p/${i}.jpg`),
    ]) {
      expect(coursePageImportInputSchema.safeParse({ ...input, storagePaths }).success)
        .toBe(false);
    }
  });

  it("opens every scope to the general administration and its own school to staff", () => {
    expect(authorizeCoursePageImport({
      userData: { role: "superAdmin" },
      storagePaths: ["educational_assets/lycee-b/Terminale/p/1.jpg"],
    }).dailyPageLimit).toBe(150);

    expect(authorizeCoursePageImport({
      userData: { role: "teacher", establishmentId: "lycee-a", accountStatus: "active" },
      storagePaths: ["educational_assets/lycee-a/Terminale/p/1.jpg"],
    }).dailyPageLimit).toBe(40);

    for (const [userData, path] of [
      [{ role: "teacher", establishmentId: "lycee-a" }, "educational_assets/global/Terminale/p/1.jpg"],
      [{ role: "admin", establishmentId: "lycee-a" }, "educational_assets/lycee-b/Terminale/p/1.jpg"],
      [{ role: "teacher" }, "educational_assets/global/Terminale/p/1.jpg"],
      [{ role: "student", establishmentId: "lycee-a" }, "educational_assets/lycee-a/Terminale/p/1.jpg"],
      [{ role: "teacher", establishmentId: "lycee-a", accountStatus: "pending_validation" }, "educational_assets/lycee-a/Terminale/p/1.jpg"],
    ] as const) {
      expect(() => authorizeCoursePageImport({ userData, storagePaths: [path] }))
        .toThrowError(expect.objectContaining({ code: "permission-denied" }));
    }
  });

  it("counts what the model reads: one unit per image, per scanned PDF page", () => {
    const image: InlineAttachment = { mimeType: "image/jpeg", data: "a".repeat(4000) };
    const pdf: InlineAttachment = {
      mimeType: "application/pdf",
      data: "a".repeat(Math.ceil((1_200_000 * 4) / 3)),
    };
    expect(pageUnits([image, image])).toBe(2);
    expect(pageUnits([pdf])).toBe(3);
  });

  it("discards QCM and mini-quiz whose correct answer does not exist", () => {
    const clean = sanitizeCoursePageDraft(draft);
    expect(clean.quizQuestions).toHaveLength(1);
    expect(clean.flowCards).toHaveLength(2);
    expect(clean.warnings).toHaveLength(2);
  });

  it("names the class, the subject and the language in the prompt", () => {
    const prompt = buildCoursePageImportPrompt(
      coursePageImportInputSchema.parse({ ...input, language: "en" }),
      2,
    );
    expect(prompt).toContain("Classe : Terminale");
    expect(prompt).toContain("Matière : Mathématiques");
    expect(prompt).toContain("Langue des contenus : anglais");
  });

  it("reads the pages, charges the quota and returns sanitized drafts", async () => {
    const quota = new MemoryQuota();
    const handler = createImportCoursePagesHandler({
      readUser: async () => ({ role: "superAdmin" }),
      source: { load: async (paths) => paths.map(() => ({ mimeType: "image/jpeg", data: "abcd" })) },
      quota,
      extractor: { extract: async (params) => {
        expect(params.attachments).toHaveLength(2);
        return draft;
      } },
    });

    const result = await handler({ auth: { uid: "root-a", token: {} }, data: input } as never);

    expect(result.lesson.title).toBe("Dérivée d'une fonction");
    expect(result.quizQuestions).toHaveLength(1);
    expect(quota.reserved).toEqual([["root-a", 2, 150]]);
    expect(quota.released).toEqual([]);
  });

  it("gives the quota back when the reading fails", async () => {
    const quota = new MemoryQuota();
    const handler = createImportCoursePagesHandler({
      readUser: async () => ({ role: "superAdmin" }),
      source: { load: async () => [{ mimeType: "image/png", data: "abcd" }] },
      quota,
      extractor: { extract: async () => {
        throw new AppError("unavailable", "Vertex AI is unavailable.");
      } },
    });

    await expect(handler({ auth: { uid: "root-a", token: {} }, data: input } as never))
      .rejects.toMatchObject({ code: "unavailable" });
    expect(quota.released).toEqual([["root-a", 1]]);
  });

  it("rejects unauthenticated callers before reading anything", async () => {
    const handler = createImportCoursePagesHandler({
      readUser: async () => {
        throw new Error("must not be read");
      },
    });

    await expect(handler({ data: input } as never))
      .rejects.toMatchObject({ code: "unauthenticated" });
  });
});

class MemoryQuota implements PageImportQuotaStore {
  reserved: Array<[string, number, number]> = [];
  released: Array<[string, number]> = [];

  async reserve(userId: string, units: number, limit: number): Promise<void> {
    this.reserved.push([userId, units, limit]);
  }

  async release(userId: string, units: number): Promise<void> {
    this.released.push([userId, units]);
  }
}
