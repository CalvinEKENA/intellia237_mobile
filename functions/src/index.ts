import { createSaveFlowPublicationHandler } from "./services/saveFlowPublicationCallable";
import { createLearningCatalogHandler } from "./services/learningCatalogCallable";
import { createEducationalMediaHandler } from "./services/educationalMedia";
import { randomUUID } from "node:crypto";

import { logger } from "firebase-functions";
import { setGlobalOptions } from "firebase-functions/v2";
import { HttpsError } from "firebase-functions/v2/https";
import { onCallWithAccountAccess as onCall } from "./services/callableAccountAccess";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { getAuth } from "firebase-admin/auth";
import { bucket, db } from "./config/firebase";

import { getEnv } from "./config/env";
import { ASK_TUTOR_CALLABLE_TIMEOUT_SECONDS } from "./config/timeouts";
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
import { toHttpsError } from "./utils/errors";
import {
  askTutorCallableInputSchema,
} from "./utils/validation";
import { AskTutorUseCase } from "./services/askTutorUseCase";
import {
  AccountDeletionProcessor,
  AdminDeletionAuthPort,
  cancelAccountDeletionHandler,
  requestAccountDeletionHandler,
} from "./services/accountDeletionCallable";
import { BucketDeletionStoragePort } from "./services/accountDeletionStorage";
import { linkChildByCodeHandler, ensureStudentLinkCodeHandler, rotateStudentLinkCodeHandler } from "./services/childLinkCallable";
import { getStudyReserveHandler } from "./services/studyReserve";
import { defineSecret } from "firebase-functions/params";
import {
  createIssueStudentAccessCodeHandler,
  createSignInWithStudentAccessCodeHandler,
} from "./services/studentAccessCode";
import { createDefaultMigrateStudentPhoneToParentHandler } from "./services/familyPhoneMigration";
import { createListParentChildrenHandler } from "./services/parentChildrenCallable";
import { createDefaultCreateChildStudentAccessHandler } from "./services/childStudentAccessCallable";
import { reviewStaffAccountHandler } from "./services/staffAccountReviewCallable";
import { manageAccountHandler } from "./services/adminAccountManagementCallable";
import { saveLessonPublicationHandler, deleteCatalogContentHandler, createCatalogChapterHandler, createListEditorialFlowHandler } from "./services/lessonPublicationCallable";
import { listRegistrationEstablishmentsHandler } from "./services/registrationEstablishmentsCallable";
import { changeAccountEstablishmentHandler } from "./services/accountEstablishmentChangeCallable";
import { importCoursePagesHandler } from "./services/coursePageImport";
import { submitFlowActivityHandler } from "./services/flowPointsCallable";
import {
  getMobileMoneyOverviewHandler,
  listMobileMoneyPaymentsHandler,
  reviewMobileMoneyPaymentHandler,
  submitMobileMoneyPaymentHandler,
} from "./services/mobileMoneyCallables";
import { deliverNotificationPushHandler } from "./services/notificationDelivery";
import { fanoutAnnouncementHandler } from "./services/announcementNotificationFanout";
import { manageEstablishmentHandler } from "./services/establishmentManagementCallable";
import { manageSchoolClassHandler } from "./services/classManagementCallable";
import { getCompanionRuntimeConfigHandler } from "./services/companionRuntimeConfigCallable";
import { createProbeGoogleIdentityHandler, parseGoogleClientIds } from "./services/googleIdentityProbe";

const env = getEnv();
setGlobalOptions({
  region: env.FUNCTIONS_REGION,
  maxInstances: 20,
  // Rollout contrôlé : false permet d'observer les jetons App Check avant de
  // basculer toutes les callables sur un refus strict dans un déploiement dédié.
  enforceAppCheck: env.ENFORCE_APP_CHECK,
});

