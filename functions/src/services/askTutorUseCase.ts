import type { DocumentData, Firestore } from "firebase-admin/firestore";

import { db } from "../config/firebase";
import { getEnv } from "../config/env";
import { generateText, logAiQuotaRejection, type LlmTokenUsage } from "../llm/llmClient";
import { buildAskTutorUserPrompt } from "../llm/prompts";
import {
  MAX_ACADEMIC_CONTEXT_CHARS,
  MAX_TOTAL_INPUT_CHARS,
  MAX_TUTOR_OUTPUT_TOKENS,
  boundTutorHistory,
  type TutorHistoryItem,
} from "../llm/tutorBudget";
import {
  buildTutorSystemPrompt,
  resolveTutorLanguage,
  type TutorLanguage,
} from "../llm/tutorPersonas";
import {
  buildActivityInstructions,
  extractInteractiveBlock,
  negotiateActivityTypes,
  renderActivityOutcome,
  type InteractiveBlock,
} from "../llm/interactiveBlocks";
import {
  ASK_TUTOR_CALLABLE_TIMEOUT_SECONDS,
  TUTOR_IN_PROGRESS_POLL_MS,
  TUTOR_IN_PROGRESS_WAIT_MS,
  TUTOR_PROVIDER_TIMEOUT_MS,
} from "../config/timeouts";
import { AppError } from "../utils/errors";
import type { AskTutorCallableInput } from "../utils/validation";
import {
  FirestoreTutorQuotaStore,
  type TutorQuotaSnapshot,
  type TutorQuotaStore,
} from "./tutorDailyQuota";
import {
  BilledProviderFailure,
  StudyReserveConsumption,
  billableFromUsage,
} from "./studyReserveConsumption";
import {
  FirestoreTutorRequestLedger,
  TUTOR_REQUEST_IN_PROGRESS_REASON,
  tutorRequestPayloadHash,
  type TutorRequestLedger,
} from "./tutorRequestLedger";

const MAX_CONTEXT_LESSONS = 3;
const MAX_CONTEXT_CHARACTERS = MAX_ACADEMIC_CONTEXT_CHARS;

export interface TutorAcademicScope {
  classLevel: string;
  establishmentId: string | null;
}

export interface AuthorizedTutorContext {
  scope: TutorAcademicScope;
  text: string;
  /** Langue d'enseignement décidée depuis le profil ; français par défaut. */
  language?: TutorLanguage;
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
  maxOutputTokens?: number;
  timeoutMs?: number;
  onUsage?: (usage: LlmTokenUsage | undefined) => void;
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
      language: resolveTutorLanguage(profileSnapshot.data()),
    };
  }
}

export class AskTutorUseCase {
  constructor(
    private readonly contextStore: TutorContextStore = new FirestoreTutorContextStore(),
    private readonly textGenerator: TutorTextGenerator = generateText,
    private readonly quotaStore: TutorQuotaStore = new FirestoreTutorQuotaStore(),
    private readonly dailyQuestionLimit: number = getEnv().TUTOR_DAILY_QUESTION_LIMIT,
    // Couche de consommation unique de la Réserve d'étude (réserve/commit/release
    // + comptabilisation de l'usage réel + seuils). Centralisée ici.
    private readonly studyReserve: StudyReserveConsumption = new StudyReserveConsumption(),
    // Registre d'idempotence : une relance avec le même requestId ne rejoue
    // ni Gemini, ni le quota, ni la Réserve d'étude.
    private readonly requestLedger: TutorRequestLedger = new FirestoreTutorRequestLedger(),
    private readonly sleep: (ms: number) => Promise<void> = (ms) =>
      new Promise((resolve) => setTimeout(resolve, ms)),
  ) {}

