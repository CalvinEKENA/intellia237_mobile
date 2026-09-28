import { timingSafeEqual } from "node:crypto";

import { getAuth } from "firebase-admin/auth";
import { FieldValue, type Firestore } from "firebase-admin/firestore";
import { logger } from "firebase-functions";
import { HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import { z } from "zod";

import { db } from "../config/firebase";
import {
  clientIdentity,
  FirestoreStudentAccessStore,
  studentAccessClientKey,
  type CustomTokenIssuer,
  type StudentAccessStore,
} from "./studentAccessCode";

/**
 * Accès démo : un compte élève unique, partagé, ouvert par un code
 * d'invitation remis par le propriétaire (ex. à un testeur).
 *
 * - Le code n'est JAMAIS écrit dans le dépôt (public) : il vit dans le secret
 *   `DEMO_ACCESS_CODE` (Secret Manager). Sans secret, l'accès est fermé.
 * - Il passe par la callable `signInWithStudentAccessCode`, donc par le même
 *   anti-bruteforce que les codes élève.
 * - Le compte démo est un élève ordinaire (aucun droit adulte, aucun
 *   établissement, aucune liaison parent), marqué `demo` ; seul lui peut
 *   changer librement de classe, pour tester chaque programme.
 */
export const demoAccessUid = "intellia-demo-student";

/** Casse, espaces et tirets ignorés : « abcd 12 » vaut « ABCD12 ». */
export function normalizeDemoAccessCode(raw: unknown): string {
  if (typeof raw !== "string") return "";
  return raw.trim().toUpperCase().replace(/[\s-]+/g, "");
}

/** Comparaison à temps constant avec le secret ; un secret vide ou trop
 * court ne reconnaît rien. */
export function matchesDemoAccessCode(raw: unknown, secret: string | undefined): boolean {
  const expected = normalizeDemoAccessCode(secret ?? "");
  const given = normalizeDemoAccessCode(raw);
  if (expected.length < 6 || given.length !== expected.length) return false;
  return timingSafeEqual(Buffer.from(given), Buffer.from(expected));
}

/** Une classe proposée au compte démo : enseignement général, francophone
 * ou anglophone. */
export interface DemoClass {
  classLevel: string;
  subsystem: "francophone" | "anglophone";
  levelSlug: string;
  series: readonly string[];
}

/** Mêmes clés que l'application (SchoolClass.catalogKey, academicLevelId). */
export const demoClasses: readonly DemoClass[] = [
  { classLevel: "6eme", subsystem: "francophone", levelSlug: "6e", series: [] },
  { classLevel: "5eme", subsystem: "francophone", levelSlug: "5e", series: [] },
  { classLevel: "4eme", subsystem: "francophone", levelSlug: "4e", series: [] },
  { classLevel: "3eme", subsystem: "francophone", levelSlug: "3e", series: [] },
  { classLevel: "Seconde", subsystem: "francophone", levelSlug: "2nde", series: ["A", "C"] },
  { classLevel: "Premiere", subsystem: "francophone", levelSlug: "1ere", series: ["A", "C", "D"] },
  { classLevel: "Terminale", subsystem: "francophone", levelSlug: "terminale", series: ["A", "C", "D"] },
  { classLevel: "Form1", subsystem: "anglophone", levelSlug: "form1", series: [] },
  { classLevel: "Form2", subsystem: "anglophone", levelSlug: "form2", series: [] },
  { classLevel: "Form3", subsystem: "anglophone", levelSlug: "form3", series: [] },
  { classLevel: "Form4", subsystem: "anglophone", levelSlug: "form4", series: [] },
  { classLevel: "Form5", subsystem: "anglophone", levelSlug: "form5", series: [] },
  { classLevel: "LowerSixth", subsystem: "anglophone", levelSlug: "lower_sixth", series: [] },
  { classLevel: "UpperSixth", subsystem: "anglophone", levelSlug: "upper_sixth", series: [] },
];

/** Champs académiques d'une classe démo, identiques à ceux d'une
 * inscription ; `null` si la classe ou la série n'existe pas. */
export function demoAcademicFields(classLevel: unknown, series: unknown) {
  const target = demoClasses.find((entry) => entry.classLevel === classLevel);
  if (!target) return null;
  const normalizedSeries =
    typeof series === "string" && series.trim() ? series.trim().toUpperCase() : null;
  if (target.series.length === 0 ? normalizedSeries !== null : !target.series.includes(normalizedSeries ?? "")) {
    return null;
  }
  return {
    classLevel: target.classLevel,
    series: normalizedSeries,
    educationalSubsystem: target.subsystem,
    educationType: "general",
    academicLevelId: `${target.subsystem === "francophone" ? "fr" : "en"}_general_${target.levelSlug}`,
    streamOrSpeciality: normalizedSeries,
  };
}

/** Classe d'arrivée : la Terminale D, la plus fournie en cours. */
export const demoDefaultClass = { classLevel: "Terminale", series: "D" } as const;

export interface DemoAccountStore {
  /** Crée le compte démo s'il manque ; ne touche jamais un compte existant. */
  ensureAccount(uid: string): Promise<void>;
  updateClass(uid: string, fields: NonNullable<ReturnType<typeof demoAcademicFields>>): Promise<void>;
}

export class FirestoreDemoAccountStore implements DemoAccountStore {
  constructor(
    private readonly firestore: Firestore = db,
    private readonly auth = getAuth(),
  ) {}

  async ensureAccount(uid: string): Promise<void> {
    try {
      await this.auth.getUser(uid);
    } catch {
      await this.auth.createUser({ uid, displayName: "Invité INTELLIA" });
    }
    // Marque durable : le client et `setDemoAccessClass` reconnaissent le
    // compte démo, même après rafraîchissement du jeton.
    await this.auth.setCustomUserClaims(uid, { demo: true });

    const academic = demoAcademicFields(demoDefaultClass.classLevel, demoDefaultClass.series)!;
    const users = this.firestore.collection("users").doc(uid);
    const profiles = this.firestore.collection("student_profiles").doc(uid);
    await this.firestore.runTransaction(async (transaction) => {
      const [user, profile] = await Promise.all([transaction.get(users), transaction.get(profiles)]);
      const now = FieldValue.serverTimestamp();
      if (!user.exists) {
        transaction.create(users, {
          uid,
          firstName: "Invité",
          lastName: "INTELLIA",
          email: "",
          role: "student",
          classLevel: academic.classLevel,
          series: academic.series,
          tutorId: "leo",
          profileCompleted: true,
          tourGuideSeen: false,
          accountStatus: "active",
          demo: true,
          createdAt: now,
          updatedAt: now,
        });
      }
      if (!profile.exists) {
        transaction.create(profiles, {
          uid,
          firstName: "Invité",
          lastName: "INTELLIA",
          email: "",
          classLevel: academic.classLevel,
          series: academic.series,
          points: 0,
          level: 1,
          streak: { current: 0, best: 0, lastStudyDate: null },
          tutorId: "leo",
          preferences: {
            preferredSubjects: [],
            difficultSubjects: [],
            dailyStudyMinutes: 30,
            studyReminderEnabled: false,
            notificationsEnabled: false,
            contentLanguage: "fr",
            interfaceLanguage: "fr",
            educationalSubsystem: academic.educationalSubsystem,
            educationType: academic.educationType,
            academicLevelId: academic.academicLevelId,
            streamOrSpeciality: academic.streamOrSpeciality,
            accountLinkage: "individual",
            establishmentCandidate: null,
          },
          consents: {
            termsAccepted: true,
            privacyAccepted: true,
            dataPolicyAccepted: true,
            acceptedAt: now,
          },
          profileCompleted: true,
          demo: true,
          createdAt: now,
          updatedAt: now,
        });
      }
    });
  }

  async updateClass(
    uid: string,
    fields: NonNullable<ReturnType<typeof demoAcademicFields>>,
  ): Promise<void> {
    const now = FieldValue.serverTimestamp();
    const batch = this.firestore.batch();
    batch.update(this.firestore.collection("users").doc(uid), {
      classLevel: fields.classLevel,
      series: fields.series,
      updatedAt: now,
    });
    batch.update(this.firestore.collection("student_profiles").doc(uid), {
      classLevel: fields.classLevel,
      series: fields.series,
      "preferences.educationalSubsystem": fields.educationalSubsystem,
      "preferences.educationType": fields.educationType,
      "preferences.academicLevelId": fields.academicLevelId,
      "preferences.streamOrSpeciality": fields.streamOrSpeciality,
      updatedAt: now,
    });
    await batch.commit();
  }
}

const signInInput = z.object({ code: z.string().max(64) });

const invalidDemoCode = () =>
  new HttpsError("permission-denied", "Invalid student access code.");

/**
 * Callable publique : échange le code d'invitation démo contre un jeton du
 * compte démo. Même anti-bruteforce, même réponse d'échec que les codes
 * élève ; sans secret configuré, tout code est refusé.
 */
export function createSignInWithDemoAccessHandler(
  pepper: () => string,
  demoCode: () => string | undefined,
  attempts: Pick<
    StudentAccessStore,
    "isClientBlocked" | "recordClientFailure" | "resetClientFailures"
  > = new FirestoreStudentAccessStore(),
  accounts: DemoAccountStore = new FirestoreDemoAccountStore(),
  tokens: CustomTokenIssuer = getAuth(),
) {
  return async (request: CallableRequest<unknown>): Promise<{ token: string }> => {
    const clientKey = studentAccessClientKey(clientIdentity(request), pepper());
    if (await attempts.isClientBlocked(clientKey)) {
      throw new HttpsError("resource-exhausted", "Too many attempts. Try again later.");
    }
    const parsed = signInInput.safeParse(request.data);
    if (!parsed.success || !matchesDemoAccessCode(parsed.data.code, demoCode())) {
      await attempts.recordClientFailure(clientKey);
      throw invalidDemoCode();
    }
    await accounts.ensureAccount(demoAccessUid);
    await attempts.resetClientFailures(clientKey);
    const token = await tokens.createCustomToken(demoAccessUid, {
      accessMethod: "demo_access",
      demo: true,
    });
    logger.info("Demo access opened.");
    return { token };
  };
}

const setDemoClassInput = z.object({
  classLevel: z.string().min(1).max(20),
  series: z.string().max(2).nullable().optional(),
});

/**
 * Callable réservée au compte démo : change sa classe (et sa série) pour
 * tester un autre programme. Aucun autre compte ne peut l'utiliser.
 */
export function createSetDemoAccessClassHandler(
  store: DemoAccountStore = new FirestoreDemoAccountStore(),
) {
  return async (request: CallableRequest<unknown>) => {
    const auth = request.auth;
    if (!auth || auth.uid !== demoAccessUid || auth.token?.demo !== true) {
      throw new HttpsError("permission-denied", "Demo access only.");
    }
    const parsed = setDemoClassInput.safeParse(request.data);
    const fields = parsed.success
      ? demoAcademicFields(parsed.data.classLevel, parsed.data.series ?? null)
      : null;
    if (!fields) throw new HttpsError("invalid-argument", "Unknown class.");
    await store.updateClass(demoAccessUid, fields);
    logger.info("Demo class changed.", { classLevel: fields.classLevel, series: fields.series });
    return { classLevel: fields.classLevel, series: fields.series };
  };
}
