import { createHmac } from "node:crypto";

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

/**
 * Migration d'un téléphone familial : de l'accès élève vers le compte parent.
 *
 * Cas réel : un parent a créé l'accès de son enfant avec SON numéro. Plus tard
 * il vérifie ce numéro pour ouvrir l'espace parent et Firebase le connecte…
 * sur l'UID élève. Personne ne doit « utiliser un autre numéro ».
 *
 * Après confirmation explicite (jamais en silence), le serveur :
 *   1. émet un code d'accès élève — l'élève garde un moyen d'entrer ;
 *   2. retire le téléphone de l'identité élève (UID et données inchangés) ;
 *   3. crée l'identité parent portant ce téléphone ;
 *   4. rattache l'élève au parent et termine le journal ;
 *   5. renvoie un jeton parent et le code d'accès, montré une seule fois.
 *
 * Firebase Auth n'offre pas de transaction entre deux comptes : chaque étape
 * est journalisée (`auth_phone_migrations/{empreinte du téléphone}`) avec un
 * bail contre les exécutions concurrentes. Un échec en 3 remet le téléphone à
 * l'élève (compensation). Si la compensation échoue aussi, le code d'accès
 * émis en 1 part dans le détail de l'erreur et le numéro, libre, peut être
 * vérifié à nouveau : l'identité fraîche ainsi créée est adoptée comme parent.
 * À aucun moment la famille ne reste sans accès parent ni accès élève.
 *
 * La preuve de possession est une vérification SMS récente du numéro : un
 * jeton ancien de l'appareil de l'enfant ne suffit pas.
 */

export const phoneVerificationMaxAgeMs = 5 * 60 * 1000;
export const migrationLeaseMs = 60 * 1000;

export type MigrationStatus =
  | "started"
  | "phone_detached"
  | "parent_attached"
  | "completed"
  | "compensated"
  | "needs_recovery";

export interface MigrationJournal {
  phoneKey: string;
  phoneE164: string;
  studentUid: string;
  parentUid: string;
  status: MigrationStatus;
  leaseUntilMs: number;
  requestId: string;
}

export interface MigrationAccount {
  role: string;
  accountStatus: string;
  firstName: string;
}

export interface FamilyPhoneMigrationStore {
  readAccount(uid: string): Promise<MigrationAccount | null>;
  /** Vrai si un document de profil existe déjà pour cet UID (tout rôle). */
  hasAnyProfile(uid: string): Promise<boolean>;
  readJournal(phoneKey: string): Promise<MigrationJournal | null>;
  /**
   * Prend le bail du journal (le crée au besoin). Renvoie null si une autre
   * exécution détient un bail encore valide.
   */
  claimJournal(params: {
    phoneKey: string;
    phoneE164: string;
    studentUid: string;
    candidateParentUid: string;
    requestId: string;
    nowMs: number;
  }): Promise<MigrationJournal | null>;
  updateJournal(
    phoneKey: string,
    patch: Partial<Pick<MigrationJournal, "status" | "parentUid" | "leaseUntilMs">> & {
      lastError?: string;
    },
  ): Promise<void>;
  /** Lien approuvé, téléphone retiré des fiches élève, journal terminé : une transaction. */
  finalizeFamily(params: {
    phoneKey: string;
    parentUid: string;
    studentUid: string;
  }): Promise<void>;
}

export interface MigrationAuthPort {
  getPhoneNumber(uid: string): Promise<string | null | undefined>;
  detachPhone(uid: string): Promise<void>;
  attachPhone(uid: string, phoneE164: string): Promise<void>;
  /** Crée l'identité parent ; idempotent si elle porte déjà ce numéro. */
  createPhoneUser(uid: string, phoneE164: string): Promise<void>;
  createCustomToken(uid: string): Promise<string>;
}

export interface MigrationResult {
  status: "completed";
  studentId: string;
  studentFirstName: string;
  parentUid: string;
  /** Jeton personnalisé du parent ; null si l'appelant EST déjà le parent. */
  parentToken: string | null;
  /** Code d'accès élève émis par CET appel ; null s'il a été émis avant. */
  studentAccessCode: string | null;
}

const migrationInput = z
  .object({
    requestId: z.string().uuid(),
    confirmed: z.literal(true),
  })
  .strict();

export function familyPhoneKey(phoneE164: string, pepper: string): string {
  return createHmac("sha256", pepper).update(`family-phone:${phoneE164}`).digest("hex");
}