  async execute(params: {
    userId: string;
    traceId: string;
    input: AskTutorCallableInput;
  }): Promise<TutorAnswer> {
    const requestId = params.input.requestId;
    if (requestId === undefined) {
      // Anciennes versions : pas d'identifiant, donc pas d'idempotence.
      return this.generate({ ...params, requestKey: params.traceId, quotaAlreadyCharged: false });
    }

    let billedFailure = false;
    const claim = await this.requestLedger.claim({
      userId: params.userId,
      requestId,
      payloadHash: tutorRequestPayloadHash(params.input),
      // Le bail couvre toute la vie de la callable : passé ce délai, une
      // exécution tuée ne bloque plus la relance.
      leaseMs: ASK_TUTOR_CALLABLE_TIMEOUT_SECONDS * 1_000,
    });
    if (claim.kind === "completed") return claim.response;
    if (claim.kind === "in_progress") {
      return this.awaitRunningRequest(params.userId, requestId);
    }

    try {
      const response = await this.generate({
        ...params,
        requestKey: requestId,
        quotaAlreadyCharged: claim.quotaAlreadyCharged,
        onBilledFailure: () => {
          billedFailure = true;
        },
      });
      await this.requestLedger
        .complete({ userId: params.userId, requestId, response })
        .catch(() => undefined);
      return response;
    } catch (error) {
      await this.requestLedger
        .fail({
          userId: params.userId,
          requestId,
          quotaCharged: claim.quotaAlreadyCharged || billedFailure,
        })
        .catch(() => undefined);
      throw error;
    }
  }

  /** Une relance attend la première exécution, sans rien relancer. */
  private async awaitRunningRequest(
    userId: string,
    requestId: string,
  ): Promise<TutorAnswer> {
    const deadline = Date.now() + TUTOR_IN_PROGRESS_WAIT_MS;
    while (Date.now() < deadline) {
      await this.sleep(TUTOR_IN_PROGRESS_POLL_MS);
      const record = await this.requestLedger.read({ userId, requestId });
      if (record?.state === "completed" && record.response) return record.response;
      if (record === null || record.state === "failed") break;
    }
    throw new AppError(
      "unavailable",
      "The answer to this question is still being prepared.",
      { reason: TUTOR_REQUEST_IN_PROGRESS_REASON },
    );
  }

  private async generate(params: {
    userId: string;
    traceId: string;
    input: AskTutorCallableInput;
    requestKey: string;
    quotaAlreadyCharged: boolean;
    onBilledFailure?: () => void;
  }): Promise<TutorAnswer> {
    const { tutorId, history, userMessage } = params.input;
    const authorizedContext = await this.contextStore.loadAuthorizedContext({
      userId: params.userId,
      requestedClassLevel: params.input.classLevel,
    });
    const language = authorizedContext.language ?? "fr";
    // Le serveur choisit seul la persona et ses règles : le téléphone ne
    // transmet qu'un identifiant déjà validé (kira | leo).
    // Activités : seulement les types que ce téléphone sait rendre ET que le
    // serveur sait valider. Un ancien client n'en déclare aucun.
    const activityTypes = negotiateActivityTypes(params.input.activities);
    const systemPrompt = buildTutorSystemPrompt(tutorId, language, {
      activityInstructions: buildActivityInstructions(activityTypes, language),
    });
    const userPrompt = assembleBoundedUserPrompt({
      systemPrompt,
      classLevel: authorizedContext.scope.classLevel,
      contextText: authorizedContext.text,
      history,
      userMessage,
      language,
      activityOutcome: params.input.activityOutcome
        ? renderActivityOutcome(params.input.activityOutcome, language)
        : undefined,
    });
    // Journée de la réservation : la question lui appartient jusqu'au bout,
    // même si la réponse arrive après minuit (Africa/Douala).
    let quotaDayKey: string | undefined;
    try {
      if (!params.quotaAlreadyCharged) {
        const reservation = await this.quotaStore.reserve({
          userId: params.userId,
          traceId: params.requestKey,
          limit: this.dailyQuestionLimit,
        });
        quotaDayKey = reservation.dayKey;
      }
    } catch (error) {
      if (error instanceof AppError && error.code === "resource-exhausted") {
        logAiQuotaRejection({
          operation: "askTutor",
          correlationId: params.traceId,
        });
      }
      throw error;
    }
    // Vrai dès que le fournisseur a pu produire (et facturer) une réponse :
    // réponse reçue mais inutilisable, ou délai dépassé côté serveur.
    let providerMayHaveBilled = false;
    try {
      // La Réserve d'étude encadre l'appel modèle : réservation (concurrence),
      // exécution, puis comptabilisation de l'usage RÉEL du fournisseur, une
      // seule fois (idempotent sur traceId). Réserve vide → rejet ; contenu
      // statique jamais affecté (ce chemin ne concerne que le tuteur).
      const { result: responseText } = await this.studyReserve.run(
        {
          studentId: params.userId,
          requestId: params.requestKey,
          provider: "vertex-ai",
          model: getEnv().GEMINI_MODEL,
        },
        async () => {
          let captured: LlmTokenUsage | undefined;
          try {
            const text = await this.textGenerator({
              operation: "askTutor",
              correlationId: params.traceId,
              system: systemPrompt,
              prompt: userPrompt,
              maxOutputTokens: MAX_TUTOR_OUTPUT_TOKENS,
              timeoutMs: tutorProviderTimeoutMs(),
              onUsage: (usage) => {
                captured = usage;
              },
            });
            return { result: text, usage: billableFromUsage(captured ?? {}) };
          } catch (error) {
            if (captured !== undefined) {
              providerMayHaveBilled = true;
              throw new BilledProviderFailure(billableFromUsage(captured), error);
            }
            if (error instanceof AppError && error.code === "deadline-exceeded") {
              // Annuler la requête HTTP n'annule pas le calcul du fournisseur.
              providerMayHaveBilled = true;
            }
            throw error;
          }
        },
      );
      // Idempotent : une clé déjà consommée n'est pas recomptée.
      const quota = await this.quotaStore.consume({
        userId: params.userId,
        traceId: params.requestKey,
        limit: this.dailyQuestionLimit,
        dayKey: quotaDayKey,
      });
      // Le bloc éventuel est validé ici ; invalide, il est retiré et seule la
      // réponse texte est servie.
      const { text, block } = extractInteractiveBlock(responseText, {
        allowed: activityTypes,
        language,
      });
      return { text, ...quota, ...(block ? { block } : {}) };
    } catch (error) {
      // Never log the prompt, user message or history. A generation that
      // provably did not reach the provider does not consume the daily
      // allowance; one the provider may have billed does, so an unusable or
      // timed-out answer can never be replayed for free.
      if (providerMayHaveBilled) {
        params.onBilledFailure?.();
        await this.quotaStore.consume({
          userId: params.userId,
          traceId: params.requestKey,
          limit: this.dailyQuestionLimit,
          dayKey: quotaDayKey,
        }).catch(() => undefined);
      } else if (!params.quotaAlreadyCharged) {
        await this.quotaStore.release({
          userId: params.userId,
          traceId: params.requestKey,
          dayKey: quotaDayKey,
        }).catch(() => undefined);
      }
      throw error;
    }
  }
}

