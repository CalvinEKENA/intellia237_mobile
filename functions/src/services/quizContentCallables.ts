import { randomUUID } from "node:crypto";

import { logger } from "firebase-functions";
import { HttpsError, type CallableRequest } from "firebase-functions/v2/https";

import { toHttpsError } from "../utils/errors";
import {
  checkTrainingQuizAnswerCallableInputSchema,
  getPublishedQuizCallableInputSchema,
  listPublishedQuizzesCallableInputSchema
} from "../utils/validation";
import {
  FirestoreQuizContentStore,
  type QuizContentStore
} from "./quizContentStore";

export function createListPublishedQuizzesHandler(
  store: QuizContentStore = new FirestoreQuizContentStore()
) {
  return async (request: CallableRequest) => {
    requireAuthentication(request);
    const traceId = randomUUID();
    try {
      const input = listPublishedQuizzesCallableInputSchema.parse(request.data);
      const quizzes = await store.listPublished(input, request.auth!.uid);
      return { traceId, quizzes };
    } catch (error) {
      logFailure("listPublishedQuizzes", traceId, error);
      throw toHttpsError(error);
    }
  };
}

export function createGetPublishedQuizHandler(
  store: QuizContentStore = new FirestoreQuizContentStore()
) {
  return async (request: CallableRequest) => {
    requireAuthentication(request);
    const traceId = randomUUID();
    try {
      const input = getPublishedQuizCallableInputSchema.parse(request.data);
      const quiz = await store.getPublished(input.quizId, request.auth!.uid);
      return { traceId, quiz };
    } catch (error) {
      logFailure("getPublishedQuiz", traceId, error);
      throw toHttpsError(error);
    }
  };
}

export function createCheckTrainingQuizAnswerHandler(
  store: QuizContentStore = new FirestoreQuizContentStore()
) {
  return async (request: CallableRequest) => {
    requireAuthentication(request);
    const traceId = randomUUID();
    try {
      const input = checkTrainingQuizAnswerCallableInputSchema.parse(request.data);
      const correction = await store.checkTrainingAnswer(input, request.auth!.uid);
      // Do not log the answer or correction: both are academic content.
      logger.info("checkTrainingQuizAnswer completed.", {
        traceId,
        quizId: input.quizId,
        questionId: input.questionId,
        isCorrect: correction.isCorrect
      });
      return { traceId, correction };
    } catch (error) {
      logFailure("checkTrainingQuizAnswer", traceId, error);
      throw toHttpsError(error);
    }
  };
}

function requireAuthentication(request: CallableRequest): void {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Firebase Auth is required.");
  }
}

function logFailure(operation: string, traceId: string, error: unknown): void {
  logger.error(`${operation} failed.`, {
    traceId,
    errorCategory: error instanceof Error ? error.name : "unknown"
  });
}

export const listPublishedQuizzesHandler = createListPublishedQuizzesHandler();
export const getPublishedQuizHandler = createGetPublishedQuizHandler();
export const checkTrainingQuizAnswerHandler = createCheckTrainingQuizAnswerHandler();