interface VerifiedPhoneCaller {
  uid: string;
  phoneE164: string;
}

/** Exige une vérification SMS récente du numéro par l'appelant. */
export function requireRecentPhoneVerification(
  request: CallableRequest<unknown>,
  nowMs: number,
): VerifiedPhoneCaller {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Firebase Auth is required.");
  const token = request.auth?.token as
    | { phone_number?: unknown; auth_time?: unknown; firebase?: { sign_in_provider?: unknown } }
    | undefined;
  const phone = typeof token?.phone_number === "string" ? token.phone_number : "";
  const authTimeMs = typeof token?.auth_time === "number" ? token.auth_time * 1000 : 0;
  if (
    token?.firebase?.sign_in_provider !== "phone" ||
    !/^\+[1-9]\d{6,14}$/.test(phone) ||
    nowMs - authTimeMs > phoneVerificationMaxAgeMs
  ) {
    throw new HttpsError(
      "failed-precondition",
      "A recent SMS verification of this phone number is required.",
      { reason: "recent-phone-verification-required" },
    );
  }
  return { uid, phoneE164: phone };
}

export interface MigrationDependencies {
  pepper: () => string;
  store: FamilyPhoneMigrationStore;
  access: StudentAccessStore;
  auth: MigrationAuthPort;
  now?: () => number;
  newUid?: () => string;
}

