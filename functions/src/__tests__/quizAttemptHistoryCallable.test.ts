import { describe, expect, it } from "vitest";

import {
  createListQuizAttemptHistoryHandler,
  type QuizAttemptHistoryStore,
} from "../services/quizAttemptHistoryCallable";

describe("quiz attempt history callable", () => {
  it("requires Firebase authentication", async () => {
    const store = new MemoryHistoryStore([]);

    await expect(
      createListQuizAttemptHistoryHandler(store)({ data: {} } as never),
    ).rejects.toMatchObject({ code: "unauthenticated" });
    expect(store.requestedStudentId).toBeNull();
  });

  it("uses request.auth and returns an allow-listed projection only", async () => {
    const store = new MemoryHistoryStore([
      {
        studentId: "student-a",
        quizId: "quiz-a",
        quizTitle: "Fonctions",
        subjectLabel: "Mathématiques",
        score: 7,
        maxScore: 10,
        pointsAwarded: 35,
        createdAt: new Date("2026-07-16T08:30:00.000Z"),
        mode: "training",
        answersByQuestion: { q1: "réponse privée" },
        corrections: [{ correctAnswer: "corrigé privé" }],
        requestHash: "secret-technique",
      },
    ]);

    const result = await createListQuizAttemptHistoryHandler(store)({
      auth: { uid: "student-a" },
      data: { studentId: "victim-id", limit: 999 },
    } as never);

    expect(store.requestedStudentId).toBe("student-a");
    expect(store.requestedLimit).toBe(20);
    expect(result.attempts).toEqual([
      {
        quizTitle: "Fonctions",
        subjectLabel: "Mathématiques",
        score: 7,
        maxScore: 10,
        pointsAwarded: 35,
        submittedAt: "2026-07-16T08:30:00.000Z",
        mode: "training",
      },
    ]);

    const serialized = JSON.stringify(result);
    expect(serialized).not.toContain("answersByQuestion");
    expect(serialized).not.toContain("corrections");
    expect(serialized).not.toContain("correctAnswer");
    expect(serialized).not.toContain("requestHash");
    expect(serialized).not.toContain("student-a");
    expect(serialized).not.toContain("victim-id");
  });

  it("caps output and maps unknown legacy modes to null", async () => {
    const store = new MemoryHistoryStore(
      Array.from({ length: 25 }, (_, index) => ({
        quizTitle: "Quiz $index",
        subjectLabel: "Matière",
        score: index,
        maxScore: 25,
        xpAwarded: 1,
        mode: "legacy-mode",
      })),
    );

    const result = await createListQuizAttemptHistoryHandler(store)({
      auth: { uid: "student-a" },
      data: null,
    } as never);

    expect(result.attempts).toHaveLength(20);
    expect(result.attempts[0]).toMatchObject({
      mode: null,
      pointsAwarded: 1,
      submittedAt: null,
    });
  });
});

class MemoryHistoryStore implements QuizAttemptHistoryStore {
  constructor(private readonly records: Record<string, unknown>[]) {}

  requestedStudentId: string | null = null;
  requestedLimit: number | null = null;

  async listRecent(studentId: string, limit: number) {
    this.requestedStudentId = studentId;
    this.requestedLimit = limit;
    return this.records;
  }
}
