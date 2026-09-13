import type { Firestore } from "firebase-admin/firestore";

import { db } from "../config/firebase";
import { audienceAllows } from "./contentAudience";
import { publishedLessonAllows } from "./educationalMedia";
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
  listPublished(input: ListPublishedQuizzesCallableInput, userId?: string): Promise<PublicQuizPayload[]>;
  getPublished(quizId: string, userId?: string): Promise<PublicQuizPayload>;
  checkTrainingAnswer(input: CheckTrainingQuizAnswerCallableInput, userId?: string): Promise<QuizCorrection>;
}

export class FirestoreQuizContentStore implements QuizContentStore {
  constructor(private readonly firestore: Firestore = db) {}

  async listPublished(
    input: ListPublishedQuizzesCallableInput, userId?: string
  ): Promise<PublicQuizPayload[]> {
    const snapshot = await this.firestore
      .collection("quizzes")
      .where("status", "==", "published")
      // Without an order, a cap of 40 let older seeded quizzes crowd a new one
      // out of the list. The listing carries no questions: 100 stays light.
      .limit(100)
      .get();

    const documents = [];
    for (const document of snapshot.docs) {
      if (!await this.authorized(document.data(), userId)) continue;
      if (!userId && !isAllowedForSeries(document.data(), input.series)) continue;
      documents.push(toPublicQuizPayload({ id: document.id, data: document.data(), includeQuestions: false }));
    }
    return documents;
  }

  private async authorized(data: Record<string, unknown>, userId?: string): Promise<boolean> {
    if (data.status !== "published") return false;
    if (!userId) return true;
    const [user, profile] = await Promise.all([this.firestore.doc(`users/${userId}`).get(), this.firestore.doc(`student_profiles/${userId}`).get()]);
    const actor = user.data() || {}, academic = profile.data() || {};
    return quizAudienceAllows(data, actor, academic) && (!data.sourceLessonPath ||
      await publishedLessonAllows(this.firestore, String(data.sourceLessonPath), actor, academic));
  }

  async getPublished(quizId: string, userId?: string): Promise<PublicQuizPayload> {
    const snapshot = await this.firestore.collection("quizzes").doc(quizId).get();
    if (!snapshot.exists) {
      throw new AppError("not-found", "Quiz not found.");
    }
    if (!await this.authorized(snapshot.data()!, userId)) {
      throw new AppError("not-found", "Quiz not found.");
    }

    return toPublicQuizPayload({
      id: snapshot.id,
      data: snapshot.data(),
      includeQuestions: true
    });
  }

  async checkTrainingAnswer(
    input: CheckTrainingQuizAnswerCallableInput, userId?: string
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
    if (!await this.authorized(quizSnapshot.data()!, userId)) {
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

export function quizAudienceAllows(data: Record<string, unknown>, user?: Record<string, unknown>, profile: Record<string, unknown> = {}): boolean {
  if (!user) return true; // Trusted internal calls only; public callables always supply authentication.
  return audienceAllows(data, user, profile);
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