export function createMigrateStudentPhoneToParentHandler(deps: MigrationDependencies) {
  const now = deps.now ?? (() => Date.now());
  const newUid = deps.newUid ?? (() => db.collection("users").doc().id);

  return async (request: CallableRequest<unknown>): Promise<MigrationResult> => {
    const caller = requireRecentPhoneVerification(request, now());
    const parsed = migrationInput.safeParse(request.data);
    if (!parsed.success) {
      throw new HttpsError("invalid-argument", "An explicit confirmation is required.");
    }
    const pepper = deps.pepper();
    const phoneKey = familyPhoneKey(caller.phoneE164, pepper);
    const existing = await deps.store.readJournal(phoneKey);

    if (existing?.status === "completed") {
      return replayCompleted(existing, caller);
    }

    const plan = await planFor(existing, caller);
    const journal = await deps.store.claimJournal({
      phoneKey,
      phoneE164: caller.phoneE164,
      studentUid: plan.studentUid,
      candidateParentUid: plan.parentUid ?? newUid(),
      requestId: parsed.data.requestId,
      nowMs: now(),
    });
    if (!journal) {
      throw new HttpsError("aborted", "This migration is already in progress. Try again shortly.");
    }

    let studentAccessCode: string | null = null;
    try {
      if (plan.adoptCallerAsParent) {
        await deps.store.updateJournal(phoneKey, { parentUid: caller.uid, status: "parent_attached" });
        journal.parentUid = caller.uid;
        journal.status = "parent_attached";
      }

      if (journal.status === "started" || journal.status === "compensated") {
        // 1. L'élève reçoit un accès qui ne dépend plus du téléphone.
        ({ code: studentAccessCode } = await issueStudentAccessCode(deps.access, pepper, {
          studentId: journal.studentUid,
          actorUid: caller.uid,
          actorRole: "family_phone_migration",
        }));
        // 2. Le téléphone quitte l'identité élève.
        try {
          await deps.auth.detachPhone(journal.studentUid);
        } catch (error) {
          // Le numéro est resté à l'élève : rien n'a changé pour la famille.
          await deps.store.updateJournal(phoneKey, { leaseUntilMs: 0, lastError: errorCode(error) });
          throw new HttpsError("unavailable", "Nothing changed. Try again.", {
            reason: "migration-compensated",
          });
        }
        await deps.store.updateJournal(phoneKey, { status: "phone_detached" });
        journal.status = "phone_detached";
      }

      if (journal.status === "phone_detached" || journal.status === "needs_recovery") {
        // 3. Le téléphone rejoint l'identité parent.
        try {
          await deps.auth.createPhoneUser(journal.parentUid, journal.phoneE164);
        } catch (error) {
          await compensate(journal, error, studentAccessCode);
        }
        await deps.store.updateJournal(phoneKey, { status: "parent_attached" });
        journal.status = "parent_attached";
      }

      // 4. Lien approuvé et fiches élève mises à jour, en une transaction.
      await retrying(() =>
        deps.store.finalizeFamily({
          phoneKey,
          parentUid: journal.parentUid,
          studentUid: journal.studentUid,
        }),
      ).catch(async (error: unknown) => {
        await deps.store.updateJournal(phoneKey, { leaseUntilMs: 0, lastError: errorCode(error) });
        throw new HttpsError(
          "unavailable",
          "The parent access is ready but the family link is not finished. Verify the number again to finish.",
          { reason: "migration-resumable", studentAccessCode },
        );
      });
    } catch (error) {
      // Le bail ne doit pas bloquer la reprise : l'état du journal, lui, reste
      // celui que la dernière étape réussie a écrit.
      await deps.store.updateJournal(phoneKey, { leaseUntilMs: 0 }).catch(() => undefined);
      throw error;
    }

    const student = await deps.store.readAccount(journal.studentUid);
    logger.info("Family phone moved from a student access to a parent account.", {
      studentId: journal.studentUid,
      parentUid: journal.parentUid,
    });
    return {
      status: "completed",
      studentId: journal.studentUid,
      studentFirstName: student?.firstName ?? "",
      parentUid: journal.parentUid,
      parentToken:
        caller.uid === journal.parentUid ? null : await deps.auth.createCustomToken(journal.parentUid),
      studentAccessCode,
    };
  };

  async function replayCompleted(
    journal: MigrationJournal,
    caller: VerifiedPhoneCaller,
  ): Promise<MigrationResult> {
    // Réponse perdue, double appui : même résultat, sans nouveau code. Le parent
    // peut en générer un depuis la fiche de l'enfant.
    if (caller.uid !== journal.parentUid && caller.uid !== journal.studentUid) {
      throw new HttpsError("failed-precondition", "This phone number already opens a parent account.");
    }
    const student = await deps.store.readAccount(journal.studentUid);
    return {
      status: "completed",
      studentId: journal.studentUid,
      studentFirstName: student?.firstName ?? "",
      parentUid: journal.parentUid,
      parentToken:
        caller.uid === journal.parentUid ? null : await deps.auth.createCustomToken(journal.parentUid),
      studentAccessCode: null,
    };
  }

  async function planFor(
    journal: MigrationJournal | null,
    caller: VerifiedPhoneCaller,
  ): Promise<{ studentUid: string; parentUid: string | null; adoptCallerAsParent: boolean }> {
    const refuse = () =>
      new HttpsError("failed-precondition", "This phone number cannot be migrated from this account.");
    const status = journal?.status;

    if (!journal || status === "compensated" || status === "started") {
      // Rien n'a encore quitté l'élève : seul l'élève qui porte ce numéro dans
      // Firebase Auth peut le céder. Une reprise de `started` reste réservée à
      // l'élève déjà inscrit au journal.
      if (status === "started" && caller.uid !== journal?.studentUid) throw refuse();
      const account = await deps.store.readAccount(caller.uid);
      if (!account || account.role !== "student" || account.accountStatus !== "active") {
        throw new HttpsError("failed-precondition", "This phone number does not open a student access.");
      }
      if ((await deps.auth.getPhoneNumber(caller.uid)) !== caller.phoneE164) {
        throw new HttpsError("failed-precondition", "This phone number does not open a student access.");
      }
      return { studentUid: caller.uid, parentUid: journal?.parentUid ?? null, adoptCallerAsParent: false };
    }

    // Le téléphone a déjà quitté l'élève : on termine, sans jamais repartir.
    if (caller.uid === journal.studentUid || caller.uid === journal.parentUid) {
      return { studentUid: journal.studentUid, parentUid: journal.parentUid, adoptCallerAsParent: false };
    }
    if (
      (status === "phone_detached" || status === "needs_recovery") &&
      !(await deps.store.hasAnyProfile(caller.uid))
    ) {
      // Le numéro, resté libre, a été vérifié à nouveau : Firebase a créé une
      // identité vierge pour lui. Elle devient le parent prévu.
      return { studentUid: journal.studentUid, parentUid: caller.uid, adoptCallerAsParent: true };
    }
    throw refuse();
  }

  async function compensate(
    journal: MigrationJournal,
    cause: unknown,
    studentAccessCode: string | null,
  ): Promise<never> {
    logger.error("Parent identity creation failed during a family phone migration.", {
      studentId: journal.studentUid,
      code: errorCode(cause),
    });
    try {
      await deps.auth.attachPhone(journal.studentUid, journal.phoneE164);
      await deps.store.updateJournal(journal.phoneKey, {
        status: "compensated",
        leaseUntilMs: 0,
        lastError: errorCode(cause),
      });
    } catch (compensationError) {
      await deps.store
        .updateJournal(journal.phoneKey, {
          status: "needs_recovery",
          leaseUntilMs: 0,
          lastError: errorCode(compensationError),
        })
        .catch(() => undefined);
      logger.error("Family phone migration compensation failed; recovery by SMS is required.", {
        studentId: journal.studentUid,
        code: errorCode(compensationError),
      });
      throw new HttpsError(
        "unavailable",
        "The number is free: verify it again to finish opening the parent space.",
        { reason: "migration-needs-recovery", studentAccessCode },
      );
    }
    throw new HttpsError("unavailable", "Nothing changed. Try again.", {
      reason: "migration-compensated",
    });
  }
}

