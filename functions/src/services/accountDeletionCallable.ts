import type { CallableRequest } from "firebase-functions/v2/https";
import { HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions";
import type { Auth } from "firebase-admin/auth";
import {
  FieldValue,
  Timestamp,
  type DocumentReference,
  type Firestore,
  type Query,
} from "firebase-admin/firestore";

import { db } from "../config/firebase";

/**
 * Suppression de compte demandée par son titulaire.
 * Politique complète : docs/architecture/ACCOUNT_DELETION.md.
 *
 * demande → délai de grâce (7 jours, annulable) → traitement serveur
 * idempotent → trace minimale. Rien n'est effacé au moment de la demande.
 */

export const ACCOUNT_DELETION_COLLECTION = "account_deletion_requests";
export const ACCOUNT_DELETION_GRACE_MS = 7 * 24 * 60 * 60 * 1000;
export const ACCOUNT_DELETION_LEASE_MS = 15 * 60 * 1000;
export const ACCOUNT_DELETION_RETRY_DELAYS_MS = [
  60 * 60 * 1000,
  6 * 60 * 60 * 1000,
  24 * 60 * 60 * 1000,
  72 * 60 * 60 * 1000,
] as const;
export const ACCOUNT_DELETION_MAX_ATTEMPTS = 5;

export type AccountDeletionStatus =
  | "scheduled"
  | "cancelled"
  | "processing"
  | "failed"
  | "needs_attention"
  | "completed";

/** États encore pris en charge par le traitement planifié. */
export const PROCESSABLE_STATUSES: readonly AccountDeletionStatus[] = [
  "scheduled",
  "failed",
  "processing",
];

/** Délai avant la tentative suivante, ou null quand il faut un humain. */
export function nextDeletionRetryDelay(attempts: number): number | null {
  if (attempts >= ACCOUNT_DELETION_MAX_ATTEMPTS) return null;
  return ACCOUNT_DELETION_RETRY_DELAYS_MS[
    Math.min(attempts - 1, ACCOUNT_DELETION_RETRY_DELAYS_MS.length - 1)
  ] ?? ACCOUNT_DELETION_RETRY_DELAYS_MS[0];
}

function normalized(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

function isSuperAdminRole(role: string): boolean {
  return role === "superAdmin" || role === "super_admin";
}

// ── Demande et annulation ─────────────────────────────────────────────────

export function createRequestAccountDeletionHandler(
  firestore: Firestore = db,
  now: () => number = () => Date.now(),
) {
  return async (request: CallableRequest<unknown>) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Firebase Auth is required.");
    }
    const user = (await firestore.collection("users").doc(uid).get()).data() ?? {};
    const role = normalized(user.role);
    if (isSuperAdminRole(role)) {
      throw new HttpsError(
        "failed-precondition",
        "A general administration account is deleted manually.",
        { reason: "super_admin_manual_deletion" },
      );
    }
    const ref = firestore.collection(ACCOUNT_DELETION_COLLECTION).doc(uid);
    const result = await firestore.runTransaction(async (transaction) => {
      const existing = (await transaction.get(ref)).data();
      const status = normalized(existing?.status) as AccountDeletionStatus | "";
      if (status && status !== "cancelled" && status !== "completed" && existing?.dueAt instanceof Timestamp) {
        // Demande déjà en cours : même réponse, même échéance.
        return { status, dueAt: existing.dueAt.toDate().toISOString(), created: false };
      }
      const dueAt = Timestamp.fromMillis(now() + ACCOUNT_DELETION_GRACE_MS);
      transaction.set(ref, {
        uid,
        role: role || "unknown",
        status: "scheduled",
        requestedAt: FieldValue.serverTimestamp(),
        dueAt,
        attempts: 0,
        lastErrorCode: null,
        updatedAt: FieldValue.serverTimestamp(),
      });
      return { status: "scheduled" as const, dueAt: dueAt.toDate().toISOString(), created: true };
    });
    if (result.created && role === "student") {
      await notifyGuardians(firestore, uid, result.dueAt).catch((error) => {
        logger.warn("Guardians could not be notified of a deletion request.", {
          error: error instanceof Error ? error.name : "unknown",
        });
      });
    }
    return { status: result.status, dueAt: result.dueAt };
  };
}

