import type { Firestore } from "firebase-admin/firestore";

import { db } from "../config/firebase";
import { AppError } from "../utils/errors";
import type {
  CheckTrainingQuizAnswerCallableInput,
  ListPublishedQuizzesCallableInput
} from "../utils/validation";
import { buildScoringQuizRecord } from "./quizAnswerKeys";
import { toPublicQuizPayload, type PublicQuizPayload } from "./quizPublicPayload";
import { scoreQuizAttempt } from "./quizScoring";
import type { QuizCorrection } from "./quizTypes";

export interface QuizContentStore {
  listPublished(input: ListPublishedQuizzesCallableInput): Promise<PublicQuizPayload[]>;
  getPublished(quizId: string): Promise<PublicQuizPayload>;
  checkTrainingAnswer(input: CheckTrainingQuizAnswerCallableInput): Promise<QuizCorrection>;
}

export class FirestoreQuizContentStore implements QuizContentStore {
  constructor(private readonly firestore: Firestore = db) {}

  async listPublished(
    input: ListPublishedQuizzesCallableInput
  ): Promise<PublicQuizPayload[]> {
    const snapshot = await this.firestore
      .collection("quizzes")
      .where("status", "==", "published")
      .where("classLevels", "array-contains-any", classLevelReadAliases(input.classLevel))
      .limit(40)
      .get();

    return snapshot.docs
      .filter((document) => isAllowedForSeries(document.data(), input.series))
      .map((document) => toPublicQuizPayload({
        id: document.id,
        data: document.data(),
        includeQuestions: false
      }));
  }

  async getPublished(quizId: string): Promise<PublicQuizPayload> {
    const snapshot = await this.firestore.collection("quizzes").doc(quizId).get();
    if (!snapshot.exists) {
      throw new AppError("not-found", "Quiz not found.");
    }

    return toPublicQuizPayload({
      id: snapshot.id,
      data: snapshot.data(),
      includeQuestions: true
    });
  }

  async checkTrainingAnswer(
    input: CheckTrainingQuizAnswerCallableInput
  ): Promise<QuizCorrection> {
    const quizRef = this.firestore.collection("quizzes").doc(input.quizId);
    const answerKeyRef = this.firestore.collection("quiz_answer_keys").doc(input.quizId);
    const [quizSnapshot, answerKeySnapshot] = await Promise.all([
      quizRef.get(),
      answerKeyRef.get()
    ]);
    if (!quizSnapshot.exists) {
      throw new AppError("not-found", "Quiz not found.");
    }

    const quiz = buildScoringQuizRecord({
      id: quizSnapshot.id,
      quizData: quizSnapshot.data(),
      answerKeyData: answerKeySnapshot.exists ? answerKeySnapshot.data() : undefined
    });
    if (quiz.status !== "published") {
      throw new AppError("not-found", "Quiz not found.");
    }
    if (quiz.mode !== "training") {
      throw new AppError(
        "failed-precondition",
        "Immediate answer checking is available only in training mode."
      );
    }

    const question = quiz.questions.find((item) => item.id === input.questionId);
    if (!question) {
      throw new AppError("invalid-argument", "Unknown quiz question.");
    }

    const result = scoreQuizAttempt({
      quiz: { ...quiz, questions: [question] },
      attemptId: "training-preview",
      answersByQuestion: { [question.id]: input.answer },
      submittedAt: new Date().toISOString()
    });
    return result.corrections[0];
  }
}

export function classLevelReadAliases(value: string): string[] {
  const normalized = value
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase();
  return normalized === "premiere" ? ["Premiere", "Première"] : [value];
}

function isAllowedForSeries(
  data: Record<string, unknown>,
  requestedSeries: string | null | undefined
): boolean {
  const allowedSeries = Array.isArray(data.series)
    ? data.series.filter((item): item is string => typeof item === "string")
    : [];
  return allowedSeries.length === 0 || (
    typeof requestedSeries === "string" && allowedSeries.includes(requestedSeries)
  );
}