async function retrying<T>(operation: () => Promise<T>, attempts = 3): Promise<T> {
  let lastError: unknown;
  for (let attempt = 0; attempt < attempts; attempt++) {
    try {
      return await operation();
    } catch (error) {
      lastError = error;
    }
  }
  throw lastError;
}

function errorCode(error: unknown): string {
  if (error && typeof error === "object" && "code" in error) {
    return String((error as { code: unknown }).code);
  }
  return error instanceof Error ? error.name : "unknown";
}

export class FirestoreFamilyPhoneMigrationStore implements FamilyPhoneMigrationStore {
  constructor(
    private readonly firestore: Firestore = db,
    private readonly nowMs: () => number = () => Date.now(),
  ) {}

  async readAccount(uid: string): Promise<MigrationAccount | null> {
    const [user, profile] = await Promise.all([
      this.firestore.collection("users").doc(uid).get(),
      this.firestore.collection("student_profiles").doc(uid).get(),
    ]);
    if (!user.exists) return null;
    const data = user.data() ?? {};
    const firstName = [data.firstName, profile.data()?.firstName].find(
      (value): value is string => typeof value === "string" && value.trim().length > 0,
    );
    return {
      role: typeof data.role === "string" ? data.role : "",
      accountStatus: typeof data.accountStatus === "string" ? data.accountStatus : "active",
      firstName: firstName?.trim() ?? "",
    };
  }

  async hasAnyProfile(uid: string): Promise<boolean> {
    const snapshots = await Promise.all(
      ["users", "student_profiles", "parent_profiles"].map((collection) =>
        this.firestore.collection(collection).doc(uid).get(),
      ),
    );
    return snapshots.some((snapshot) => snapshot.exists);
  }

  async readJournal(phoneKey: string): Promise<MigrationJournal | null> {
    const snapshot = await this.firestore.collection("auth_phone_migrations").doc(phoneKey).get();
    return snapshot.exists ? toJournal(phoneKey, snapshot.data() ?? {}) : null;
  }

