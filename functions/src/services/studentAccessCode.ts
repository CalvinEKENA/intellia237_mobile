import { createHmac, randomInt } from "node:crypto";

import { getAuth } from "firebase-admin/auth";
import { FieldValue, type Firestore } from "firebase-admin/firestore";
import { logger } from "firebase-functions";
import { HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import { z } from "zod";

import { db } from "../config/firebase";

/**
 * Code d'accès élève : l'accès d'un élève à SON espace sans téléphone.
 *
 * Distinct du code de liaison parent (qui établit une relation) : ce code est
 * un identifiant de connexion. Il est donc traité comme un secret :
 * - tiré par CSPRNG, 12 symboles non ambigus (≈ 2^59,5 combinaisons) ;
 * - jamais stocké en clair : seule une empreinte HMAC-SHA-256, avec un poivre
 *   gardé dans Secret Manager, sert d'index ;
 * - renvoyé une seule fois à l'émission ; une nouvelle émission invalide
 *   l'ancien code dans la même transaction ;
 * - vérifié côté serveur avec un anti-bruteforce par client, puis échangé
 *   contre un jeton personnalisé Firebase pour l'UID élève.
 *
 * Le parent lié, la direction de l'école de l'élève et la super-administration
 * peuvent émettre un code. Aucun code n'apparaît dans une URL, un journal ou
 * une analytique.
 */

export const studentAccessCodeAlphabet = "ABCDEFGHJKMNPQRSTUVWXYZ23456789";
export const studentAccessCodeLength = 12;

/**
 * Verrou par client (IP ajoutée par Google + application App Check).
 *
 * Registre de décisions : au Cameroun, beaucoup d'utilisateurs partagent une
 * même IP publique (NAT des opérateurs mobiles, Wi-Fi d'école). Un seuil de 5
 * échecs bloquait toute une classe pour quelques fautes de frappe. Avec 31^12
 * combinaisons, même 20 essais par quart d'heure et par IP laissent une
 * probabilité de réussite négligeable ; le verrou sert à freiner l'abus, pas à
 * porter seul la sécurité.
 */
export const studentAccessRateLimit = {
  maxFailures: 20,
  windowMs: 15 * 60 * 1000,
  blockMs: 15 * 60 * 1000,
};

/** Majuscules, sans espaces ni tirets. */
export function normalizeStudentAccessCode(raw: unknown): string {
  if (typeof raw !== "string") return "";
  return raw.trim().toUpperCase().replace(/[\s-]+/g, "");
}

export function isWellFormedStudentAccessCode(normalized: string): boolean {
  if (normalized.length !== studentAccessCodeLength) return false;
  for (const symbol of normalized) {
    if (!studentAccessCodeAlphabet.includes(symbol)) return false;
  }
  return true;
}

/** Présentation lisible à voix haute : `ABCD-EFGH-JKMN`. */
export function formatStudentAccessCode(normalized: string): string {
  return normalized.match(/.{1,4}/g)?.join("-") ?? normalized;
}

export function generateStudentAccessCode(
  random: (max: number) => number = randomInt,
): string {
  let code = "";
  for (let index = 0; index < studentAccessCodeLength; index++) {
    code += studentAccessCodeAlphabet[random(studentAccessCodeAlphabet.length)];
  }
  return code;
}

/** Empreinte d'index : le code en clair n'est jamais écrit. */
export function studentAccessLookupKey(normalized: string, pepper: string): string {
  return createHmac("sha256", pepper).update(`student-access:${normalized}`).digest("hex");
}

/** Identité de client pour l'anti-bruteforce, sans IP en clair. */
export function studentAccessClientKey(
  client: { ip: string; appId: string },
  pepper: string,
): string {
  return createHmac("sha256", pepper)
    .update(`student-access-client:${client.ip}|${client.appId}`)
    .digest("hex");
}

export type AccountRole = "student" | "parent" | "teacher" | "admin" | "superAdmin";

export interface AccountSnapshot {
  role: string;
  accountStatus: string;
  establishmentId: string;
}

export interface StudentAccessCredentialStatus {
  hasAccessCode: boolean;
  issuedAt: string | null;
}

export interface StudentAccessStore {
  readAccount(uid: string): Promise<AccountSnapshot | null>;
  isLinkedParent(parentId: string, studentId: string): Promise<boolean>;
  /**
   * Remplace l'empreinte active de l'élève par [lookupKey], dans une seule
   * transaction : l'ancien index est supprimé, le nouveau créé. Renvoie null en
   * cas de collision d'empreinte (le code sera retiré).
   */
  replaceCredential(params: {
    studentId: string;
    lookupKey: string;
    actorUid: string;
    actorRole: string;
  }): Promise<{ version: number } | null>;
  readCredentialStatus(studentId: string): Promise<StudentAccessCredentialStatus>;
  /** studentId du code actif, ou null (inconnu, remplacé, incohérent). */
  resolveActiveCredential(lookupKey: string): Promise<string | null>;
  isClientBlocked(clientKey: string): Promise<boolean>;
  recordClientFailure(clientKey: string): Promise<void>;
  resetClientFailures(clientKey: string): Promise<void>;
}

export interface CustomTokenIssuer {
  createCustomToken(uid: string, claims?: Record<string, unknown>): Promise<string>;
}

export class FirestoreStudentAccessStore implements StudentAccessStore {
  constructor(
    private readonly firestore: Firestore = db,
    private readonly now: () => number = () => Date.now(),
  ) {}

  async readAccount(uid: string): Promise<AccountSnapshot | null> {
    const snapshot = await this.firestore.collection("users").doc(uid).get();
    if (!snapshot.exists) {
      // Accès ouvert par un parent pour un enfant sans téléphone : l'élève
      // n'a pas encore rempli son profil, mais son identité existe.
      const pending = await this.firestore.collection("pending_student_accounts").doc(uid).get();
      return pending.exists
        ? { role: "student", accountStatus: "active", establishmentId: "" }
        : null;
    }
    const data = snapshot.data() ?? {};
    return {
      role: normalized(data.role),
      accountStatus: normalized(data.accountStatus) || "active",
      establishmentId:
        normalized(data.establishmentId) ||
        (await this.profileEstablishment(uid)),
    };
  }

  async isLinkedParent(parentId: string, studentId: string): Promise<boolean> {
    const link = await this.firestore
      .collection("children_links")
      .doc(`${parentId}_${studentId}`)
      .get();
    return (
      link.exists &&
      link.data()?.status === "approved" &&
      link.data()?.parentId === parentId &&
      link.data()?.studentId === studentId
    );
  }

  async replaceCredential(params: {
    studentId: string;
    lookupKey: string;
    actorUid: string;
    actorRole: string;
  }): Promise<{ version: number } | null> {
    const credentialRef = this.firestore
      .collection("student_access_credentials")
      .doc(params.studentId);
    const lookupRef = this.firestore
      .collection("student_access_codes")
      .doc(params.lookupKey);
    return this.firestore.runTransaction(async (transaction) => {
      const [credential, lookup] = await Promise.all([
        transaction.get(credentialRef),
        transaction.get(lookupRef),
      ]);
      if (lookup.exists) return null;
      const previousKey = normalized(credential.data()?.lookupKey);
      const version =
        (typeof credential.data()?.version === "number"
          ? (credential.data()?.version as number)
          : 0) + 1;
      if (previousKey && previousKey !== params.lookupKey) {
        transaction.delete(
          this.firestore.collection("student_access_codes").doc(previousKey),
        );
      }
      transaction.create(lookupRef, {
        studentId: params.studentId,
        version,
        createdAt: FieldValue.serverTimestamp(),
      });
      transaction.set(credentialRef, {
        studentId: params.studentId,
        lookupKey: params.lookupKey,
        version,
        status: "active",
        issuedAtMs: this.now(),
        issuedAt: FieldValue.serverTimestamp(),
        issuedBy: params.actorUid,
        issuedByRole: params.actorRole,
        ...(credential.exists
          ? {}
          : { createdAt: FieldValue.serverTimestamp() }),
      }, { merge: true });
      transaction.create(this.firestore.collection("student_access_audit").doc(), {
        type: credential.exists ? "rotated" : "issued",
        studentId: params.studentId,
        actorUid: params.actorUid,
        actorRole: params.actorRole,
        version,
        createdAt: FieldValue.serverTimestamp(),
      });
      return { version };
    });
  }

  async readCredentialStatus(studentId: string): Promise<StudentAccessCredentialStatus> {
    const snapshot = await this.firestore
      .collection("student_access_credentials")
      .doc(studentId)
      .get();
    const data = snapshot.data();
    if (!data || data.status !== "active" || !normalized(data.lookupKey)) {
      return { hasAccessCode: false, issuedAt: null };
    }
    const issuedAtMs = typeof data.issuedAtMs === "number" ? data.issuedAtMs : null;
    return {
      hasAccessCode: true,
      issuedAt: issuedAtMs === null ? null : new Date(issuedAtMs).toISOString(),
    };
  }

  async resolveActiveCredential(lookupKey: string): Promise<string | null> {
    const lookup = await this.firestore
      .collection("student_access_codes")
      .doc(lookupKey)
      .get();
    const studentId = normalized(lookup.data()?.studentId);
    if (!studentId) return null;
    const credential = await this.firestore
      .collection("student_access_credentials")
      .doc(studentId)
      .get();
    const data = credential.data();
    // L'index et la fiche doivent désigner le même code actif : un index
    // orphelin (remplacé) n'ouvre jamais rien.
    if (
      !data ||
      data.status !== "active" ||
      data.lookupKey !== lookupKey ||
      data.version !== lookup.data()?.version
    ) {
      return null;
    }
    return studentId;
  }

  async isClientBlocked(clientKey: string): Promise<boolean> {
    const snapshot = await this.firestore
      .collection("student_access_attempts")
      .doc(clientKey)
      .get();
    const blockedUntilMs = snapshot.data()?.blockedUntilMs;
    return typeof blockedUntilMs === "number" && blockedUntilMs > this.now();
  }

  async recordClientFailure(clientKey: string): Promise<void> {
    const ref = this.firestore.collection("student_access_attempts").doc(clientKey);
    await this.firestore.runTransaction(async (transaction) => {
      const now = this.now();
      const data = (await transaction.get(ref)).data();
      const windowStartMs = typeof data?.windowStartMs === "number" ? data.windowStartMs : 0;
      const withinWindow = now - windowStartMs <= studentAccessRateLimit.windowMs;
      const failures = withinWindow ? (Number(data?.failures) || 0) + 1 : 1;
      transaction.set(ref, {
        failures,
        windowStartMs: withinWindow ? windowStartMs : now,
        blockedUntilMs:
          failures >= studentAccessRateLimit.maxFailures
            ? now + studentAccessRateLimit.blockMs
            : (typeof data?.blockedUntilMs === "number" ? data.blockedUntilMs : 0),
        updatedAt: FieldValue.serverTimestamp(),
      });
    });
  }

  async resetClientFailures(clientKey: string): Promise<void> {
    await this.firestore
      .collection("student_access_attempts")
      .doc(clientKey)
      .delete()
      .catch(() => undefined);
  }

  private async profileEstablishment(uid: string): Promise<string> {
    const profile = await this.firestore.collection("student_profiles").doc(uid).get();
    return normalized(profile.data()?.establishmentId);
  }
}

const issueInput = z.object({ studentId: z.string().trim().min(1).max(128).regex(/^[^/]+$/) }).strict();
const signInInput = z.object({ code: z.string().max(64) }).strict();

function isActive(account: AccountSnapshot | null): account is AccountSnapshot {
  return account !== null && account.accountStatus === "active";
}

export function isSuperAdminRole(role: string): boolean {
  return role === "superAdmin" || role === "super_admin";
}

/**
 * Qui peut agir sur l'accès d'un élève : un parent lié, la direction de l'école
 * de l'élève, la super-administration. Jamais un parent d'un autre élève, jamais
 * une direction d'une autre école — même si le parent est lié aux deux écoles.
 */
export async function authorizeStudentGuardianAction(
  store: Pick<StudentAccessStore, "readAccount" | "isLinkedParent">,
  actorUid: string,
  studentId: string,
): Promise<{ actorRole: string; student: AccountSnapshot }> {
  const [actor, student] = await Promise.all([
    store.readAccount(actorUid),
    store.readAccount(studentId),
  ]);
  if (!isActive(actor)) {
    throw new HttpsError("permission-denied", "This account cannot manage a student access.");
  }
  if (!student || student.role !== "student" || student.accountStatus === "deleted") {
    // Même réponse qu'un refus : l'existence d'un élève n'est pas révélée.
    throw new HttpsError("permission-denied", "This account cannot manage a student access.");
  }
  if (actor.role === "parent" && (await store.isLinkedParent(actorUid, studentId))) {
    return { actorRole: "parent", student };
  }
  if (
    actor.role === "admin" &&
    actor.establishmentId.length > 0 &&
    actor.establishmentId === student.establishmentId
  ) {
    return { actorRole: "admin", student };
  }
  if (isSuperAdminRole(actor.role)) {
    return { actorRole: "superAdmin", student };
  }
  throw new HttpsError("permission-denied", "This account cannot manage a student access.");
}

/** Émet un nouveau code d'accès pour [studentId] ; l'ancien cesse de fonctionner. */
export async function issueStudentAccessCode(
  store: StudentAccessStore,
  pepper: string,
  params: { studentId: string; actorUid: string; actorRole: string },
  random: (max: number) => number = randomInt,
): Promise<{ code: string; version: number }> {
  for (let attempt = 0; attempt < 5; attempt++) {
    const code = generateStudentAccessCode(random);
    const result = await store.replaceCredential({
      studentId: params.studentId,
      lookupKey: studentAccessLookupKey(code, pepper),
      actorUid: params.actorUid,
      actorRole: params.actorRole,
    });
    if (result) return { code: formatStudentAccessCode(code), version: result.version };
  }
  throw new HttpsError("resource-exhausted", "Unable to issue a student access code.");
}

export function createIssueStudentAccessCodeHandler(
  pepper: () => string,
  store: StudentAccessStore = new FirestoreStudentAccessStore(),
) {
  return async (
    request: CallableRequest<unknown>,
  ): Promise<{ code: string; issuedAt: string }> => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Firebase Auth is required.");
    const parsed = issueInput.safeParse(request.data);
    if (!parsed.success) throw new HttpsError("invalid-argument", "Invalid request payload.");
    const { actorRole } = await authorizeStudentGuardianAction(store, uid, parsed.data.studentId);
    const { code } = await issueStudentAccessCode(store, pepper(), {
      studentId: parsed.data.studentId,
      actorUid: uid,
      actorRole,
    });
    logger.info("Student access code issued.", {
      studentId: parsed.data.studentId,
      actorRole,
    });
    return { code, issuedAt: new Date().toISOString() };
  };
}

