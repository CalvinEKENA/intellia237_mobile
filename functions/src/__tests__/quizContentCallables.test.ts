import { describe, expect, it } from "vitest";

import {
  createCheckTrainingQuizAnswerHandler,
  createGetPublishedQuizHandler,
  createListPublishedQuizzesHandler
} from "../services/quizContentCallables";
import type { QuizContentStore } from "../services/quizContentStore";
import type { PublicQuizPayload } from "../services/quizPublicPayload";

const publicQuiz: PublicQuizPayload = {
  id: "quiz-a",
  title: "Quiz sécurisé",
  subjectId: "math",
  subjectLabel: "Mathématiques",
  description: "",
  difficultyLabel: "Intermédiaire",
  classLevels: ["3eme"],
  series: [],
  timerSeconds: null,
  mode: "training",
  questionCount: 1,
  questions: [{
    id: "q1",
    type: "qcm",
    prompt: "2 + 2",
    options: ["4", "5"],
    pointsReward: 10
  }]
};

describe("quiz content callables", () => {
  it("requires authentication for every student content endpoint", async () => {
    const store = new MemoryQuizContentStore();
    await expect(createListPublishedQuizzesHandler(store)({
      data: { classLevel: "3eme", series: null }
    } as never)).rejects.toMatchObject({ code: "unauthenticated" });
    await expect(createGetPublishedQuizHandler(store)({
      data: { quizId: "quiz-a" }
    } as never)).rejects.toMatchObject({ code: "unauthenticated" });
    await expect(createCheckTrainingQuizAnswerHandler(store)({
      data: { quizId: "quiz-a", questionId: "q1", answer: "0" }
    } as never)).rejects.toMatchObject({ code: "unauthenticated" });
  });

  it("returns hub metadata without question payload", async () => {
    const store = new MemoryQuizContentStore();
    const result = await createListPublishedQuizzesHandler(store)({
      auth: { uid: "student-a" },
      data: { classLevel: "3eme", series: null }
    } as never);

    expect(result.quizzes).toHaveLength(1);
    expect(result.quizzes[0].questionCount).toBe(1);
    expect(result.quizzes[0].questions).toBeUndefined();
  });

  it("returns a public quiz without answer fields", async () => {
    const store = new MemoryQuizContentStore();
    const result = await createGetPublishedQuizHandler(store)({
      auth: { uid: "student-a" },
      data: { quizId: "quiz-a" }
    } as never);

    const serialized = JSON.stringify(result.quiz);
    expect(serialized).not.toContain("correctOptionIndex");
    expect(serialized).not.toContain("acceptedAnswers");
    expect(serialized).not.toContain("explanation");
  });

  it("checks a training answer without submitting or awarding points", async () => {
    const store = new MemoryQuizContentStore();
    const result = await createCheckTrainingQuizAnswerHandler(store)({
      auth: { uid: "student-a" },
      data: { quizId: "quiz-a", questionId: "q1", answer: "0" }
    } as never);

    expect(result.correction).toMatchObject({
      questionId: "q1",
      isCorrect: true,
      correctAnswer: "4"
    });
    expect(store.checkCount).toBe(1);
  });
});

class MemoryQuizContentStore implements QuizContentStore {
  checkCount = 0;

  async listPublished(): Promise<PublicQuizPayload[]> {
    const { questions: _, ...summary } = publicQuiz;
    return [summary];
  }

  async getPublished(): Promise<PublicQuizPayload> {
    return publicQuiz;
  }

  async checkTrainingAnswer() {
    this.checkCount += 1;
    return {
      questionId: "q1",
      prompt: "2 + 2",
      userAnswer: "4",
      correctAnswer: "4",
      explanation: "2 + 2 = 4.",
      isCorrect: true,
      pointsReward: 10
    };
  }
}
