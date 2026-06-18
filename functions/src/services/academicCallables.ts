import { randomUUID } from "node:crypto";

import { logger } from "firebase-functions";
import { HttpsError, type CallableRequest } from "firebase-functions/v2/https";

import { RecordLessonProgressUseCase } from "./recordLessonProgressUseCase";
import { SubmitQuizAttemptUseCase } from "./submitQuizAttemptUseCase";
import { toHttpsError } from "../utils/errors";
import {
  recordLessonProgressCallableInputSchema,
  submitQuizAttemptCallableInputSchema
} from "../utils/validation";

export function createSubmitQuizAttemptHandler(
  useCase = new SubmitQuizAttemptUseCase()
) {
  return async (request: CallableRequest) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Firebase Auth is required.");
    }

    const traceId = randomUUID();
    const startedAt = Date.now();

    try {
      const input = submitQuizAttemptCallableInputSchema.parse(request.data);
      const result = await useCase.execute({
        studentId: request.auth.uid,
        input
      });

      logger.info("submitQuizAttempt completed.", {
        traceId,
        quizId: input.quizId,
        score: result.score,
        xpAwarded: result.xpAwarded,
        idempotentReplay: result.idempotentReplay,
        durationMs: Date.now() - startedAt
      });

      return {
        traceId,
        ...result
      };
    } catch (error) {
      logger.error("submitQuizAttempt failed.", {
        traceId,
        errorCategory: error instanceof HttpsError
          ? error.code
          : error instanceof Error
            ? error.name
            : "unknown"
      });
      throw toHttpsError(error);
    }
  };
}

export function createRecordLessonProgressHandler(
  useCase = new RecordLessonProgressUseCase()
) {
  return async (request: CallableRequest) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Firebase Auth is required.");
    }

    const traceId = randomUUID();
    const startedAt = Date.now();

    try {
      const input = recordLessonProgressCallableInputSchema.parse(request.data);
      const result = await useCase.execute({
        studentId: request.auth.uid,
        input
      });

      logger.info("recordLessonProgress completed.", {
        traceId,
        subjectId: input.subjectId,
        chapterId: input.chapterId,
        lessonId: input.lessonId,
        progress: result.progress,
        idempotentReplay: result.idempotentReplay,
        durationMs: Date.now() - startedAt
      });

      return {
        traceId,
        ...result
      };
    } catch (error) {
      logger.error("recordLessonProgress failed.", {
        traceId,
        errorCategory: error instanceof HttpsError
          ? error.code
          : error instanceof Error
            ? error.name
            : "unknown"
      });
      throw toHttpsError(error);
    }
  };
}

export const submitQuizAttemptHandler = createSubmitQuizAttemptHandler();
export const recordLessonProgressHandler = createRecordLessonProgressHandler();
