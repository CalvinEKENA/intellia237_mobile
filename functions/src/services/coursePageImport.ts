import { logger } from "firebase-functions";
import type { CallableRequest } from "firebase-functions/v2/https";
import { HttpsError } from "firebase-functions/v2/https";
import { FieldValue, type DocumentData, type Firestore } from "firebase-admin/firestore";
import { z } from "zod";

import { bucket, db } from "../config/firebase";
import { generateStructuredContent, type InlineAttachment } from "../llm/llmClient";
import { AppError, toHttpsError } from "../utils/errors";
import {
  type CoursePageImportInput,
  coursePageImportInputSchema,
} from "../utils/validation";
import { tutorQuotaDayKey } from "./tutorDailyQuota";

/**
 * Photographed or scanned course pages, read once by Gemini and returned as
 * drafts: a lesson, QCM, corrected exercises and FLOW cards.
 *
 * Decision log: nothing is written here. The function reads and proposes; the
 * Studio shows every piece to its author, who edits, discards and only then
 * creates drafts that follow the usual editorial workflow. Pages stay in the
 * educational assets tree, under the scope the author may write.
 */

const ALLOWED_PAGE_TYPES = new Set([
  "image/jpeg",
  "image/png",
  "image/webp",
  "application/pdf",
]);

// Inline data grows by a third once base64-encoded; the request must stay
// under the provider's inline limit.
export const MAX_TOTAL_PAGE_BYTES = 14 * 1024 * 1024;

// Scanned PDF pages weigh a few hundred kilobytes each: the quota counts what
// the model actually reads rather than the number of files.
const PDF_BYTES_PER_PAGE = 400 * 1024;

export const DAILY_PAGE_LIMIT = {
  generalAdministration: 150,
  staff: 40,
} as const;

const text = (max: number) => z.string().trim().min(1).max(max);

export const coursePageDraftSchema = z.object({
  lesson: z.object({
    title: text(160),
    summary: text(600),
    estimatedMinutes: z.number().int().min(5).max(120),
    sections: z
      .array(z.object({ title: text(160), body: text(6000) }))
      .min(1)
      .max(24),
  }),
  quizQuestions: z
    .array(
      z.object({
        prompt: text(600),
        options: z.array(text(300)).min(2).max(6),
        correctOptionIndex: z.number().int().min(0),
        explanation: z.string().trim().max(1200).default(""),
      }),
    )
    .max(20)
    .default([]),
  exercises: z
    .array(
      z.object({
        statement: text(3000),
        solution: text(4000),
        difficulty: z.number().int().min(1).max(5).default(3),
      }),
    )
    .max(15)
    .default([]),
  flowCards: z
    .array(
      z.discriminatedUnion("type", [
        z.object({
          type: z.literal("notion"),
          title: text(120),
          hook: z.string().trim().max(200).default(""),
          insight: text(400),
          points: z.array(text(200)).max(5).default([]),
        }),
        z.object({
          type: z.literal("question"),
          title: text(120),
          question: text(600),
          answer: text(1200),
        }),
        z.object({
          type: z.literal("quiz"),
          title: text(120),
          question: text(600),
          options: z.array(text(300)).min(2).max(6),
          correctIndex: z.number().int().min(0),
          explanation: z.string().trim().max(800).default(""),
        }),
      ]),
    )
    .max(20)
    .default([]),
  warnings: z.array(text(300)).max(10).default([]),
});

export type CoursePageDraft = z.infer<typeof coursePageDraftSchema>;

export const COURSE_PAGE_IMPORT_SYSTEM_PROMPT = `Tu es l'éditeur pédagogique d'INTELLIA237, application d'apprentissage de l'enseignement secondaire au Cameroun.
On te confie des photos ou des PDF de pages de cours. Tu les transformes fidèlement en contenus exploitables, que l'équipe relira avant toute publication.

Règles impératives :
- Reste fidèle aux pages. N'invente ni notion, ni chiffre, ni date, ni définition absents des pages. Tu peux reformuler et structurer.
- Si un passage est illisible, coupé ou ambigu, ne devine pas : signale-le dans "warnings".
- Écris les formules en texte lisible avec les symboles Unicode (x², √, ≤, π, →, Δ, ∈…), jamais en LaTeX ni en Markdown.
- Pas de Markdown : ni #, ni **, ni tableaux. Des phrases et des retours à la ligne suffisent.
- Adapte le niveau de langue à la classe indiquée.
- Chaque QCM a exactement une bonne réponse et des distracteurs plausibles, tirés des erreurs fréquentes.
- Chaque exercice a un corrigé complet, étape par étape.
- Réponds uniquement par un objet JSON valide, sans texte autour.`;