/** Réponse du tuteur : texte, quota, et au plus un bloc interactif validé. */
export type TutorAnswer = { text: string } & TutorQuotaSnapshot & {
  block?: InteractiveBlock | Record<string, unknown>;
};

function tutorProviderTimeoutMs(): number {
  return Math.min(getEnv().LLM_SERVICE_TIMEOUT_MS, TUTOR_PROVIDER_TIMEOUT_MS);
}

/**
 * Prompt utilisateur borné : fenêtre d'historique, puis contrôle du total
 * (système compris). Si le total dépasse encore le plafond, l'historique est
 * réduit, puis le contexte ; la question de l'élève n'est jamais coupée.
 */
export function assembleBoundedUserPrompt(params: {
  systemPrompt: string;
  classLevel: string;
  contextText: string;
  history: readonly TutorHistoryItem[];
  userMessage: string;
  language: TutorLanguage;
  activityOutcome?: string;
}): string {
  let window = boundTutorHistory(params.history);
  let contextText = params.contextText.slice(0, MAX_ACADEMIC_CONTEXT_CHARS);
  const render = () => buildAskTutorUserPrompt({
    classLevel: params.classLevel,
    contextText,
    historyText: window
      .map((item) => `${historyLabel(item.role, params.language)} : ${item.text}`)
      .join("\n"),
    userMessage: params.userMessage,
    language: params.language,
    activityOutcome: params.activityOutcome,
  });
  let prompt = render();
  while (params.systemPrompt.length + prompt.length > MAX_TOTAL_INPUT_CHARS && window.length > 0) {
    window = window.slice(1);
    prompt = render();
  }
  if (params.systemPrompt.length + prompt.length > MAX_TOTAL_INPUT_CHARS) {
    const excess = params.systemPrompt.length + prompt.length - MAX_TOTAL_INPUT_CHARS;
    contextText = contextText.slice(0, Math.max(0, contextText.length - excess - 1));
    prompt = render();
  }
  return prompt;
}

function historyLabel(role: TutorHistoryItem["role"], language: TutorLanguage): string {
  if (language === "en") return role === "user" ? "Learner" : "Companion";
  return role === "user" ? "Élève" : "Compagnon";
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
