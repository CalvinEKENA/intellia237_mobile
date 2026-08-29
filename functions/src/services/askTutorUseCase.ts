import type { DocumentData, Firestore } from "firebase-admin/firestore";

import { db } from "../config/firebase";
import { getEnv } from "../config/env";
import { generateText, logAiQuotaRejection } from "../llm/llmClient";
import { ASK_TUTOR_SYSTEM_PROMPT, buildAskTutorUserPrompt } from "../llm/prompts";
import { AppError } from "../utils/errors";
import type { AskTutorCallableInput } from "../utils/validation";
import {
  FirestoreTutorQuotaStore,
  type TutorQuotaSnapshot,
  type TutorQuotaStore,
} from "./tutorDailyQuota";

const MAX_CONTEXT_LESSONS = 3;
const MAX_CONTEXT_CHARACTERS = 5_000;

export interface TutorAcademicScope {
  classLevel: string;
  establishmentId: string | null;
}

export interface AuthorizedTutorContext {
  scope: TutorAcademicScope;
  text: string;
}

export interface TutorContextStore {
  loadAuthorizedContext(params: {
    userId: string;
    requestedClassLevel: string;
  }): Promise<AuthorizedTutorContext>;
}

type TutorTextGenerator = (params: {
  operation: "askTutor";
  correlationId: string;
  system: string;
  prompt: string;
}) => Promise<string>;

/**
 * Loads only lessons the authenticated student has actually opened, under the
 * student's authoritative class path. There is intentionally no broad
 * collectionGroup fallback: an empty context is safer and more honest than a
 * random lesson from another class or school.
 */
export class FirestoreTutorContextStore implements TutorContextStore {
  constructor(private readonly firestore: Firestore = db) {}

  async loadAuthorizedContext(params: {
    userId: string;
    requestedClassLevel: string;
  }): Promise<AuthorizedTutorContext> {
    const userRef = this.firestore.collection("users").doc(params.userId);
    const profileRef = this.firestore.collection("student_profiles").doc(params.userId);
    const [userSnapshot, profileSnapshot] = await Promise.all([
      userRef.get(),
      profileRef.get(),
    ]);
    if (!userSnapshot.exists || !profileSnapshot.exists) {
      throw new AppError("failed-precondition", "A completed student profile is required.");
    }

    const scope = resolveTutorAcademicScope({
      requestedClassLevel: params.requestedClassLevel,
      userData: userSnapshot.data(),
      profileData: profileSnapshot.data(),
    });
    if (!isSafeDocumentId(scope.classLevel)) {
      throw new AppError("failed-precondition", "The stored class level is invalid.");
    }

    const progressSnapshot = await profileRef
      .collection("lessonProgress")
      .orderBy("updatedAt", "desc")
      .limit(8)
      .get();

    const candidates = progressSnapshot.docs
      .map((document) => document.data())
      .filter((progress) => progressBelongsToScope(progress, scope))
      .map((progress) => ({
        subjectId: normalizedString(progress.subjectId),
        chapterId: normalizedString(progress.chapterId),
        lessonId: normalizedString(progress.lessonId),
      }))
      .filter((progress) =>
        isSafeDocumentId(progress.subjectId) &&
        isSafeDocumentId(progress.chapterId) &&
        isSafeDocumentId(progress.lessonId)
      );

    const lessonSnapshots = await Promise.all(candidates.map((candidate) =>
      this.firestore
        .collection("classes")
        .doc(scope.classLevel)
        .collection("subjects")
        .doc(candidate.subjectId)
        .collection("chapters")
        .doc(candidate.chapterId)
        .collection("lessons")
        .doc(candidate.lessonId)
        .get()
    ));
    const authorizedLessons = lessonSnapshots
      .filter((snapshot) => snapshot.exists)
      .map((snapshot) => snapshot.data())
      .filter((lesson): lesson is DocumentData =>
        lesson !== undefined && lessonBelongsToTutorScope(lesson, scope)
      )
      .slice(0, MAX_CONTEXT_LESSONS);

    return {
      scope,
      text: renderTutorContext(authorizedLessons),
    };
  }
}

export class AskTutorUseCase {
  constructor(
    private readonly contextStore: TutorContextStore = new FirestoreTutorContextStore(),
    private readonly textGenerator: TutorTextGenerator = generateText,
    private readonly quotaStore: TutorQuotaStore = new FirestoreTutorQuotaStore(),
    private readonly dailyQuestionLimit: number = getEnv().TUTOR_DAILY_QUESTION_LIMIT,
  ) {}