export function buildCoursePageImportPrompt(
  input: CoursePageImportInput,
  pageCount: number,
): string {
  const language = input.language === "en" ? "anglais" : "français";
  return `Classe : ${input.classLevel}
Matière : ${input.subjectLabel}
Chapitre : ${input.chapterTitle?.trim() || "non précisé"}
Langue des contenus : ${language}
Fichiers fournis : ${pageCount}, dans l'ordre des pages.

Produis exactement ce JSON :
{
  "lesson": {"title": "…", "summary": "2 à 3 phrases", "estimatedMinutes": 20, "sections": [{"title": "…", "body": "…"}]},
  "quizQuestions": [{"prompt": "…", "options": ["…", "…", "…", "…"], "correctOptionIndex": 0, "explanation": "…"}],
  "exercises": [{"statement": "…", "solution": "…", "difficulty": 3}],
  "flowCards": [
    {"type": "notion", "title": "…", "hook": "…", "insight": "l'idée clé en une ou deux phrases", "points": ["…"]},
    {"type": "question", "title": "…", "question": "…", "answer": "…"},
    {"type": "quiz", "title": "…", "question": "…", "options": ["…", "…", "…"], "correctIndex": 0, "explanation": "…"}
  ],
  "warnings": ["…"]
}

Quantités visées : 3 à 10 sections, 5 à 10 QCM, 3 à 6 exercices, 4 à 8 cartes FLOW mêlant notions, questions et mini-quiz.
Si les pages ne permettent pas d'atteindre ces quantités sans inventer, produis-en moins et explique-le dans "warnings".`;
}

/**
 * Staff may read pages for the scope they can write: the general
 * administration for every scope, a school's active staff for their school.
 */
export function authorizeCoursePageImport({
  userData,
  storagePaths,
}: {
  userData: DocumentData | undefined;
  storagePaths: string[];
}): { dailyPageLimit: number } {
  const role = normalizedString(userData?.role);
  const status = normalizedString(userData?.accountStatus);
  if (status && status !== "active") {
    throw new AppError("permission-denied", "The account is not active.");
  }

  if (role === "superAdmin" || role === "super_admin") {
    return { dailyPageLimit: DAILY_PAGE_LIMIT.generalAdministration };
  }
  if (role !== "admin" && role !== "teacher") {
    throw new AppError("permission-denied", "Only staff can import course pages.");
  }
  const establishmentId = normalizedString(userData?.establishmentId);
  if (!establishmentId) {
    throw new AppError(
      "permission-denied",
      "A staff account must belong to a school to import course pages.",
    );
  }
  for (const path of storagePaths) {
    if (path.split("/")[1] !== establishmentId) {
      throw new AppError("permission-denied", "These pages belong to another scope.");
    }
  }
  return { dailyPageLimit: DAILY_PAGE_LIMIT.staff };
}

export function pageUnits(attachments: InlineAttachment[]): number {
  return attachments.reduce((total, attachment) => {
    if (attachment.mimeType !== "application/pdf") return total + 1;
    const bytes = Math.floor((attachment.data.length * 3) / 4);
    return total + Math.max(1, Math.ceil(bytes / PDF_BYTES_PER_PAGE));
  }, 0);
}

/** Discards what would mislead a learner instead of trusting the model. */
export function sanitizeCoursePageDraft(draft: CoursePageDraft): CoursePageDraft {
  const warnings = [...draft.warnings];
  const quizQuestions = draft.quizQuestions.filter(
    (question) => question.correctOptionIndex < question.options.length,
  );
  if (quizQuestions.length < draft.quizQuestions.length) {
    warnings.push("Des QCM sans bonne réponse valide ont été écartés.");
  }
  const flowCards = draft.flowCards.filter(
    (card) => card.type !== "quiz" || card.correctIndex < card.options.length,
  );
  if (flowCards.length < draft.flowCards.length) {
    warnings.push("Des mini-quiz FLOW sans bonne réponse valide ont été écartés.");
  }
  return { ...draft, quizQuestions, flowCards, warnings };
}

export interface CoursePageSource {
  load(storagePaths: string[]): Promise<InlineAttachment[]>;
}

export class StorageCoursePageSource implements CoursePageSource {
  async load(storagePaths: string[]): Promise<InlineAttachment[]> {
    const attachments: InlineAttachment[] = [];
    let totalBytes = 0;
    for (const path of storagePaths) {
      const file = bucket.file(path);
      const [exists] = await file.exists();
      if (!exists) {
        throw new AppError("not-found", "A page could not be found.");
      }
      const [metadata] = await file.getMetadata();
      const contentType = String(metadata.contentType ?? "").toLowerCase();
      if (!ALLOWED_PAGE_TYPES.has(contentType)) {
        throw new AppError(
          "invalid-argument",
          "Only JPEG, PNG or WebP images and PDF documents can be read.",
        );
      }
      totalBytes += Number(metadata.size ?? 0);
      if (totalBytes > MAX_TOTAL_PAGE_BYTES) {
        throw new AppError(
          "invalid-argument",
          "These pages are too heavy to be read together.",
        );
      }
      const [buffer] = await file.download();
      attachments.push({ mimeType: contentType, data: buffer.toString("base64") });
    }
    return attachments;
  }
}