export const saveFlowPublication = onCall({ timeoutSeconds: 60, region: env.FUNCTIONS_REGION }, createSaveFlowPublicationHandler());
export const readLearningCatalog = onCall({ timeoutSeconds: 60, region: env.FUNCTIONS_REGION }, createLearningCatalogHandler());
export const educationalMedia = onCall({ timeoutSeconds: 60, region: env.FUNCTIONS_REGION }, createEducationalMediaHandler());
export const saveLessonPublication = onCall({ timeoutSeconds: 120, memory: "512MiB", region: env.FUNCTIONS_REGION }, saveLessonPublicationHandler);
export const deleteCatalogContent = onCall({ timeoutSeconds: 300, memory: "512MiB", region: env.FUNCTIONS_REGION }, deleteCatalogContentHandler);
export const listRegistrationEstablishments = onCall({ timeoutSeconds: 30, region: env.FUNCTIONS_REGION }, listRegistrationEstablishmentsHandler);
export const createCatalogChapter = onCall({ timeoutSeconds: 60, region: env.FUNCTIONS_REGION }, createCatalogChapterHandler());
export const listEditorialFlow = onCall({ timeoutSeconds: 30, region: env.FUNCTIONS_REGION }, createListEditorialFlowHandler());
export const manageEstablishment = onCall({ timeoutSeconds: 30, region: env.FUNCTIONS_REGION }, manageEstablishmentHandler);
export const manageSchoolClass = onCall({ timeoutSeconds: 30, region: env.FUNCTIONS_REGION }, manageSchoolClassHandler);
export const getCompanionRuntimeConfig = onCall({ timeoutSeconds: 30, region: env.FUNCTIONS_REGION }, getCompanionRuntimeConfigHandler);

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

// generateQuiz et generateSummary ne sont plus exposées : aucune version de
// l'application ni Studio ne les appelle, et elles laissaient tout compte
// connecté déclencher une génération Gemini sans rôle ni quota. La logique
// reste disponible pour les scripts d'administration (scripts/pregenerate.ts).