function clientIdentity(request: CallableRequest<unknown>): { ip: string; appId: string } {
  // L'infrastructure Google AJOUTE l'adresse du client en fin d'en-tête : les
  // valeurs précédentes viennent du client et ne prouvent rien. Prendre la
  // première laisserait un attaquant changer d'identité à chaque essai.
  const forwarded = request.rawRequest?.headers?.["x-forwarded-for"];
  const forwardedIp =
    typeof forwarded === "string" ? forwarded.split(",").pop()?.trim() ?? "" : "";
  return {
    ip: forwardedIp || request.rawRequest?.ip || "unknown",
    appId: request.app?.appId ?? "no-app-check",
  };
}

const invalidAccessCode = () =>
  new HttpsError("permission-denied", "Invalid student access code.");

/**
 * Callable publique : échange un code d'accès contre un jeton personnalisé de
 * l'UID élève. Toute cause d'échec — format, code inconnu ou remplacé, compte
 * suspendu — reçoit la même réponse et compte comme un échec du client.
 */
export function createSignInWithStudentAccessCodeHandler(
  pepper: () => string,
  store: StudentAccessStore = new FirestoreStudentAccessStore(),
  tokens: CustomTokenIssuer = getAuth(),
) {
  return async (request: CallableRequest<unknown>): Promise<{ token: string }> => {
    const secret = pepper();
    const clientKey = studentAccessClientKey(clientIdentity(request), secret);
    if (await store.isClientBlocked(clientKey)) {
      throw new HttpsError("resource-exhausted", "Too many attempts. Try again later.");
    }
    const parsed = signInInput.safeParse(request.data);
    const code = normalizeStudentAccessCode(parsed.success ? parsed.data.code : "");
    if (!isWellFormedStudentAccessCode(code)) {
      await store.recordClientFailure(clientKey);
      throw invalidAccessCode();
    }
    const studentId = await store.resolveActiveCredential(studentAccessLookupKey(code, secret));
    const student = studentId ? await store.readAccount(studentId) : null;
    if (!studentId || !student || student.role !== "student" || student.accountStatus !== "active") {
      await store.recordClientFailure(clientKey);
      throw invalidAccessCode();
    }
    await store.resetClientFailures(clientKey);
    const token = await tokens.createCustomToken(studentId, {
      accessMethod: "student_access_code",
    });
    logger.info("Student signed in with an access code.", { studentId });
    return { token };
  };
}

function normalized(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}