export interface PageImportQuotaStore {
  reserve(userId: string, units: number, limit: number): Promise<void>;
  release(userId: string, units: number): Promise<void>;
}

export class FirestorePageImportQuotaStore implements PageImportQuotaStore {
  constructor(
    private readonly firestore: Firestore = db,
    private readonly now: () => Date = () => new Date(),
  ) {}

  async reserve(userId: string, units: number, limit: number): Promise<void> {
    const document = this.document(userId);
    await this.firestore.runTransaction(async (transaction) => {
      const used = readUnits((await transaction.get(document)).data());
      if (used + units > limit) {
        throw new AppError(
          "resource-exhausted",
          "The daily course page reading quota is reached.",
        );
      }
      transaction.set(
        document,
        { userId, units: used + units, updatedAt: FieldValue.serverTimestamp() },
        { merge: true },
      );
    });
  }

  async release(userId: string, units: number): Promise<void> {
    const document = this.document(userId);
    await this.firestore.runTransaction(async (transaction) => {
      const used = readUnits((await transaction.get(document)).data());
      transaction.set(
        document,
        { units: Math.max(0, used - units), updatedAt: FieldValue.serverTimestamp() },
        { merge: true },
      );
    });
  }

  private document(userId: string) {
    return this.firestore
      .collection("course_page_import_daily_usage")
      .doc(`${userId}_${tutorQuotaDayKey(this.now())}`);
  }
}

export interface CoursePageExtractor {
  extract(params: {
    correlationId: string;
    system: string;
    prompt: string;
    attachments: InlineAttachment[];
  }): Promise<CoursePageDraft>;
}

export const vertexCoursePageExtractor: CoursePageExtractor = {
  extract: (params) => generateStructuredContent({
    operation: "importCoursePages",
    correlationId: params.correlationId,
    system: params.system,
    prompt: params.prompt,
    schema: coursePageDraftSchema,
    attachments: params.attachments,
    timeoutMs: 120_000,
  }),
};

export interface CoursePageImportDependencies {
  readUser(userId: string): Promise<DocumentData | undefined>;
  source: CoursePageSource;
  quota: PageImportQuotaStore;
  extractor: CoursePageExtractor;
}

export function createImportCoursePagesHandler(
  dependencies?: Partial<CoursePageImportDependencies>,
) {
  const deps: CoursePageImportDependencies = {
    readUser: async (userId) => (await db.collection("users").doc(userId).get()).data(),
    source: new StorageCoursePageSource(),
    quota: new FirestorePageImportQuotaStore(),
    extractor: vertexCoursePageExtractor,
    ...dependencies,
  };

  return async (request: CallableRequest<unknown>): Promise<CoursePageDraft> => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Firebase Auth is required.");
    }
    const userId = request.auth.uid;
    let reservedUnits = 0;

    try {
      const input = coursePageImportInputSchema.parse(request.data);
      const access = authorizeCoursePageImport({
        userData: await deps.readUser(userId),
        storagePaths: input.storagePaths,
      });
      const attachments = await deps.source.load(input.storagePaths);
      const units = pageUnits(attachments);
      await deps.quota.reserve(userId, units, access.dailyPageLimit);
      reservedUnits = units;

      const draft = await deps.extractor.extract({
        correlationId: `pages-${userId.slice(0, 8)}-${Date.now()}`,
        system: COURSE_PAGE_IMPORT_SYSTEM_PROMPT,
        prompt: buildCoursePageImportPrompt(input, attachments.length),
        attachments,
      });
      return sanitizeCoursePageDraft(draft);
    } catch (error) {
      if (reservedUnits > 0) {
        // A failed reading costs the author nothing.
        await deps.quota.release(userId, reservedUnits).catch(() => undefined);
      }
      logger.error("importCoursePages failed.", {
        userId,
        error: error instanceof Error ? error.message : String(error),
      });
      throw toHttpsError(error);
    }
  };
}

function normalizedString(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

function readUnits(data: DocumentData | undefined): number {
  const units: unknown = data?.units;
  return typeof units === "number" && Number.isFinite(units) ? units : 0;
}

export const importCoursePagesHandler = createImportCoursePagesHandler();
