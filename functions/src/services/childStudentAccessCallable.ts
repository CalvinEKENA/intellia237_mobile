import { getAuth, type Auth } from "firebase-admin/auth";
import { FieldValue, type Firestore } from "firebase-admin/firestore";
import { logger } from "firebase-functions";
import { HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import { z } from "zod";

import { db } from "../config/firebase";
import {
  FirestoreStudentAccessStore,
  issueStudentAccessCode,
  type StudentAccessStore,
} from "./studentAccessCode";
import { hasUserRole, resolveUserRoles } from "../auth/userRoles";

/**
 * Nouvelle famille, enfant sans téléphone : le parent ouvre l'accès INTELLIA
 * de son enfant.
 *
 * Aucun numéro n'est demandé à l'enfant. Le serveur crée une identité élève
 * sans téléphone ni e-mail, la relie au parent (lien approuvé : c'est le
 * parent qui la crée) et émet son code d'accès, renvoyé une seule fois.
 * L'enfant complète lui-même son profil scolaire (école, classe) à sa
 * première connexion : le parent ne choisit jamais d'école à sa place.
 *
 * Garde-fous : rôle parent actif, idempotence par `requestId` (une réponse
 * perdue ne crée pas un second enfant), plafond de créations par parent.
 */

export const childAccessCreationLimit = { perWindow: 5, windowMs: 24 * 60 * 60 * 1000 };

const createInput = z
  .object({
    firstName: z.string().trim().min(1).max(60),
    requestId: z.string().uuid(),
  })
  .strict();

export interface ChildAccessCreationStore {
  readParent(uid: string): Promise<{ role: string; accountStatus: string } | null>;
  /** Réserve la création : null si le plafond est atteint ; `existing` si rejouée. */
  reserve(params: {
    parentId: string;
    requestId: string;
    candidateStudentId: string;
    firstName: string;
    nowMs: number;
  }): Promise<{ studentId: string; replay: boolean; completed: boolean } | null>;
  /** Lien approuvé et fiche d'attente, en une transaction. */
  linkPendingChild(params: { parentId: string; studentId: string; firstName: string }): Promise<void>;
  complete(params: { parentId: string; requestId: string }): Promise<void>;
}

export interface ChildIdentityPort {
  /** Crée l'identité élève sans téléphone ; idempotent pour le même UID. */
  createStudentIdentity(uid: string, displayName: string): Promise<void>;
}

export function createCreateChildStudentAccessHandler(deps: {
  pepper: () => string;
  store: ChildAccessCreationStore;
  access: StudentAccessStore;
  identities: ChildIdentityPort;
  newUid?: () => string;
  now?: () => number;
}) {
  const newUid = deps.newUid ?? (() => db.collection("users").doc().id);
  const now = deps.now ?? (() => Date.now());

  return async (
    request: CallableRequest<unknown>,
  ): Promise<{ studentId: string; firstName: string; code: string | null }> => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Firebase Auth is required.");
    const parsed = createInput.safeParse(request.data);
    if (!parsed.success) throw new HttpsError("invalid-argument", "Invalid request payload.");
    const parent = await deps.store.readParent(uid);
    if (!parent || !hasUserRole(parent, "parent") || parent.accountStatus !== "active") {
      throw new HttpsError("permission-denied", "Only a parent can open a child's access.");
    }

    const reservation = await deps.store.reserve({
      parentId: uid,
      requestId: parsed.data.requestId,
      candidateStudentId: newUid(),
      firstName: parsed.data.firstName,
      nowMs: now(),
    });
    if (!reservation) {
      throw new HttpsError("resource-exhausted", "Too many child accesses created today.");
    }
    if (reservation.replay && reservation.completed) {
      // Le code n'est pas stocké : le parent en génère un nouveau si besoin.
      return { studentId: reservation.studentId, firstName: parsed.data.firstName, code: null };
    }

    await deps.identities.createStudentIdentity(reservation.studentId, parsed.data.firstName);
    await deps.store.linkPendingChild({
      parentId: uid,
      studentId: reservation.studentId,
      firstName: parsed.data.firstName,
    });
    const { code } = await issueStudentAccessCode(deps.access, deps.pepper(), {
      studentId: reservation.studentId,
      actorUid: uid,
      actorRole: "parent",
    });
    await deps.store.complete({ parentId: uid, requestId: parsed.data.requestId });
    logger.info("Parent opened a child's student access.", {
      parentId: uid,
      studentId: reservation.studentId,
    });
    return { studentId: reservation.studentId, firstName: parsed.data.firstName, code };
  };
}

