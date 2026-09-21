import { createHash } from "node:crypto";

import { FieldValue, Timestamp, type Firestore } from "firebase-admin/firestore";

import { db } from "../config/firebase";
import { AppError } from "../utils/errors";

/**
 * Idempotence d'une question au tuteur.
 *
 * Le téléphone génère un `requestId` par question logique et le réutilise s'il
 * relance après un délai dépassé ou une coupure réseau. Le serveur tient un
 * registre court (`tutor_requests/{uid}__{requestId}`) pour qu'une relance :
 * - renvoie la réponse déjà produite, sans nouvel appel Gemini ni quota ;
 * - attende la première exécution si elle est encore en cours ;
 * - ne réserve jamais deux fois le quota quotidien ni la Réserve d'étude.
 *
 * Bornes :
 * - un enregistrement vit 15 minutes (`expireAt`, politique TTL Firestore à
 *   activer ; au-delà, il est de toute façon ignoré) ;
 * - au plus 2 exécutions par identifiant, pour qu'une relance après échec reste
 *   possible sans ouvrir une boucle gratuite ;
 * - la réponse conservée est le texte du compagnon, jamais la question de
 *   l'élève : seule une empreinte de la question est stockée, pour refuser la
 *   réutilisation d'un identifiant avec un autre message.
 */

export const TUTOR_REQUEST_RETENTION_MS = 15 * 60 * 1000;
export const TUTOR_REQUEST_MAX_EXECUTIONS = 2;
export const TUTOR_REQUEST_COLLECTION = "tutor_requests";
export const TUTOR_REQUEST_IN_PROGRESS_REASON = "tutor_request_in_progress";
export const TUTOR_REQUEST_RETRY_LIMIT_REASON = "tutor_request_retry_limit";

export interface CachedTutorResponse {
  text: string;
  limit: number;
  remaining: number;
  resetsAt: string;
  /** Bloc interactif validé, rejoué tel quel en cas de relance. */
  block?: Record<string, unknown>;
}

export interface TutorRequestRecord {
  state: "running" | "completed" | "failed";
  payloadHash: string;
  executions: number;
  leaseUntilMs: number;
  quotaCharged: boolean;
  expireAtMs: number;
  response?: CachedTutorResponse;
}

export type TutorRequestClaim =
  | { kind: "execute"; quotaAlreadyCharged: boolean; record: TutorRequestRecord }
  | { kind: "completed"; response: CachedTutorResponse }
  | { kind: "in_progress" };

/** Empreinte de la question logique : même identifiant ⇒ même question. */
export function tutorRequestPayloadHash(input: {
  tutorId: string;
  classLevel: string;
  userMessage: string;
}): string {
  return createHash("sha256")
    .update(`${input.tutorId}\u0000${input.classLevel}\u0000${input.userMessage}`)
    .digest("hex");
}

/**
 * Décision pure, testée sans Firestore : que faire d'une requête compte tenu
 * de l'enregistrement existant.
 */
export function decideTutorRequestClaim(params: {
  existing: TutorRequestRecord | null;
  payloadHash: string;
  nowMs: number;
  leaseMs: number;
}): { claim: TutorRequestClaim; next: TutorRequestRecord | null } {
  const { existing, payloadHash, nowMs, leaseMs } = params;
  const fresh = (): TutorRequestRecord => ({
    state: "running",
    payloadHash,
    executions: 1,
    leaseUntilMs: nowMs + leaseMs,
    quotaCharged: false,
    expireAtMs: nowMs + TUTOR_REQUEST_RETENTION_MS,
  });

  if (existing === null || existing.expireAtMs <= nowMs) {
    const next = fresh();
    return { claim: { kind: "execute", quotaAlreadyCharged: false, record: next }, next };
  }
  if (existing.payloadHash !== payloadHash) {
    throw new AppError(
      "invalid-argument",
      "This request identifier was already used for another question.",
    );
  }
  if (existing.state === "completed" && existing.response) {
    return { claim: { kind: "completed", response: existing.response }, next: null };
  }
  if (existing.state === "running" && existing.leaseUntilMs > nowMs) {
    return { claim: { kind: "in_progress" }, next: null };
  }
  if (existing.executions >= TUTOR_REQUEST_MAX_EXECUTIONS) {
    throw new AppError(
      "failed-precondition",
      "This question cannot be retried again; ask it once more.",
      { reason: TUTOR_REQUEST_RETRY_LIMIT_REASON },
    );
  }
  const next: TutorRequestRecord = {
    ...existing,
    state: "running",
    executions: existing.executions + 1,
    leaseUntilMs: nowMs + leaseMs,
  };
  return {
    claim: { kind: "execute", quotaAlreadyCharged: existing.quotaCharged, record: next },
    next,
  };
}