async function notifyGuardians(firestore: Firestore, studentId: string, dueAtIso: string) {
  const links = await firestore
    .collection("children_links")
    .where("studentId", "==", studentId)
    .get();
  const parentIds = [...new Set(
    links.docs
      .filter((link) => normalized(link.get("status")) === "approved")
      .map((link) => normalized(link.get("parentId")))
      .filter(Boolean),
  )];
  if (parentIds.length === 0) return;
  const batch = firestore.batch();
  for (const parentId of parentIds) {
    batch.set(
      firestore.collection("notifications").doc(`account_deletion_${studentId}_${parentId}`),
      {
        userId: parentId,
        type: "account_deletion_scheduled",
        title: "Suppression d’un compte élève",
        body: "Votre enfant a demandé la suppression de son compte INTELLIA237. Elle aura lieu dans 7 jours ; il peut l’annuler d’ici là.",
        data: { studentId, dueAt: dueAtIso },
        route: "/notifications",
        sourceId: `account_deletion_${studentId}`,
        createdAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  }
  await batch.commit();
}

export function createCancelAccountDeletionHandler(firestore: Firestore = db) {
  return async (request: CallableRequest<unknown>) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Firebase Auth is required.");
    }
    const ref = firestore.collection(ACCOUNT_DELETION_COLLECTION).doc(uid);
    return firestore.runTransaction(async (transaction) => {
      const existing = (await transaction.get(ref)).data();
      const status = normalized(existing?.status);
      if (status === "cancelled" || !existing) return { status: "cancelled" as const };
      if (status !== "scheduled") {
        throw new HttpsError(
          "failed-precondition",
          "Deletion has already started and can no longer be cancelled.",
          { reason: "account_deletion_in_progress" },
        );
      }
      transaction.update(ref, {
        status: "cancelled",
        cancelledAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
      return { status: "cancelled" as const };
    });
  };
}

// ── Traitement ────────────────────────────────────────────────────────────

export interface DeletionAuthPort {
  /** Désactive le compte et révoque ses jetons de rafraîchissement. */
  disable(uid: string): Promise<void>;
  /** Supprime le compte ; un compte déjà absent n'est pas une erreur. */
  deleteUser(uid: string): Promise<void>;
}

export interface DeletionStoragePort {
  /** Supprime tous les objets sous ce préfixe ; renvoie leur nombre. */
  deletePrefix(prefix: string): Promise<number>;
}

export class AdminDeletionAuthPort implements DeletionAuthPort {
  constructor(private readonly auth: Auth) {}
  async disable(uid: string): Promise<void> {
    try {
      await this.auth.updateUser(uid, { disabled: true });
      await this.auth.revokeRefreshTokens(uid);
    } catch (error) {
      if (!isUserNotFound(error)) throw error;
    }
  }
  async deleteUser(uid: string): Promise<void> {
    try {
      await this.auth.deleteUser(uid);
    } catch (error) {
      if (!isUserNotFound(error)) throw error;
    }
  }
}

function isUserNotFound(error: unknown): boolean {
  return typeof error === "object" && error !== null &&
    (error as { code?: unknown }).code === "auth/user-not-found";
}

/** Collections interrogées par champ : tout document de la personne. */
const OWNED_BY_FIELD: ReadonlyArray<{ collection: string; field: string }> = [
  { collection: "children_links", field: "studentId" },
  { collection: "children_links", field: "parentId" },
  { collection: "child_access_requests", field: "parentId" },
  { collection: "notifications", field: "userId" },
  { collection: "notification_devices", field: "userId" },
  { collection: "quiz_attempts", field: "studentId" },
  { collection: "progress", field: "studentId" },
  { collection: "recommendations", field: "studentId" },
  { collection: "flow_completions", field: "studentId" },
  { collection: "flow_events", field: "studentId" },
  { collection: "flow_daily_points", field: "studentId" },
  { collection: "student_link_codes", field: "studentId" },
  { collection: "ai_tutor_daily_usage", field: "userId" },
  { collection: "tutor_requests", field: "userId" },
  { collection: "ai_conversations", field: "userId" },
];

/** Documents identifiés par l'uid (sous-collections comprises). */
const OWNED_BY_ID: readonly string[] = [
  "student_profiles",
  "parent_profiles",
  "teacher_profiles",
  "admin_profiles",
  "settings",
  "streaks",
  "study_reserve",
  "pending_student_accounts",
  "link_attempts",
  "child_access_quotas",
];

export interface DeletionReport {
  documents: number;
  classesUpdated: number;
  storageObjects: number;
}

export class AccountDeletionProcessor {
  constructor(
    private readonly firestore: Firestore,
    private readonly auth: DeletionAuthPort,
    private readonly storage: DeletionStoragePort,
    private readonly now: () => number = () => Date.now(),
  ) {}

  private requests() {
    return this.firestore.collection(ACCOUNT_DELETION_COLLECTION);
  }

  /** Traite les demandes arrivées à échéance ; renvoie le nombre traité. */
  async processDue(limit = 20): Promise<{ completed: number; failed: number }> {
    const due = await this.requests()
      .where("status", "in", [...PROCESSABLE_STATUSES])
      .where("dueAt", "<=", Timestamp.fromMillis(this.now()))
      .orderBy("dueAt")
      .limit(limit)
      .get();
    let completed = 0;
    let failed = 0;
    for (const document of due.docs) {
      const outcome = await this.processOne(document.id);
      if (outcome === "completed") completed += 1;
      if (outcome === "failed" || outcome === "needs_attention") failed += 1;
    }
    return { completed, failed };
  }

  async processOne(uid: string): Promise<AccountDeletionStatus | "skipped"> {
    const ref = this.requests().doc(uid);
    const claimed = await this.firestore.runTransaction(async (transaction) => {
      const data = (await transaction.get(ref)).data();
      const status = normalized(data?.status) as AccountDeletionStatus;
      const dueAt = data?.dueAt instanceof Timestamp ? data.dueAt.toMillis() : Number.POSITIVE_INFINITY;
      if (!PROCESSABLE_STATUSES.includes(status) || dueAt > this.now()) return null;
      const attempts = Number(data?.attempts ?? 0) + 1;
      // Le bail est porté par dueAt : une exécution tuée est reprise après lui.
      transaction.update(ref, {
        status: "processing",
        attempts,
        dueAt: Timestamp.fromMillis(this.now() + ACCOUNT_DELETION_LEASE_MS),
        processingStartedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
      return { attempts, role: normalized(data?.role) };
    });
    if (claimed === null) return "skipped";

    try {
      const report = await this.erase(uid, claimed.role);
      await ref.update({
        status: "completed",
        completedAt: FieldValue.serverTimestamp(),
        report,
        lastErrorCode: null,
        dueAt: FieldValue.delete(),
        updatedAt: FieldValue.serverTimestamp(),
      });
      return "completed";
    } catch (error) {
      const delay = nextDeletionRetryDelay(claimed.attempts);
      const status: AccountDeletionStatus = delay === null ? "needs_attention" : "failed";
      // Un code, jamais un message : il pourrait citer une donnée personnelle.
      const code = typeof (error as { code?: unknown })?.code === "string"
        ? String((error as { code: string }).code).slice(0, 60)
        : error instanceof Error ? error.name.slice(0, 60) : "unknown";
      await ref.update({
        status,
        lastErrorCode: code,
        dueAt: delay === null ? FieldValue.delete() : Timestamp.fromMillis(this.now() + delay),
        updatedAt: FieldValue.serverTimestamp(),
      });
      // Aucun identifiant dans le journal : la demande porte l'état complet.
      logger.error("Account deletion step failed.", { status, code });
      return status;
    }
  }

  /** Étapes dans l'ordre de la politique ; chacune est rejouable. */
  async erase(uid: string, role: string): Promise<DeletionReport> {
    if (isSuperAdminRole(role)) {
      throw Object.assign(new Error("Super administrators are deleted manually."), {
        code: "super_admin_manual_deletion",
      });
    }
    // (a) Plus aucune nouvelle session, et les règles refusent tout de suite.
    await this.auth.disable(uid);
    await this.firestore.collection("users").doc(uid).set({
      uid,
      role: role || "unknown",
      accountStatus: "deleted",
      deletedAt: FieldValue.serverTimestamp(),
    });

    // (b) Firestore.
    let documents = 0;
    for (const { collection, field } of OWNED_BY_FIELD) {
      documents += await this.deleteQuery(this.firestore.collection(collection).where(field, "==", uid));
    }
    const credential = await this.firestore.collection("student_access_credentials").doc(uid).get();
    const lookupKey = normalized(credential.get("lookupKey"));
    if (lookupKey) {
      await this.firestore.collection("student_access_codes").doc(lookupKey).delete();
      documents += 1;
    }
    if (credential.exists) {
      await credential.ref.delete();
      documents += 1;
    }
    for (const collection of OWNED_BY_ID) {
      const ref = this.firestore.collection(collection).doc(uid);
      if ((await ref.get()).exists || (await ref.listCollections()).length > 0) {
        await this.firestore.recursiveDelete(ref);
        documents += 1;
      }
    }
    const classesUpdated = await this.removeFromClasses(uid);

    // (c) Storage.
    const storageObjects = await this.storage.deletePrefix(`avatars/${uid}/`);

    // (d) Auth, en dernier.
    await this.auth.deleteUser(uid);
    return { documents, classesUpdated, storageObjects };
  }

  private async deleteQuery(query: Query): Promise<number> {
    let deleted = 0;
    for (;;) {
      const page = await query.limit(400).get();
      if (page.empty) return deleted;
      const batch = this.firestore.batch();
      for (const document of page.docs) batch.delete(document.ref);
      await batch.commit();
      deleted += page.size;
      if (page.size < 400) return deleted;
    }
  }

  private async removeFromClasses(uid: string): Promise<number> {
    const refs = new Map<string, DocumentReference>();
    for (const field of ["studentIds", "teacherIds"]) {
      const snapshot = await this.firestore.collection("classes").where(field, "array-contains", uid).get();
      for (const document of snapshot.docs) refs.set(document.id, document.ref);
    }
    const main = await this.firestore.collection("classes").where("mainTeacherId", "==", uid).get();
    for (const document of main.docs) refs.set(document.id, document.ref);
    for (const ref of refs.values()) {
      const snapshot = await ref.get();
      await ref.update({
        studentIds: FieldValue.arrayRemove(uid),
        teacherIds: FieldValue.arrayRemove(uid),
        ...(normalized(snapshot.get("mainTeacherId")) === uid ? { mainTeacherId: null } : {}),
        updatedAt: FieldValue.serverTimestamp(),
      });
    }
    return refs.size;
  }
}

export const requestAccountDeletionHandler = createRequestAccountDeletionHandler();
export const cancelAccountDeletionHandler = createCancelAccountDeletionHandler();
