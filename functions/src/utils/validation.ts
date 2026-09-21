import { z } from "zod";

import {
  MAX_HISTORY_ITEMS_ACCEPTED,
  MAX_HISTORY_ITEM_CHARS_ACCEPTED,
  MAX_USER_MESSAGE_CHARS,
} from "../llm/tutorBudget";
import { resolveTutorId, type TutorId } from "../llm/tutorPersonas";

export const difficultySchema = z.enum(["easy", "medium", "hard"]);
export const summaryLevelSchema = z.enum(["basic", "standard", "advanced"]);

export const generateQuizCallableInputSchema = z.object({
  courseId: z.string().trim().min(3).max(128),
  count: z.coerce.number().int().min(1).max(20),
  difficulty: difficultySchema,
});

export const generateSummaryCallableInputSchema = z.object({
  courseId: z.string().trim().min(3).max(128),
  level: summaryLevelSchema,
});

export type GenerateQuizCallableInput = z.infer<
  typeof generateQuizCallableInputSchema
>;
export type GenerateSummaryCallableInput = z.infer<
  typeof generateSummaryCallableInputSchema
>;


export const clientIdSchema = z
  .string()
  .trim()
  .min(8)
  .max(80)
  .regex(/^[A-Za-z0-9_-]+$/);

// Noms portés par d'anciennes versions installées, avant le regroupement sur
// Kira et Léo. Ils identifient seulement le compagnon : aucun texte de persona
// venu du téléphone n'entre jamais dans le prompt.
const legacyTutorNameAliases: Readonly<Record<string, TutorId>> = {
  ethan: "leo",
  armel: "leo",
  nathan: "leo",
  grace: "kira",
  cynthia: "kira",
  marianne: "kira",
};

function tutorIdFromLegacyName(name: string): TutorId | null {
  const resolved = resolveTutorId(name);
  if (resolved) return resolved;
  const key = name.normalize("NFD").replace(/[\u0300-\u036f]/g, "").trim().toLowerCase();
  return legacyTutorNameAliases[key] ?? null;
}

const legacyTutorSchema = z
  .object({
    name: z.string().max(40),
    specialty: z.string().max(200).optional(),
    personality: z.string().max(200).optional(),
    motto: z.string().max(200).optional(),
  })
  .strict();

export const askTutorCallableInputSchema = z
  .object({
    userMessage: z.string().trim().min(1).max(MAX_USER_MESSAGE_CHARS),
    history: z
      .array(
        z
          .object({
            role: z.enum(["user", "assistant"]),
            text: z.string().max(MAX_HISTORY_ITEM_CHARS_ACCEPTED),
          })
          .strict(),
      )
      .max(MAX_HISTORY_ITEMS_ACCEPTED),
    classLevel: z.string().min(1).max(50),
    // Contrat actuel : un identifiant, rien d'autre.
    tutorId: z.string().max(16).optional(),
    // Contrat des versions déjà installées, accepté borné et jamais injecté.
    tutor: legacyTutorSchema.optional(),
    // Identifiant d'idempotence de la question logique, réutilisé à la relance.
    requestId: clientIdSchema.optional(),
  })
  .strict()
  .transform((input, context) => {
    const tutorId = input.tutorId !== undefined
      ? resolveTutorId(input.tutorId)
      : input.tutor !== undefined
        ? tutorIdFromLegacyName(input.tutor.name)
        : null;
    if (tutorId === null) {
      context.addIssue({
        code: z.ZodIssueCode.custom,
        path: ["tutorId"],
        message: "Unknown tutor.",
      });
      return z.NEVER;
    }
    return {
      userMessage: input.userMessage,
      history: input.history,
      classLevel: input.classLevel,
      tutorId,
      ...(input.requestId !== undefined ? { requestId: input.requestId } : {}),
    };
  });

export type AskTutorCallableInput = z.infer<typeof askTutorCallableInputSchema>;

export const answersByQuestionSchema = z
  .record(z.string().trim().min(1).max(128), z.string().max(1000))
  .refine((answers) => Object.keys(answers).length <= 100, {
    message: "A quiz attempt cannot contain more than 100 answers.",
  });

export const submitQuizAttemptCallableInputSchema = z
  .object({
    quizId: z.string().trim().min(1).max(128),
    clientAttemptId: clientIdSchema,
    answersByQuestion: answersByQuestionSchema,
    startedAt: z.string().datetime().optional(),
    durationSeconds: z.coerce.number().int().min(0).max(86400).optional(),
  })
  .strict();

function firestoreDocumentSegmentSchema(maxLength: number) {
  return z
    .string()
    .trim()
    .min(1)
    .max(maxLength)
    .refine((value) => value !== "." && value !== ".." && !value.includes("/"), {
      message: "Must be a single Firestore document id segment.",
    });
}

export const recordLessonProgressCallableInputSchema = z
  .object({
    classLevel: firestoreDocumentSegmentSchema(64),
    subjectId: firestoreDocumentSegmentSchema(128),
    chapterId: firestoreDocumentSegmentSchema(128),
    lessonId: firestoreDocumentSegmentSchema(128),
    progress: z.coerce.number().min(0).max(1),
    clientEventId: clientIdSchema,
  })
  .strict();

