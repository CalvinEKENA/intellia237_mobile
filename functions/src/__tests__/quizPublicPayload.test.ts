import { describe, expect, it } from "vitest";

import { toPublicQuizPayload } from "../services/quizPublicPayload";
import { buildScoringQuizRecord } from "../services/quizAnswerKeys";

describe("student quiz payload", () => {
  const source = {
    title: "Équations du premier degré",
    subjectId: "math",
    subjectLabel: "Mathématiques",
    description: "Entraînement ciblé",
    difficultyLabel: "Intermédiaire",
    classLevels: ["3eme"],
    series: [],
    status: "published",
    mode: "training",
    questions: [
      {
        id: "q1",
        type: "qcm",
        prompt: "Résous 2x = 8",
        options: ["2", "4", "6"],
        correctOptionIndex: 1,
        acceptedAnswers: ["4"],
        correctBooleanValue: true,
        explanation: "On divise les deux membres par 2.",
        pointsReward: 10,
        internalNote: "Ne jamais exposer"
      }
    ],
    privateDraftComment: "corrigé validé"
  };

  it("returns lightweight metadata for the hub", () => {
    const payload = toPublicQuizPayload({
      id: "quiz-a",
      data: source,
      includeQuestions: false
    });

    expect(payload.questionCount).toBe(1);
    expect(payload.questions).toBeUndefined();
    expect(JSON.stringify(payload)).not.toContain("correctOptionIndex");
    expect(JSON.stringify(payload)).not.toContain("explanation");
    expect(JSON.stringify(payload)).not.toContain("privateDraftComment");
  });

  it("allow-lists question fields without leaking any answer key", () => {
    const payload = toPublicQuizPayload({
      id: "quiz-a",
      data: source,
      includeQuestions: true
    });

    expect(payload.questions).toEqual([
      {
        id: "q1",
        type: "qcm",
        prompt: "Résous 2x = 8",
        options: ["2", "4", "6"],
        pointsReward: 10
      }
    ]);
    const serialized = JSON.stringify(payload);
    expect(serialized).not.toContain("correctOptionIndex");
    expect(serialized).not.toContain("correctBooleanValue");
    expect(serialized).not.toContain("acceptedAnswers");
    expect(serialized).not.toContain("explanation");
    expect(serialized).not.toContain("internalNote");
  });

  it("refuses drafts instead of exposing them", () => {
    expect(() => toPublicQuizPayload({
      id: "quiz-draft",
      data: { ...source, status: "draft" },
      includeQuestions: true
    })).toThrowError("Quiz not found.");
  });

  it("reconstructs scoring data from the private answer-key document", () => {
    const publicDocument = {
      ...source,
      questions: [{
        id: "q1",
        type: "qcm",
        prompt: "Résous 2x = 8",
        options: ["2", "4", "6"],
        pointsReward: 10
      }]
    };
    const scoringQuiz = buildScoringQuizRecord({
      id: "quiz-a",
      quizData: publicDocument,
      answerKeyData: {
        answers: [{
          id: "q1",
          correctOptionIndex: 1,
          explanation: "On divise par 2.",
          pointsReward: 10
        }]
      }
    });

    expect(scoringQuiz.questions[0].correctOptionIndex).toBe(1);
    expect(scoringQuiz.questions[0].explanation).toBe("On divise par 2.");
  });

  it("rejects a public-only quiz whose private answer key is missing", () => {
    expect(() => buildScoringQuizRecord({
      id: "quiz-a",
      quizData: {
        ...source,
        questions: [{
          id: "q1",
          type: "qcm",
          prompt: "2 + 2",
          options: ["4", "5"],
          pointsReward: 10
        }]
      }
    })).toThrowError("Quiz answer key is incomplete");
  });
});