  async claimJournal(params: {
    phoneKey: string;
    phoneE164: string;
    studentUid: string;
    candidateParentUid: string;
    requestId: string;
    nowMs: number;
  }): Promise<MigrationJournal | null> {
    const ref = this.firestore.collection("auth_phone_migrations").doc(params.phoneKey);
    return this.firestore.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(ref);
      const current = snapshot.exists ? toJournal(params.phoneKey, snapshot.data() ?? {}) : null;
      if (current && current.leaseUntilMs > params.nowMs) return null;
      const leaseUntilMs = params.nowMs + migrationLeaseMs;
      if (!current) {
        const journal: MigrationJournal = {
          phoneKey: params.phoneKey,
          phoneE164: params.phoneE164,
          studentUid: params.studentUid,
          parentUid: params.candidateParentUid,
          status: "started",
          leaseUntilMs,
          requestId: params.requestId,
        };
        transaction.create(ref, {
          ...journalFields(journal),
          attempts: 1,
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });
        return journal;
      }
      // Après compensation, tout est revenu à l'état initial : on repart avec
      // l'élève qui porte le numéro aujourd'hui.
      const restarted = current.status === "compensated";
      const journal: MigrationJournal = {
        ...current,
        studentUid: restarted ? params.studentUid : current.studentUid,
        status: restarted ? "started" : current.status,
        leaseUntilMs,
        requestId: params.requestId,
      };
      transaction.update(ref, {
        studentUid: journal.studentUid,
        status: journal.status,
        leaseUntilMs,
        requestId: params.requestId,
        attempts: FieldValue.increment(1),
        updatedAt: FieldValue.serverTimestamp(),
      });
      return journal;
    });
  }

  async updateJournal(
    phoneKey: string,
    patch: Partial<Pick<MigrationJournal, "status" | "parentUid" | "leaseUntilMs">> & {
      lastError?: string;
    },
  ): Promise<void> {
    await this.firestore
      .collection("auth_phone_migrations")
      .doc(phoneKey)
      .update({ ...patch, updatedAt: FieldValue.serverTimestamp() });
  }

  async finalizeFamily(params: {
    phoneKey: string;
    parentUid: string;
    studentUid: string;
  }): Promise<void> {
    const journalRef = this.firestore.collection("auth_phone_migrations").doc(params.phoneKey);
    const linkRef = this.firestore
      .collection("children_links")
      .doc(`${params.parentUid}_${params.studentUid}`);
    const userRef = this.firestore.collection("users").doc(params.studentUid);
    const profileRef = this.firestore.collection("student_profiles").doc(params.studentUid);
    await this.firestore.runTransaction(async (transaction) => {
      const [link, profile] = await Promise.all([transaction.get(linkRef), transaction.get(profileRef)]);
      transaction.set(
        linkRef,
        {
          parentId: params.parentUid,
          studentId: params.studentUid,
          status: "approved",
          linkedVia: "family_phone_migration",
          updatedAt: FieldValue.serverTimestamp(),
          ...(link.exists ? {} : { createdAt: FieldValue.serverTimestamp() }),
        },
        { merge: true },
      );
      // Le numéro appartient désormais au parent : il quitte les fiches élève,
      // qui gardent tout le reste (classe, progression, réserve, historique).
      const moved = {
        phoneNumber: FieldValue.delete(),
        authPhoneMovedToParentId: params.parentUid,
        authPhoneMovedAtMs: this.nowMs(),
        updatedAt: FieldValue.serverTimestamp(),
      };
      transaction.update(userRef, moved);
      if (profile.exists) transaction.update(profileRef, moved);
      transaction.update(journalRef, {
        status: "completed",
        parentUid: params.parentUid,
        leaseUntilMs: 0,
        completedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
      transaction.create(this.firestore.collection("student_access_audit").doc(), {
        type: "phone_moved_to_parent",
        studentId: params.studentUid,
        actorUid: params.parentUid,
        actorRole: "parent",
        createdAt: FieldValue.serverTimestamp(),
      });
    });
  }
}

function journalFields(journal: MigrationJournal) {
  return {
    phoneE164: journal.phoneE164,
    studentUid: journal.studentUid,
    parentUid: journal.parentUid,
    status: journal.status,
    leaseUntilMs: journal.leaseUntilMs,
    requestId: journal.requestId,
  };
}

function toJournal(phoneKey: string, data: Record<string, unknown>): MigrationJournal {
  return {
    phoneKey,
    phoneE164: String(data.phoneE164 ?? ""),
    studentUid: String(data.studentUid ?? ""),
    parentUid: String(data.parentUid ?? ""),
    status: String(data.status ?? "started") as MigrationStatus,
    leaseUntilMs: typeof data.leaseUntilMs === "number" ? data.leaseUntilMs : 0,
    requestId: String(data.requestId ?? ""),
  };
}

export class AdminMigrationAuthPort implements MigrationAuthPort {
  constructor(private readonly auth: Auth = getAuth()) {}

  async getPhoneNumber(uid: string): Promise<string | null | undefined> {
    return (await this.auth.getUser(uid)).phoneNumber;
  }

  async detachPhone(uid: string): Promise<void> {
    await this.auth.updateUser(uid, { phoneNumber: null });
  }

  async attachPhone(uid: string, phoneE164: string): Promise<void> {
    await this.auth.updateUser(uid, { phoneNumber: phoneE164 });
  }

  async createPhoneUser(uid: string, phoneE164: string): Promise<void> {
    try {
      await this.auth.createUser({ uid, phoneNumber: phoneE164 });
    } catch (error) {
      if (errorCode(error) !== "auth/uid-already-exists") throw error;
      const existing = await this.auth.getUser(uid);
      if (existing.phoneNumber !== phoneE164) {
        await this.auth.updateUser(uid, { phoneNumber: phoneE164 });
      }
    }
  }

  async createCustomToken(uid: string): Promise<string> {
    return this.auth.createCustomToken(uid);
  }
}

export function createDefaultMigrateStudentPhoneToParentHandler(pepper: () => string) {
  return createMigrateStudentPhoneToParentHandler({
    pepper,
    store: new FirestoreFamilyPhoneMigrationStore(),
    access: new FirestoreStudentAccessStore(),
    auth: new AdminMigrationAuthPort(),
  });
}
