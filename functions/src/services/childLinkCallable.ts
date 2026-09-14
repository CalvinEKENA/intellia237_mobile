import type { CallableRequest } from "firebase-functions/v2/https";
import { HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";

import { db } from "../config/firebase";

/**
 * Liaison parent ↔ enfant, autoritaire côté serveur.
 *
 * Un élève possède un **code de liaison** court et non devinable, stocké sur son
 * profil et indexé (index inverse `student_link_codes/{code}` → studentId). Le
 * parent saisit ce code ; le serveur le résout et crée un document canonique
 * `children_links/{parentId}_{studentId}` en statut `approved`. La possession du
 * code est la preuve d'autorisation : aucun parent ne peut rattacher un enfant
 * en devinant un UID, et aucun annuaire d'élèves n'est exposé au client.
 *
 * Durcissement (release v27) :
 * - anti-bruteforce : les tentatives échouées par parent sont comptées, puis
 *   bloquées au-delà d'un seuil (message générique, sans énumération) ;
 * - l'élève peut faire tourner (révoquer + régénérer) son code : l'ancien code
 *   est immédiatement supprimé de l'index inverse ;
 * - idempotence conservée pour les liens déjà approuvés.
 *
 * L'index inverse, le code et le compteur de tentatives ne sont écrits/lus que
 * par ces callables (Admin SDK) : les règles Firestore refusent tout accès
 * client (deny par défaut), sans qu'aucune règle existante ne soit affaiblie.
 * App Check est appliqué globalement (setGlobalOptions) ; ces callables en
 * héritent sans configuration séparée.
 */

export interface StudentSummary {
  studentId: string;
  firstName: string;
  classLevel: string;
}

export interface ChildLinkResult {
  studentId: string;
  firstName: string;
  classLevel: string;
  alreadyLinked: boolean;
}

/** Paramètres anti-bruteforce (fenêtre glissante par parent). */
export const linkRateLimit = {
  maxFailures: 5,
  windowMs: 15 * 60 * 1000,
  blockMs: 15 * 60 * 1000,
};

export interface ChildLinkStore {
  /** Rôle stocké du compte appelant (`parent`, `student`, …), ou undefined. */
  readRole(uid: string): Promise<string | undefined>;

  /** Vrai si le parent est temporairement bloqué (trop d'échecs récents). */
  isRateLimited(parentId: string): Promise<boolean>;

  /** Enregistre une tentative échouée (code inconnu) pour ce parent. */
  recordFailedAttempt(parentId: string): Promise<void>;

  /** Réinitialise le compteur d'échecs (après une résolution réussie). */
  resetAttempts(parentId: string): Promise<void>;

  /** Résout un code de liaison normalisé → studentId, ou null si inconnu. */
  resolveStudentByCode(code: string): Promise<string | null>;

  /** Résumé minimal d'un élève (nom, classe). Jamais l'annuaire complet. */
  readStudentSummary(studentId: string): Promise<StudentSummary | null>;

  /** Crée/merge le lien approuvé parent↔élève. Idempotent. */
  upsertApprovedLink(params: {
    parentId: string;
    studentId: string;
  }): Promise<{ alreadyLinked: boolean }>;

  /** Renvoie le code de liaison de l'élève, en le générant au besoin. */
  ensureLinkCode(studentId: string): Promise<string>;

  /** Révoque l'ancien code et en émet un nouveau. L'ancien devient invalide. */
  rotateLinkCode(studentId: string): Promise<string>;
}

// Alphabet sans caractères ambigus (pas de O/0, I/1, etc.), lisible à voix haute.
const _codeAlphabet = "ABCDEFGHJKMNPQRSTUVWXYZ23456789";
const _codeLength = 8;

/** Normalise un code saisi : majuscules, sans espaces ni tirets. */
export function normalizeLinkCode(raw: unknown): string {
  if (typeof raw !== "string") return "";
  return raw
    .trim()
    .toUpperCase()
    .replace(/[\s-]+/g, "");
}

export function generateLinkCode(random: () => number = Math.random): string {
  let code = "";
  for (let i = 0; i < _codeLength; i++) {
    code += _codeAlphabet[Math.floor(random() * _codeAlphabet.length)];
  }
  return code;
}

export class FirestoreChildLinkStore implements ChildLinkStore {
  async readRole(uid: string): Promise<string | undefined> {
    const snapshot = await db.collection("users").doc(uid).get();
    const role = snapshot.data()?.role;
    return typeof role === "string" ? role : undefined;
  }

  async isRateLimited(parentId: string): Promise<boolean> {
    const snapshot = await db.collection("link_attempts").doc(parentId).get();
    const blockedUntilMs = snapshot.data()?.blockedUntilMs;
    return typeof blockedUntilMs === "number" && blockedUntilMs > Date.now();
  }

  async recordFailedAttempt(parentId: string): Promise<void> {
    const ref = db.collection("link_attempts").doc(parentId);
    await db.runTransaction(async (tx) => {
      const now = Date.now();
      const data = (await tx.get(ref)).data();
      const windowStartMs =
        typeof data?.windowStartMs === "number" ? data.windowStartMs : 0;
      const withinWindow = now - windowStartMs <= linkRateLimit.windowMs;
      const failures = withinWindow ? (data?.failures ?? 0) + 1 : 1;
      tx.set(ref, {
        failures,
        windowStartMs: withinWindow ? windowStartMs : now,
        blockedUntilMs:
          failures >= linkRateLimit.maxFailures
            ? now + linkRateLimit.blockMs
            : (data?.blockedUntilMs ?? 0),
        updatedAt: FieldValue.serverTimestamp(),
      });
    });
  }

  async resetAttempts(parentId: string): Promise<void> {
    await db
      .collection("link_attempts")
      .doc(parentId)
      .delete()
      .catch(() => {
        // L'absence de document est le cas nominal : rien à réinitialiser.
      });
  }

  async resolveStudentByCode(code: string): Promise<string | null> {
    if (!code) return null;
    const snapshot = await db.collection("student_link_codes").doc(code).get();
    const studentId = snapshot.data()?.studentId;
    return typeof studentId === "string" && studentId.length > 0
      ? studentId
      : null;
  }

  async readStudentSummary(studentId: string): Promise<StudentSummary | null> {
    const snapshot = await db
      .collection("student_profiles")
      .doc(studentId)
      .get();
    const data = snapshot.data();
    if (!data) return null;
    return {
      studentId,
      firstName:
        typeof data.firstName === "string" && data.firstName.trim().length > 0
          ? data.firstName.trim()
          : "Enfant",
      classLevel:
        typeof data.classLevel === "string" ? data.classLevel.trim() : "",
    };
  }

  async upsertApprovedLink(params: {
    parentId: string;
    studentId: string;
  }): Promise<{ alreadyLinked: boolean }> {
    const linkId = `${params.parentId}_${params.studentId}`;
    const ref = db.collection("children_links").doc(linkId);
    const existing = await ref.get();
    const alreadyLinked =
      existing.exists && existing.data()?.status === "approved";
    await ref.set(
      {
        parentId: params.parentId,
        studentId: params.studentId,
        status: "approved",
        linkedVia: "code",
        updatedAt: FieldValue.serverTimestamp(),
        ...(existing.exists ? {} : { createdAt: FieldValue.serverTimestamp() }),
      },
      { merge: true },
    );
    return { alreadyLinked };
  }

  async ensureLinkCode(studentId: string): Promise<string> {
    const profileRef = db.collection("student_profiles").doc(studentId);
    const existing = (await profileRef.get()).data()?.linkCode;
    if (typeof existing === "string" && existing.length > 0) return existing;
    return this._issueCode(studentId, null);
  }

  async rotateLinkCode(studentId: string): Promise<string> {
    const profileRef = db.collection("student_profiles").doc(studentId);
    const previous = (await profileRef.get()).data()?.linkCode;
    const previousCode =
      typeof previous === "string" && previous.length > 0 ? previous : null;
    return this._issueCode(studentId, previousCode);
  }

  /**
   * Émet un code unique pour l'élève et, si [previousCode] est fourni, supprime
   * l'ancien de l'index inverse dans la même transaction (invalidation
   * immédiate). Réessaie en cas de collision.
   */
  private async _issueCode(
    studentId: string,
    previousCode: string | null,
  ): Promise<string> {
    const profileRef = db.collection("student_profiles").doc(studentId);
    for (let attempt = 0; attempt < 8; attempt++) {
      const code = generateLinkCode();
      const codeRef = db.collection("student_link_codes").doc(code);
      const committed = await db.runTransaction(async (tx) => {
        // Sans rotation, un code déjà présent est renvoyé tel quel (idempotent).
        if (previousCode === null) {
          const profile = await tx.get(profileRef);
          const already = profile.data()?.linkCode;
          if (typeof already === "string" && already.length > 0) return already;
        }
        const taken = await tx.get(codeRef);
        if (taken.exists) return null;
        if (previousCode !== null && previousCode !== code) {
          tx.delete(db.collection("student_link_codes").doc(previousCode));
        }
        tx.set(codeRef, {
          studentId,
          createdAt: FieldValue.serverTimestamp(),
        });
        tx.set(profileRef, { linkCode: code }, { merge: true });
        return code;
      });
      if (committed) return committed;
    }
    throw new HttpsError(
      "resource-exhausted",
      "Impossible de générer un code de liaison. Réessayez.",
    );
  }
}

function requireParent(role: string | undefined): void {
  if (role !== "parent") {
    throw new HttpsError(
      "permission-denied",
      "Seul un compte parent peut rattacher un enfant.",
    );
  }
}

function requireStudent(role: string | undefined): void {
  if (role !== "student") {
    throw new HttpsError(
      "permission-denied",
      "Seul un compte élève possède un code de liaison.",
    );
  }
}

/** Callable parent : rattache un enfant à partir de son code de liaison. */
export function createLinkChildByCodeHandler(
  store: ChildLinkStore = new FirestoreChildLinkStore(),
) {
  return async (
    request: CallableRequest<{ code?: unknown }>,
  ): Promise<ChildLinkResult> => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Firebase Auth is required.");
    }
    requireParent(await store.readRole(uid));

    // Anti-bruteforce : au-delà du seuil d'échecs, on refuse sans révéler quoi
    // que ce soit sur l'existence d'un code (aucune énumération possible).
    if (await store.isRateLimited(uid)) {
      throw new HttpsError(
        "resource-exhausted",
        "Trop de tentatives. Réessaie un peu plus tard.",
      );
    }

    const code = normalizeLinkCode(request.data?.code);
    if (code.length === 0) {
      throw new HttpsError("invalid-argument", "Code enfant manquant.");
    }
    const studentId = await store.resolveStudentByCode(code);
    if (!studentId) {
      await store.recordFailedAttempt(uid);
      throw new HttpsError("not-found", "Ce code enfant est introuvable.");
    }
    const summary = await store.readStudentSummary(studentId);
    if (!summary) {
      await store.recordFailedAttempt(uid);
      throw new HttpsError("not-found", "Ce code enfant est introuvable.");
    }
    // Résolution réussie : on repart d'un compteur propre.
    await store.resetAttempts(uid);
    const { alreadyLinked } = await store.upsertApprovedLink({
      parentId: uid,
      studentId,
    });
    return {
      studentId,
      firstName: summary.firstName,
      classLevel: summary.classLevel,
      alreadyLinked,
    };
  };
}

/** Callable élève : renvoie (ou génère) son code de liaison à partager. */
export function createEnsureStudentLinkCodeHandler(
  store: ChildLinkStore = new FirestoreChildLinkStore(),
) {
  return async (
    request: CallableRequest<unknown>,
  ): Promise<{ code: string }> => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Firebase Auth is required.");
    }
    requireStudent(await store.readRole(uid));
    return { code: await store.ensureLinkCode(uid) };
  };
}

/**
 * Callable élève : révoque le code actuel et en génère un nouveau. L'ancien code
 * cesse immédiatement de fonctionner ; les liens déjà approuvés sont conservés.
 */
export function createRotateStudentLinkCodeHandler(
  store: ChildLinkStore = new FirestoreChildLinkStore(),
) {
  return async (
    request: CallableRequest<unknown>,
  ): Promise<{ code: string }> => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Firebase Auth is required.");
    }
    requireStudent(await store.readRole(uid));
    return { code: await store.rotateLinkCode(uid) };
  };
}

export const linkChildByCodeHandler = createLinkChildByCodeHandler();
export const ensureStudentLinkCodeHandler =
  createEnsureStudentLinkCodeHandler();
export const rotateStudentLinkCodeHandler =
  createRotateStudentLinkCodeHandler();