export type SubmitQuizAttemptCallableInput = z.infer<
  typeof submitQuizAttemptCallableInputSchema
>;
export type RecordLessonProgressCallableInput = z.infer<
  typeof recordLessonProgressCallableInputSchema
>;

export const listPublishedQuizzesCallableInputSchema = z
  .object({
    classLevel: z.string().trim().min(1).max(64),
    series: z.string().trim().min(1).max(32).nullable().optional(),
  })
  .strict();

export const getPublishedQuizCallableInputSchema = z
  .object({
    quizId: z.string().trim().min(1).max(128),
  })
  .strict();

export const checkTrainingQuizAnswerCallableInputSchema = z
  .object({
    quizId: z.string().trim().min(1).max(128),
    questionId: z.string().trim().min(1).max(128),
    answer: z.string().max(1000),
  })
  .strict();

export type ListPublishedQuizzesCallableInput = z.infer<
  typeof listPublishedQuizzesCallableInputSchema
>;
export type GetPublishedQuizCallableInput = z.infer<
  typeof getPublishedQuizCallableInputSchema
>;
export type CheckTrainingQuizAnswerCallableInput = z.infer<
  typeof checkTrainingQuizAnswerCallableInputSchema
>;

const staffNameSchema = z.string().trim().min(2).max(60);
const legacyStaffEstablishmentSchema = z
  .object({
    id: z.string().trim().min(2).max(128),
    name: z.string().trim().min(2).max(160),
    city: z.string().trim().min(1).max(80).optional(),
  })
  .strict()
  .optional();

const staffRegistrationBaseSchema = z
  .object({
    firstName: staffNameSchema,
    lastName: staffNameSchema,
    email: z.string().trim().email().max(256),
    establishment: legacyStaffEstablishmentSchema,
    acceptedTerms: z.literal(true),
    acceptedPrivacy: z.literal(true),
  })
  .strict();

export const teacherRegistrationCallableInputSchema =
  staffRegistrationBaseSchema
    .extend({
      role: z.literal("teacher"),
      subjects: z.array(z.string().trim().min(1).max(80)).min(1).max(8),
      levels: z.array(z.string().trim().min(1).max(80)).min(1).max(12),
    })
    .strict();

export const adminRegistrationCallableInputSchema = staffRegistrationBaseSchema
  .extend({
    role: z.literal("admin"),
    jobTitle: z.string().trim().min(3).max(120),
  })
  .strict();

export const staffRegistrationCallableInputSchema = z.discriminatedUnion(
  "role",
  [
    teacherRegistrationCallableInputSchema,
    adminRegistrationCallableInputSchema,
  ],
);

export type StaffRegistrationCallableInput = z.infer<
  typeof staffRegistrationCallableInputSchema
>;

export const staffAccountReviewCallableInputSchema = z
  .object({
    reviewId: z
      .string()
      .trim()
      .min(1)
      .max(128)
      .regex(/^[A-Za-z0-9_-]+$/),
    approved: z.boolean(),
    // Only the general administration may send it: it attaches a school to
    // an account that has none at the moment it approves the account.
    establishmentId: z
      .string()
      .trim()
      .min(1)
      .max(128)
      .regex(/^[A-Za-z0-9_-]+$/)
      .optional(),
  })
  .strict();

export type StaffAccountReviewCallableInput = z.infer<
  typeof staffAccountReviewCallableInputSchema
>;

// The general administration attaches an account to its school, or moves it
// to another one. Identifiers and a reason travel, never a role, a permission
// or a claim.
export const accountEstablishmentChangeInputSchema = z
  .object({
    accountId: z
      .string()
      .trim()
      .min(1)
      .max(128)
      .regex(/^[A-Za-z0-9_-]+$/),
    establishmentId: z
      .string()
      .trim()
      .min(1)
      .max(128)
      .regex(/^[A-Za-z0-9_-]+$/),
    reason: z.string().trim().min(5).max(280).optional(),
  })
  .strict();

export type AccountEstablishmentChangeInput = z.infer<
  typeof accountEstablishmentChangeInputSchema
>;

// Course pages photographed or scanned by staff, already uploaded under the
// educational assets tree. Only their storage paths travel to the function.
export const coursePageImportInputSchema = z
  .object({
    classLevel: z.string().trim().min(1).max(32),
    subjectLabel: z.string().trim().min(1).max(80),
    chapterTitle: z.string().trim().max(160).optional(),
    language: z.enum(["fr", "en"]).default("fr"),
    storagePaths: z
      .array(
        z
          .string()
          .trim()
          .max(512)
          .regex(/^educational_assets\/[A-Za-z0-9_-]+(\/[A-Za-z0-9._-]+)+$/)
          .refine((path) => !path.includes(".."), "Path traversal is forbidden."),
      )
      .min(1)
      .max(12),
    rightsConfirmed: z.literal(true),
  })
  .strict();

export type CoursePageImportInput = z.infer<typeof coursePageImportInputSchema>;
