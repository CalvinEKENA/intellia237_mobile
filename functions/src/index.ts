import { randomUUID } from "node:crypto";

import { logger } from "firebase-functions";
import { setGlobalOptions } from "firebase-functions/v2";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { onDocumentCreated } from "firebase-functions/v2/firestore";

import { getEnv } from "./config/env";
import {
  recordLessonProgressHandler,
  submitQuizAttemptHandler,
} from "./services/academicCallables";
import { submitStaffRegistrationHandler } from "./services/staffRegistrationCallable";
import {
  checkTrainingQuizAnswerHandler,
  getPublishedQuizHandler,
  listPublishedQuizzesHandler,
} from "./services/quizContentCallables";
import { listQuizAttemptHistoryHandler } from "./services/quizAttemptHistoryCallable";
import { GenerateQuizUseCase } from "./services/generateQuizUseCase";
import { GenerateSummaryUseCase } from "./services/generateSummaryUseCase";
import { toHttpsError } from "./utils/errors";
import {
  generateQuizCallableInputSchema,
  generateSummaryCallableInputSchema,
  askTutorCallableInputSchema,
} from "./utils/validation";
import { AskTutorUseCase } from "./services/askTutorUseCase";
import { requestAccountDeletionHandler } from "./services/accountDeletionCallable";
import { reviewStaffAccountHandler } from "./services/staffAccountReviewCallable";
import { submitFlowActivityHandler } from "./services/flowPointsCallable";
import {
  getMobileMoneyOverviewHandler,
  listMobileMoneyPaymentsHandler,
  reviewMobileMoneyPaymentHandler,
  submitMobileMoneyPaymentHandler,
} from "./services/mobileMoneyCallables";
import { deliverNotificationPushHandler } from "./services/notificationDelivery";
import { fanoutAnnouncementHandler } from "./services/announcementNotificationFanout";

const env = getEnv();
setGlobalOptions({
  region: env.FUNCTIONS_REGION,
  maxInstances: 20,
  // Rollout contrôlé : false permet d'observer les jetons App Check avant de
  // basculer toutes les callables sur un refus strict dans un déploiement dédié.
  enforceAppCheck: env.ENFORCE_APP_CHECK,
});

const generateQuizUseCase = new GenerateQuizUseCase();
const generateSummaryUseCase = new GenerateSummaryUseCase();
const askTutorUseCase = new AskTutorUseCase();

export const deliverNotificationPush = onDocumentCreated(
  {
    region: env.FUNCTIONS_REGION,
    document: "notifications/{notificationId}",
    retry: true,
  },
  deliverNotificationPushHandler,
);

export const fanoutAnnouncementNotifications = onDocumentCreated(
  {
    region: env.FUNCTIONS_REGION,
    document: "announcements/{announcementId}",
    retry: true,
    timeoutSeconds: 300,
    memory: "512MiB",
  },
  fanoutAnnouncementHandler,
);

export const generateQuiz = onCall(
  {
    region: env.FUNCTIONS_REGION,
    timeoutSeconds: 120,
    memory: "1GiB",
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
        difficulty: input.difficulty,
      });

      return {
        traceId,
        ...result,
      };
    } catch (error) {
      logger.error("generateQuiz failed.", {
        traceId,
        error: error instanceof Error ? error.message : String(error),
      });
      throw toHttpsError(error);
    }
  },
);

export const generateSummary = onCall(
  {
    region: env.FUNCTIONS_REGION,
    timeoutSeconds: 120,
    memory: "1GiB",
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
        level: input.level,
      });

      return {
        traceId,
        ...result,
      };
    } catch (error) {
      logger.error("generateSummary failed.", {
        traceId,
        error: error instanceof Error ? error.message : String(error),
      });
      throw toHttpsError(error);
    }
  },
);

export const askTutor = onCall(
  {
    region: env.FUNCTIONS_REGION,
    // Must exceed the default 45s provider timeout so quota reservations can
    // always be released by the catch path before the platform terminates us.
    timeoutSeconds: 60,
    memory: "512MiB",
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
        input,
      });

      return {
        traceId,
        ...result,
      };
    } catch (error) {
      logger.error("askTutor failed.", {
        traceId,
        error: error instanceof Error ? error.message : String(error),
      });
      throw toHttpsError(error);
    }
  },
);

export const submitQuizAttempt = onCall(
  {
    region: env.FUNCTIONS_REGION,
    timeoutSeconds: 30,
    memory: "512MiB",
  },
  submitQuizAttemptHandler,
);

export const listPublishedQuizzes = onCall(
  {
    region: env.FUNCTIONS_REGION,
    timeoutSeconds: 20,
    memory: "256MiB",
  },
  listPublishedQuizzesHandler,
);

export const getPublishedQuiz = onCall(
  {
    region: env.FUNCTIONS_REGION,
    timeoutSeconds: 20,
    memory: "256MiB",
  },
  getPublishedQuizHandler,
);

export const checkTrainingQuizAnswer = onCall(
  {
    region: env.FUNCTIONS_REGION,
    timeoutSeconds: 20,
    memory: "256MiB",
  },
  checkTrainingQuizAnswerHandler,
);

export const listQuizAttemptHistory = onCall(
  {
    region: env.FUNCTIONS_REGION,
    timeoutSeconds: 20,
    memory: "256MiB",
  },
  listQuizAttemptHistoryHandler,
);

export const recordLessonProgress = onCall(
  {
    region: env.FUNCTIONS_REGION,
    timeoutSeconds: 30,
    memory: "512MiB",
  },
  recordLessonProgressHandler,
);

export const submitStaffRegistration = onCall(
  {
    region: env.FUNCTIONS_REGION,
    timeoutSeconds: 30,
    memory: "256MiB",
  },
  submitStaffRegistrationHandler,
);

export const requestAccountDeletion = onCall(
  {
    region: env.FUNCTIONS_REGION,
    timeoutSeconds: 15,
    memory: "256MiB",
  },
  requestAccountDeletionHandler,
);

export const reviewStaffAccount = onCall(
  {
    region: env.FUNCTIONS_REGION,
    timeoutSeconds: 20,
    memory: "256MiB",
  },
  reviewStaffAccountHandler,
);

export const submitFlowActivity = onCall(
  {
    region: env.FUNCTIONS_REGION,
    timeoutSeconds: 20,
    memory: "256MiB",
  },
  submitFlowActivityHandler,
);

export const getMobileMoneyOverview = onCall(
  {
    region: env.FUNCTIONS_REGION,
    timeoutSeconds: 20,
    memory: "256MiB",
  },
  getMobileMoneyOverviewHandler,
);

export const submitMobileMoneyPayment = onCall(
  {
    region: env.FUNCTIONS_REGION,
    timeoutSeconds: 20,
    memory: "256MiB",
  },
  submitMobileMoneyPaymentHandler,
);

export const listMobileMoneyPayments = onCall(
  {
    region: env.FUNCTIONS_REGION,
    timeoutSeconds: 20,
    memory: "256MiB",
  },
  listMobileMoneyPaymentsHandler,
);

export const reviewMobileMoneyPayment = onCall(
  {
    region: env.FUNCTIONS_REGION,
    timeoutSeconds: 20,
    memory: "256MiB",
  },
  reviewMobileMoneyPaymentHandler,
);
