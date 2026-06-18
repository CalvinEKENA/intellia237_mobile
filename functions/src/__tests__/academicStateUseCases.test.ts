import { HttpsError } from "firebase-functions/v2/https";
import { describe, expect, it } from "vitest";

import {
  type AcademicStateStore,
  type LessonProgressCommand,
  type LessonProgressResult,
  type SubmitQuizAttemptCommand
} from "../services/academicStateStore";
import { createSubmitQuizAttemptHandler } from "../services/academicCallables";
import { scoreQuizAttempt } from "../services/quizScoring";
import type { QuizRecord, QuizSubmissionResult } from "../services/quizTypes";
import { SubmitQuizAttemptUseCase } from "../services/submitQuizAttemptUseCase";
import { AppError } from "../utils/errors";

const submittedAt = "2026-06-18T12:00:00.000Z";

describe("submitQuizAttempt", () => {
  it("rejects unauthenticated callers", async () => {
    const handler = createSubmitQuizAttemptHandler(
      new SubmitQuizAttemptUseCase(new MemoryAcademicStateStore())
    );

    await expect(handler({
      data: validPayload()
    } as never)).rejects.toMatchObject({
      code: "unauthenticated"
    });
  });

  it("rejects malformed payloads", async () => {
    const handler = createSubmitQuizAttemptHandler(
      new SubmitQuizAttemptUseCase(new MemoryAcademicStateStore())
    );

    await expect(handler({
      auth: { uid: "student-a" },
      data: {
        ...validPayload(),
        clientAttemptId: "bad id with spaces"
      }
    } as never)).rejects.toMatchObject({
      code: "invalid-argument"
    });
  });

  it("returns not-found when the quiz does not exist", async () => {
    const handler = createSubmitQuizAttemptHandler(
      new SubmitQuizAttemptUseCase(new MemoryAcademicStateStore())
    );

    await expect(handler({
      auth: { uid: "student-a" },
      data: validPayload()
    } as never)).rejects.toMatchObject({
      code: "not-found"
    });
  });

  it("computes score, corrections, and XP from server quiz answers", async () => {
    const store = new MemoryAcademicStateStore([publishedQuiz()]);
    const handler = createSubmitQuizAttemptHandler(new SubmitQuizAttemptUseCase(store));

    const result = await handler({
      auth: { uid: "student-a" },
      data: validPayload({
        answersByQuestion: {
          q1: "0",
          q2: "wrong",
          q3: "true"
        }
      })
    } as never);

    expect(result.score).toBe(2);
    expect(result.maxScore).toBe(3);
    expect(result.xpAwarded).toBe(12);
    expect(result.corrections.map((item) => item.isCorrect)).toEqual([true, false, true]);
    expect(result.submittedAt).toBe(submittedAt);
    expect(result.submittedAt).not.toBe("2020-01-01T00:00:00.000Z");
  });

  it("rejects client-supplied XP instead of trusting it", async () => {
    const store = new MemoryAcademicStateStore([publishedQuiz()]);
    const handler = createSubmitQuizAttemptHandler(new SubmitQuizAttemptUseCase(store));

    await expect(handler({
      auth: { uid: "student-a" },
      data: {
        ...validPayload(),
        xpAwarded: 999999
      }
    } as never)).rejects.toMatchObject({
      code: "invalid-argument"
    });
  });

  it("rejects answers for foreign question ids", async () => {
    const store = new MemoryAcademicStateStore([publishedQuiz()]);
    const handler = createSubmitQuizAttemptHandler(new SubmitQuizAttemptUseCase(store));

    await expect(handler({
      auth: { uid: "student-a" },
      data: validPayload({
        answersByQuestion: {
          q1: "0",
          foreign: "0"
        }
      })
    } as never)).rejects.toMatchObject({
      code: "invalid-argument"
    });
  });

  it("replays identical client attempt ids idempotently", async () => {
    const store = new MemoryAcademicStateStore([publishedQuiz()]);
    const useCase = new SubmitQuizAttemptUseCase(store);

    const first = await useCase.execute({
      studentId: "student-a",
      input: validPayload()
    });
    const second = await useCase.execute({
      studentId: "student-a",
      input: validPayload()
    });

    expect(first.idempotentReplay).toBe(false);
    expect(second.idempotentReplay).toBe(true);
    expect(second.score).toBe(first.score);
    expect(second.xpAwarded).toBe(first.xpAwarded);
  });

  it("rejects reused client attempt ids with different payloads", async () => {
    const store = new MemoryAcademicStateStore([publishedQuiz()]);
    const useCase = new SubmitQuizAttemptUseCase(store);

    await useCase.execute({
      studentId: "student-a",
      input: validPayload()
    });

    await expect(useCase.execute({
      studentId: "student-a",
      input: validPayload({
        answersByQuestion: {
          q1: "1",
          q2: "wrong",
          q3: "false"
        }
      })
    })).rejects.toMatchObject({
      code: "already-exists"
    });
  });

  it("maps transaction failures to internal without leaking the raw message", async () => {
    const handler = createSubmitQuizAttemptHandler(
      new SubmitQuizAttemptUseCase(new MemoryAcademicStateStore([publishedQuiz()], true))
    );

    await expect(handler({
      auth: { uid: "student-a" },
      data: validPayload()
    } as never)).rejects.toMatchObject({
      code: "internal",
      message: "Internal server error."
    });
  });
});