  async execute(params: {
    userId: string;
    traceId: string;
    input: AskTutorCallableInput;
  }): Promise<{ text: string } & TutorQuotaSnapshot> {
    const { tutor, history, userMessage } = params.input;
    const authorizedContext = await this.contextStore.loadAuthorizedContext({
      userId: params.userId,
      requestedClassLevel: params.input.classLevel,
    });
    const historyText = history.map((item) => `${item.role}: ${item.text}`).join("\n");

    const systemPrompt = ASK_TUTOR_SYSTEM_PROMPT
      .replace("{TUTOR_NAME}", tutor.name)
      .replace("{TUTOR_SPECIALTY}", tutor.specialty)
      .replace("{TUTOR_PERSONALITY}", tutor.personality)
      .replace("{TUTOR_MOTTO}", tutor.motto);
    const userPrompt = buildAskTutorUserPrompt(
      authorizedContext.scope.classLevel,
      authorizedContext.text,
      historyText,
      userMessage,
    );
    try {
      await this.quotaStore.reserve({
        userId: params.userId,
        traceId: params.traceId,
        limit: this.dailyQuestionLimit,
      });
    } catch (error) {
      if (error instanceof AppError && error.code === "resource-exhausted") {
        logAiQuotaRejection({
          operation: "askTutor",
          correlationId: params.traceId,
        });
      }
      throw error;
    }
    try {
      const responseText = await this.textGenerator({
        operation: "askTutor",
        correlationId: params.traceId,
        system: systemPrompt,
        prompt: userPrompt,
      });
      const quota = await this.quotaStore.consume({
        userId: params.userId,
        traceId: params.traceId,
        limit: this.dailyQuestionLimit,
      });
      return { text: responseText, ...quota };
    } catch (error) {
      // Never log the prompt, user message or history. A failed generation does
      // not consume the student's daily allowance.
      await this.quotaStore.release({
        userId: params.userId,
        traceId: params.traceId,
      }).catch(() => undefined);
      throw error;
    }
  }
}

export function resolveTutorAcademicScope({
  requestedClassLevel,
  userData,
  profileData,
}: {
  requestedClassLevel: string;
  userData: DocumentData | undefined;
  profileData: DocumentData | undefined;
}): TutorAcademicScope {
  if (normalizedString(userData?.role) !== "student") {
    throw new AppError("permission-denied", "The tutor course context is reserved for students.");
  }
  const userClass = normalizedString(userData?.classLevel);
  const profileClass = normalizedString(profileData?.classLevel);
  if (userClass && profileClass && !sameAcademicValue(userClass, profileClass)) {
    throw new AppError("failed-precondition", "Student class data is inconsistent.");
  }
  const classLevel = profileClass || userClass;
  if (!classLevel) {
    throw new AppError("failed-precondition", "The student class level is missing.");
  }
  if (!sameAcademicValue(requestedClassLevel, classLevel)) {
    throw new AppError("permission-denied", "Requested class does not match the student profile.");
  }

  const userEstablishment = normalizedString(userData?.establishmentId);
  const profileEstablishment = normalizedString(profileData?.establishmentId);
  if (
    userEstablishment &&
    profileEstablishment &&
    userEstablishment !== profileEstablishment
  ) {
    throw new AppError("failed-precondition", "Student establishment data is inconsistent.");
  }

  return {
    classLevel,
    establishmentId: profileEstablishment || userEstablishment || null,
  };
}

export function lessonBelongsToTutorScope(
  lesson: DocumentData,
  scope: TutorAcademicScope,
): boolean {
  if (normalizedString(lesson.status) !== "published") {
    return false;
  }
  const lessonClass = normalizedString(lesson.classLevel);
  if (lessonClass && !sameAcademicValue(lessonClass, scope.classLevel)) {
    return false;
  }

  const lessonEstablishment = normalizedString(lesson.establishmentId);
  if (lessonEstablishment) {
    return Boolean(scope.establishmentId) &&
      lessonEstablishment === scope.establishmentId;
  }
  // Existing catalog lessons without an establishment are global. A lesson
  // explicitly marked as establishment-scoped must never fall back to global.
  return normalizedString(lesson.visibilityScope) !== "establishment";
}

function progressBelongsToScope(
  progress: DocumentData,
  scope: TutorAcademicScope,
): boolean {
  // Legacy client-written progress was not tied to a verified catalog lesson.
  // It is intentionally excluded instead of being used as a RAG pointer.
  if (Number(progress.authorizationVersion) !== 1) {
    return false;
  }
  const progressClass = normalizedString(progress.classLevel);
  if (!progressClass || !sameAcademicValue(progressClass, scope.classLevel)) {
    return false;
  }
  const contentScope = normalizedString(progress.contentScope);
  if (contentScope === "global") {
    return true;
  }
  return contentScope === "establishment" &&
    Boolean(scope.establishmentId) &&
    normalizedString(progress.establishmentId) === scope.establishmentId;
}

function renderTutorContext(lessons: DocumentData[]): string {
  const sections = lessons.map((lesson) => {
    const title = normalizedString(lesson.title) || "Sans titre";
    const contentSections = Array.isArray(lesson.contentSections)
      ? lesson.contentSections
      : [];
    const body = contentSections
      .filter((section): section is Record<string, unknown> =>
        Boolean(section) && typeof section === "object"
      )
      .map((section) => {
        const sectionTitle = normalizedString(section.title);
        const sectionBody = normalizedString(section.body);
        return `${sectionTitle}\n${sectionBody}`.trim();
      })
      .filter(Boolean)
      .join("\n");
    return `Titre de la leçon : ${title}\n${body}`.trim();
  });
  const context = sections.join("\n\n---\n\n");
  return context.length <= MAX_CONTEXT_CHARACTERS
    ? context
    : `${context.slice(0, MAX_CONTEXT_CHARACTERS)}…`;
}

function sameAcademicValue(left: string, right: string): boolean {
  return left.trim().toLocaleLowerCase("fr") === right.trim().toLocaleLowerCase("fr");
}

function normalizedString(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

function isSafeDocumentId(value: string): boolean {
  return value.length > 0 && value.length <= 128 && !value.includes("/");
}