export interface TutorRequestLedger {
  claim(params: {
    userId: string;
    requestId: string;
    payloadHash: string;
    leaseMs: number;
  }): Promise<TutorRequestClaim>;
  complete(params: {
    userId: string;
    requestId: string;
    response: CachedTutorResponse;
  }): Promise<void>;
  fail(params: {
    userId: string;
    requestId: string;
    quotaCharged: boolean;
  }): Promise<void>;
  read(params: { userId: string; requestId: string }): Promise<TutorRequestRecord | null>;
}

export function tutorRequestDocumentId(userId: string, requestId: string): string {
  return `${userId}__${requestId}`;
}

function recordFrom(data: FirebaseFirestore.DocumentData | undefined): TutorRequestRecord | null {
  if (!data) return null;
  const state = data.state;
  if (state !== "running" && state !== "completed" && state !== "failed") return null;
  const expireAt = data.expireAt instanceof Timestamp ? data.expireAt.toMillis() : Number(data.expireAtMs ?? 0);
  const response = data.response && typeof data.response.text === "string"
    ? {
      text: String(data.response.text),
      limit: Number(data.response.limit ?? 0),
      remaining: Number(data.response.remaining ?? 0),
      resetsAt: String(data.response.resetsAt ?? ""),
      ...(data.response.block && typeof data.response.block === "object"
        ? { block: data.response.block as Record<string, unknown> }
        : {}),
    }
    : undefined;
  return {
    state,
    payloadHash: String(data.payloadHash ?? ""),
    executions: Number(data.executions ?? 0),
    leaseUntilMs: Number(data.leaseUntilMs ?? 0),
    quotaCharged: data.quotaCharged === true,
    expireAtMs: expireAt,
    ...(response ? { response } : {}),
  };
}

export class FirestoreTutorRequestLedger implements TutorRequestLedger {
  constructor(
    private readonly firestore: Firestore = db,
    private readonly now: () => number = () => Date.now(),
  ) {}

  private ref(userId: string, requestId: string) {
    return this.firestore
      .collection(TUTOR_REQUEST_COLLECTION)
      .doc(tutorRequestDocumentId(userId, requestId));
  }

  async claim(params: {
    userId: string;
    requestId: string;
    payloadHash: string;
    leaseMs: number;
  }): Promise<TutorRequestClaim> {
    const ref = this.ref(params.userId, params.requestId);
    return this.firestore.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(ref);
      const { claim, next } = decideTutorRequestClaim({
        existing: recordFrom(snapshot.data()),
        payloadHash: params.payloadHash,
        nowMs: this.now(),
        leaseMs: params.leaseMs,
      });
      if (next !== null) {
        transaction.set(ref, {
          userId: params.userId,
          requestId: params.requestId,
          state: next.state,
          payloadHash: next.payloadHash,
          executions: next.executions,
          leaseUntilMs: next.leaseUntilMs,
          quotaCharged: next.quotaCharged,
          expireAt: Timestamp.fromMillis(next.expireAtMs),
          updatedAt: FieldValue.serverTimestamp(),
        });
      }
      return claim;
    });
  }

  async complete(params: {
    userId: string;
    requestId: string;
    response: CachedTutorResponse;
  }): Promise<void> {
    await this.ref(params.userId, params.requestId).set(
      {
        state: "completed",
        quotaCharged: true,
        response: params.response,
        leaseUntilMs: 0,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  }

  async fail(params: {
    userId: string;
    requestId: string;
    quotaCharged: boolean;
  }): Promise<void> {
    await this.ref(params.userId, params.requestId).set(
      {
        state: "failed",
        quotaCharged: params.quotaCharged,
        leaseUntilMs: 0,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  }

  async read(params: { userId: string; requestId: string }): Promise<TutorRequestRecord | null> {
    return recordFrom((await this.ref(params.userId, params.requestId).get()).data());
  }
}