describe("recordLessonProgress", () => {
  it("records monotonic progress and replays idempotently", async () => {
    const store = new MemoryAcademicStateStore([publishedQuiz()]);
    const first = await store.recordLessonProgress({
      studentId: "student-a",
      classLevel: "Terminale",
      subjectId: "math",
      chapterId: "algebra",
      lessonId: "linear-equations",
      progress: 0.7,
      clientEventId: "event_0001",
      requestHash: "hash-a"
    });
    const lower = await store.recordLessonProgress({
      studentId: "student-a",
      classLevel: "Terminale",
      subjectId: "math",
      chapterId: "algebra",
      lessonId: "linear-equations",
      progress: 0.2,
      clientEventId: "event_0002",
      requestHash: "hash-b"
    });
    const replay = await store.recordLessonProgress({
      studentId: "student-a",
      classLevel: "Terminale",
      subjectId: "math",
      chapterId: "algebra",
      lessonId: "linear-equations",
      progress: 0.7,
      clientEventId: "event_0001",
      requestHash: "hash-a"
    });

    expect(first.progress).toBe(0.7);
    expect(lower.progress).toBe(0.7);
    expect(replay.idempotentReplay).toBe(true);
  });
});

function validPayload(overrides: Partial<{
  answersByQuestion: Record<string, string>;
}> = {}) {
  return {
    quizId: "quiz-a",
    clientAttemptId: "attempt_0001",
    answersByQuestion: overrides.answersByQuestion ?? {
      q1: "0",
      q2: "Paris",
      q3: "true"
    },
    startedAt: "2020-01-01T00:00:00.000Z",
    durationSeconds: 42
  };
}

function publishedQuiz(): QuizRecord {
  return {
    id: "quiz-a",
    title: "Server scored quiz",
    subjectId: "math",
    subjectLabel: "Mathematiques",
    status: "published",
    questions: [
      {
        id: "q1",
        type: "qcm",
        prompt: "2 + 2",
        options: ["4", "5"],
        correctOptionIndex: 0,
        acceptedAnswers: [],
        explanation: "2 + 2 = 4.",
        xpReward: 5
      },
      {
        id: "q2",
        type: "shortAnswer",
        prompt: "Capital of Cameroon",
        options: [],
        acceptedAnswers: ["Yaounde", "Yaoundé"],
        explanation: "The capital is Yaounde.",
        xpReward: 9
      },
      {
        id: "q3",
        type: "trueFalse",
        prompt: "The sky is blue.",
        options: [],
        correctBooleanValue: true,
        acceptedAnswers: [],
        explanation: "Often true in daylight.",
        xpReward: 7
      }
    ]
  };
}

class MemoryAcademicStateStore implements AcademicStateStore {
  private readonly quizzes = new Map<string, QuizRecord>();
  private readonly attempts = new Map<string, { requestHash: string; result: QuizSubmissionResult }>();
  private readonly progress = new Map<string, number>();
  private readonly progressEvents = new Map<string, { requestHash: string; result: LessonProgressResult }>();

  constructor(quizzes: QuizRecord[] = [], private readonly failSubmit = false) {
    for (const quiz of quizzes) {
      this.quizzes.set(quiz.id, quiz);
    }
  }

  async submitQuizAttempt(command: SubmitQuizAttemptCommand): Promise<QuizSubmissionResult> {
    if (this.failSubmit) {
      throw new Error("secret-token-123 transaction failure");
    }

    const attemptId = `${command.studentId}_${command.clientAttemptId}`;
    const existing = this.attempts.get(attemptId);
    if (existing) {
      if (existing.requestHash !== command.requestHash) {
        throw new AppError("already-exists", "Client attempt id was already used with a different payload.");
      }
      return {
        ...existing.result,
        idempotentReplay: true
      };
    }

    const quiz = this.quizzes.get(command.quizId);
    if (!quiz) {
      throw new AppError("not-found", "Quiz not found.");
    }
    if (quiz.status !== "published") {
      throw new AppError("failed-precondition", "Only published quizzes can be submitted.");
    }

    try {
      const result = scoreQuizAttempt({
        quiz,
        attemptId,
        answersByQuestion: command.answersByQuestion,
        submittedAt
      });
      this.attempts.set(attemptId, {
        requestHash: command.requestHash,
        result
      });
      return result;
    } catch (error) {
      throw new AppError(
        "invalid-argument",
        error instanceof Error ? error.message : "Invalid quiz answers."
      );
    }
  }

  async recordLessonProgress(command: LessonProgressCommand): Promise<LessonProgressResult> {
    const eventKey = `${command.studentId}_${command.clientEventId}`;
    const existingEvent = this.progressEvents.get(eventKey);
    if (existingEvent) {
      if (existingEvent.requestHash !== command.requestHash) {
        throw new HttpsError("already-exists", "Client event id was already used with a different payload.");
      }
      return {
        ...existingEvent.result,
        idempotentReplay: true
      };
    }

    const progressId = `${command.subjectId}_${command.chapterId}_${command.lessonId}`;
    const previousProgress = this.progress.get(progressId) ?? 0;
    const nextProgress = Math.max(previousProgress, command.progress);
    this.progress.set(progressId, nextProgress);
    const result = {
      progressId,
      progress: nextProgress,
      previousProgress,
      isCompleted: nextProgress >= 1,
      updatedAt: submittedAt,
      idempotentReplay: false
    };
    this.progressEvents.set(eventKey, {
      requestHash: command.requestHash,
      result
    });
    return result;
  }
}