export const askTutor = onCall(
  {
    region: env.FUNCTIONS_REGION,
    // Contrat fournisseur (45 s) < callable (75 s) < téléphone (90 s) :
    // voir config/timeouts.ts.
    timeoutSeconds: ASK_TUTOR_CALLABLE_TIMEOUT_SECONDS,
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

export const cancelAccountDeletion = onCall(
  {
    region: env.FUNCTIONS_REGION,
    timeoutSeconds: 15,
    memory: "256MiB",
  },
  cancelAccountDeletionHandler,
);

// Traitement des suppressions arrivées à échéance (délai de grâce de 7 jours),
// idempotent et repris en cas d'échec : docs/architecture/ACCOUNT_DELETION.md.
export const processAccountDeletions = onSchedule(
  {
    region: env.FUNCTIONS_REGION,
    schedule: "every 60 minutes",
    timeZone: "Africa/Douala",
    timeoutSeconds: 540,
    memory: "512MiB",
    retryCount: 0,
  },
  async () => {
    const processor = new AccountDeletionProcessor(
      db,
      new AdminDeletionAuthPort(getAuth()),
      new BucketDeletionStoragePort(bucket),
    );
    const result = await processor.processDue();
    logger.info("Account deletion run finished.", result);
  },
);

export const reviewStaffAccount = onCall(
  {
    region: env.FUNCTIONS_REGION,
    timeoutSeconds: 20,
    memory: "256MiB",
  },
  reviewStaffAccountHandler,
);

export const manageAccount = onCall(
  { region: env.FUNCTIONS_REGION, timeoutSeconds: 30, memory: "256MiB" },
  manageAccountHandler,
);

export const changeAccountEstablishment = onCall(
  {
    region: env.FUNCTIONS_REGION,
    timeoutSeconds: 30,
    memory: "256MiB",
  },
  changeAccountEstablishmentHandler,
);

// Reading photographed pages takes one multimodal request of up to two
// minutes: the function outlives it, and holds the pages in memory once.
export const importCoursePages = onCall(
  {
    region: env.FUNCTIONS_REGION,
    timeoutSeconds: 180,
    memory: "1GiB",
  },
  importCoursePagesHandler,
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

// Liaison parent ↔ enfant, autoritaire côté serveur (section C release v27).
export const linkChildByCode = onCall(
  {
    region: env.FUNCTIONS_REGION,
    timeoutSeconds: 20,
    memory: "256MiB",
  },
  linkChildByCodeHandler,
);

export const ensureStudentLinkCode = onCall(
  {
    region: env.FUNCTIONS_REGION,
    timeoutSeconds: 20,
    memory: "256MiB",
  },
  ensureStudentLinkCodeHandler,
);

export const rotateStudentLinkCode = onCall(
  {
    region: env.FUNCTIONS_REGION,
    timeoutSeconds: 20,
    memory: "256MiB",
  },
  rotateStudentLinkCodeHandler,
);

// Accès famille : code d'accès élève, migration du téléphone familial, enfants
// d'un parent. Le poivre HMAC vit dans Secret Manager ; sans lui, rien ne
// s'émet ni ne s'ouvre (voir docs/architecture/FAMILY_IDENTITY_ACCESS_BILLING.md).
const studentAccessCodePepper = defineSecret("STUDENT_ACCESS_CODE_PEPPER");

function configuredStudentAccessPepper(): string {
  const value = studentAccessCodePepper.value();
  if (typeof value !== "string" || value.length < 32) {
    logger.error("STUDENT_ACCESS_CODE_PEPPER is missing or too short.");
    throw new HttpsError("failed-precondition", "Student access is not configured.");
  }
  return value;
}

export const issueStudentAccessCode = onCall(
  {
    region: env.FUNCTIONS_REGION,
    timeoutSeconds: 20,
    memory: "256MiB",
    secrets: [studentAccessCodePepper],
  },
  createIssueStudentAccessCodeHandler(configuredStudentAccessPepper),
);

// Publique : ne répond qu'au détenteur d'un jeton Google frais, sur son propre
// compte, par « existing » ou « unknown ». Ne crée jamais d'utilisateur.
export const probeGoogleIdentity = onCall(
  {
    region: env.FUNCTIONS_REGION,
    timeoutSeconds: 15,
    memory: "256MiB",
  },
  createProbeGoogleIdentityHandler({
    audiences: () => parseGoogleClientIds(env.GOOGLE_OAUTH_CLIENT_IDS),
  }),
);

export const signInWithStudentAccessCode = onCall(
  {
    region: env.FUNCTIONS_REGION,
    timeoutSeconds: 20,
    memory: "256MiB",
    secrets: [studentAccessCodePepper],
  },
  createSignInWithStudentAccessCodeHandler(configuredStudentAccessPepper),
);

export const migrateStudentPhoneToParent = onCall(
  {
    region: env.FUNCTIONS_REGION,
    timeoutSeconds: 60,
    memory: "256MiB",
    secrets: [studentAccessCodePepper],
  },
  createDefaultMigrateStudentPhoneToParentHandler(configuredStudentAccessPepper),
);

export const createChildStudentAccess = onCall(
  {
    region: env.FUNCTIONS_REGION,
    timeoutSeconds: 30,
    memory: "256MiB",
    secrets: [studentAccessCodePepper],
  },
  createDefaultCreateChildStudentAccessHandler(configuredStudentAccessPepper),
);

export const listParentChildren = onCall(
  {
    region: env.FUNCTIONS_REGION,
    timeoutSeconds: 20,
    memory: "256MiB",
  },
  createListParentChildrenHandler(),
);

export const getStudyReserve = onCall(
  {
    region: env.FUNCTIONS_REGION,
    timeoutSeconds: 20,
    memory: "256MiB",
  },
  getStudyReserveHandler,
);
