import { randomUUID } from "node:crypto";

import { logger } from "firebase-functions";
import { setGlobalOptions } from "firebase-functions/v2";
import { HttpsError, onCall } from "firebase-functions/v2/https";

import { getEnv } from "./config/env";
import {
  recordLessonProgressHandler,
  submitQuizAttemptHandler
} from "./services/academicCallables";
import { GenerateQuizUseCase } from "./services/generateQuizUseCase";
import { GenerateSummaryUseCase } from "./services/generateSummaryUseCase";
import { toHttpsError } from "./utils/errors";
import {
  generateQuizCallableInputSchema,
  generateSummaryCallableInputSchema,
  askTutorCallableInputSchema
} from "./utils/validation";
import { AskTutorUseCase } from "./services/askTutorUseCase";

const env = getEnv();
setGlobalOptions({
  region: env.FUNCTIONS_REGION,
  maxInstances: 20
});

const generateQuizUseCase = new GenerateQuizUseCase();
const generateSummaryUseCase = new GenerateSummaryUseCase();
const askTutorUseCase = new AskTutorUseCase();

export const generateQuiz = onCall(
  {
    region: env.FUNCTIONS_REGION,
    timeoutSeconds: 120,
    memory: "1GiB"
  },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Firebase Auth is required.");
    }

    const traceId = randomUUID();

    try {
      const input = generateQuizCallableInputSchema.parse(request.data);
      const result = await generateQuizUseCase.execute({
        userId: request.auth.uid,
        traceId,
        courseId: input.courseId,
        count: input.count,
        difficulty: input.difficulty
      });

      return {
        traceId,
        ...result
      };
    } catch (error) {
      logger.error("generateQuiz failed.", {
        traceId,
        error: error instanceof Error ? error.message : String(error)
      });
      throw toHttpsError(error);
    }
  }
);

export const generateSummary = onCall(
  {
    region: env.FUNCTIONS_REGION,
    timeoutSeconds: 120,
    memory: "1GiB"
  },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Firebase Auth is required.");
    }

    const traceId = randomUUID();

    try {
      const input = generateSummaryCallableInputSchema.parse(request.data);
      const result = await generateSummaryUseCase.execute({
        userId: request.auth.uid,
        traceId,
        courseId: input.courseId,
        level: input.level
      });

      return {
        traceId,
        ...result
      };
    } catch (error) {
      logger.error("generateSummary failed.", {
        traceId,
        error: error instanceof Error ? error.message : String(error)
      });
      throw toHttpsError(error);
    }
  }
);

export const askTutor = onCall(
  {
    region: env.FUNCTIONS_REGION,
    timeoutSeconds: 30, // 30s is more than enough for Gemini chat completion
    memory: "512MiB"
  },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Firebase Auth is required.");
    }

    const traceId = randomUUID();

    try {
      const input = askTutorCallableInputSchema.parse(request.data);
      const result = await askTutorUseCase.execute({
        userId: request.auth.uid,
        traceId,
        input
      });

      return {
        traceId,
        ...result
      };
    } catch (error) {
      logger.error("askTutor failed.", {
        traceId,
        error: error instanceof Error ? error.message : String(error)
      });
      throw toHttpsError(error);
    }
  }
);

export const submitQuizAttempt = onCall(
  {
    region: env.FUNCTIONS_REGION,
    timeoutSeconds: 30,
    memory: "512MiB"
  },
  submitQuizAttemptHandler
);

export const recordLessonProgress = onCall(
  {
    region: env.FUNCTIONS_REGION,
    timeoutSeconds: 30,
    memory: "512MiB"
  },
  recordLessonProgressHandler
);