export class FirestoreChildAccessCreationStore implements ChildAccessCreationStore {
  constructor(private readonly firestore: Firestore = db) {}

  async readParent(uid: string) {
    const snapshot = await this.firestore.collection("users").doc(uid).get();
    if (!snapshot.exists) return null;
    const data = snapshot.data() ?? {};
    return {
      role: typeof data.role === "string" ? data.role : "",
      roles: [...resolveUserRoles(data)],
      accountStatus: typeof data.accountStatus === "string" ? data.accountStatus : "active",
    };
  }

  async reserve(params: {
    parentId: string;
    requestId: string;
    candidateStudentId: string;
    firstName: string;
    nowMs: number;
  }) {
    const requestRef = this.firestore
      .collection("child_access_requests")
      .doc(`${params.parentId}_${params.requestId}`);
    const quotaRef = this.firestore.collection("child_access_quotas").doc(params.parentId);
    return this.firestore.runTransaction(async (transaction) => {
      const [existing, quota] = await Promise.all([
        transaction.get(requestRef),
        transaction.get(quotaRef),
      ]);
      if (existing.exists) {
        return {
          studentId: String(existing.data()?.studentId ?? ""),
          replay: true,
          completed: existing.data()?.status === "completed",
        };
      }
      const windowStartMs =
        typeof quota.data()?.windowStartMs === "number" ? (quota.data()?.windowStartMs as number) : 0;
      const inWindow = params.nowMs - windowStartMs < childAccessCreationLimit.windowMs;
      const count = inWindow ? Number(quota.data()?.count ?? 0) : 0;
      if (count >= childAccessCreationLimit.perWindow) return null;
      transaction.set(quotaRef, {
        windowStartMs: inWindow ? windowStartMs : params.nowMs,
        count: count + 1,
        updatedAt: FieldValue.serverTimestamp(),
      });
      transaction.create(requestRef, {
        parentId: params.parentId,
        studentId: params.candidateStudentId,
        status: "started",
        createdAt: FieldValue.serverTimestamp(),
      });
      return { studentId: params.candidateStudentId, replay: false, completed: false };
    });
  }

  async linkPendingChild(params: { parentId: string; studentId: string; firstName: string }) {
    const batch = this.firestore.batch();
    batch.set(
      this.firestore.collection("children_links").doc(`${params.parentId}_${params.studentId}`),
      {
        parentId: params.parentId,
        studentId: params.studentId,
        status: "approved",
        linkedVia: "parent_created_access",
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    batch.set(
      this.firestore.collection("pending_student_accounts").doc(params.studentId),
      {
        studentId: params.studentId,
        firstName: params.firstName,
        createdBy: params.parentId,
        createdAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    await batch.commit();
  }

  async complete(params: { parentId: string; requestId: string }) {
    await this.firestore
      .collection("child_access_requests")
      .doc(`${params.parentId}_${params.requestId}`)
      .update({ status: "completed", completedAt: FieldValue.serverTimestamp() });
  }
}

export class AdminChildIdentityPort implements ChildIdentityPort {
  constructor(private readonly auth: () => Auth = () => getAuth()) {}

  async createStudentIdentity(uid: string, displayName: string): Promise<void> {
    try {
      await this.auth().createUser({ uid, displayName });
    } catch (error) {
      const code = error && typeof error === "object" && "code" in error ? String(error.code) : "";
      if (code !== "auth/uid-already-exists") throw error;
    }
  }
}

export function createDefaultCreateChildStudentAccessHandler(pepper: () => string) {
  return createCreateChildStudentAccessHandler({
    pepper,
    store: new FirestoreChildAccessCreationStore(),
    access: new FirestoreStudentAccessStore(),
    identities: new AdminChildIdentityPort(),
  });
}
