import { isDeepStrictEqual } from "node:util";
import type { Auth } from "firebase-admin/auth";
import { FieldValue, Firestore, Timestamp, type DocumentSnapshot, type Transaction } from "firebase-admin/firestore";
import { normalizeStudentProvisionInput, planStudentProvision, type StudentProvisionInput } from "./studentProvisioning";

type Data = Record<string, unknown>;
export type ConversionOptions = { convertRole?: string; confirm: boolean; apply: boolean };

export function requireTeacherConversion(options: ConversionOptions) {
  if (options.convertRole !== "teacher:student" || !options.confirm) {
    throw new Error("Conversion requires --convert-role teacher:student AND --confirm.");
  }
}

// This narrowly scoped operation must never detach an active teacher from real work.
// Query results are rechecked inside the write transaction, not only in the CLI.
export const teacherMigrationRelations: ReadonlyArray<readonly [string, string, "==" | "array-contains"]> = [
  ["classes", "teacherIds", "array-contains"], ["classes", "mainTeacherId", "=="],
  ["subjects", "teacherIds", "array-contains"], ["lesson_assets", "teacherUid", "=="],
  ["quizzes", "createdBy", "=="], ["announcements", "createdBy", "=="],
  ["children_links", "parentId", "=="], ["children_links", "studentId", "=="],
  ["establishments", "adminId", "=="], ["establishments", "adminIds", "array-contains"],
  ["establishments", "createdBy", "=="], ["account_role_changes", "targetId", "=="],
  ["account_management_audit", "targetId", "=="], ["establishment_changes", "accountId", "=="],
  ["subscriptions", "userId", "=="], ["payments", "userId", "=="],
  ["mobile_money_payment_requests", "userId", "=="],
  ["mobile_money_payment_requests", "parentId", "=="],
  ["mobile_money_payment_requests", "studentIds", "array-contains"],
  ["mobile_money_payment_requests", "beneficiaryStudentId", "=="],
  ["subscriptions", "parentId", "=="], ["entitlements", "parentId", "=="], ["entitlements", "userId", "=="],
];

const collections = ["users", "student_profiles", "teacher_profiles", "parent_profiles", "admin_profiles", "account_deletion_requests", "subscriptions", "entitlements"];
const journalPath = (uid: string) => `account_role_migrations/teacher_student_v1_${uid}`;

export interface MigrationSnapshot {
  projectId: string;
  uid: string;
  email: string;
  claims: Data;
  disabled: boolean;
  providerIds: string[];
  documents: Array<{ path: string; data: Data | null; updateTime: Timestamp | null }>;
}

// Lossless for the profile schema; unknown Firestore types stop BEFORE any writes.
export function encodeMigrationSnapshot(value: unknown): unknown {
  if (value instanceof Timestamp) return { __firestoreTimestamp: [value.seconds, value.nanoseconds] };
  if (Array.isArray(value)) return value.map(encodeMigrationSnapshot);
  if (value !== null && typeof value === "object") {
    if (Object.getPrototypeOf(value) !== Object.prototype) throw new Error("Unsupported backup value.");
    return Object.fromEntries(Object.entries(value).map(([key, child]) => {
      if (/password|secret|token|private.?key/i.test(key)) throw new Error("Credential-like data cannot enter a migration backup.");
      return [key, encodeMigrationSnapshot(child)];
    }));
  }
  if (value === null || ["string", "number", "boolean"].includes(typeof value)) return value;
  throw new Error("Unsupported backup value.");
}

export function decodeMigrationSnapshot(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(decodeMigrationSnapshot);
  if (value !== null && typeof value === "object") {
    const data = value as Data;
    if (Array.isArray(data.__firestoreTimestamp)) {
      return new Timestamp(Number(data.__firestoreTimestamp[0]), Number(data.__firestoreTimestamp[1]));
    }
    return Object.fromEntries(Object.entries(data).map(([key, child]) => [key, decodeMigrationSnapshot(child)]));
  }
  return value;
}

export function assertConvertibleTeacher(user: Data | undefined, teacher: Data | undefined, claims: Data) {
  if (!user || user.role !== "teacher" || !teacher || teacher.archived === true ||
      (user.roles !== undefined && (!Array.isArray(user.roles) || user.roles.some((role) => role !== "teacher"))) ||
      !["pending_validation", "active", undefined].includes(user.accountStatus as string | undefined) ||
      user.establishmentId || teacher.establishmentId || user.isSuperAdmin || teacher.analytics ||
      Object.values((teacher.workload ?? {}) as Data).some((value) => value !== 0)) {
    throw new Error("Incompatible teacher profile or professional activity.");
  }
  for (const [key, value] of Object.entries(claims)) {
    const allowed = (key === "role" && value === "teacher") || (key === "teacher" && value === true) ||
      (key === "roles" && Array.isArray(value) && value.every((role) => role === "teacher"));
    if (!allowed) throw new Error("Incompatible or unknown claims; separate review required.");
  }
}

export async function migrateTeacherToStudent(deps: {
  db: Firestore;
  auth: Pick<Auth, "getUserByEmail" | "getUser" | "setCustomUserClaims" | "revokeRefreshTokens">;
  projectId: string;
  saveBackup: (snapshot: MigrationSnapshot) => Promise<void>;
}, input: StudentProvisionInput, options: ConversionOptions) {
  requireTeacherConversion(options);
  const target = normalizeStudentProvisionInput(input);
  const { db, auth } = deps;
  const identity = await auth.getUserByEmail(target.email);
  if (identity.disabled) throw new Error("Incompatible disabled account.");
  const uid = identity.uid;
  const claims: Data = identity.customClaims ?? {};
  const refs = collections.map((collection) => db.doc(`${collection}/${uid}`));
  const journalRef = db.doc(journalPath(uid));
  const read = async (transaction?: Transaction) => {
    const documents = transaction ? await transaction.getAll(...refs, journalRef) : await db.getAll(...refs, journalRef);
    const relations: Record<string, number> = {};
    await Promise.all(teacherMigrationRelations.map(async ([collection, field, operator]) => {
      const query = db.collection(collection).where(field, operator, uid).limit(1);
      relations[`${collection}.${field}`] = (transaction ? await transaction.get(query) : await query.get()).size;
    }));
    return { documents, relations };
  };
  type State = Awaited<ReturnType<typeof read>>;
  const validate = ({ documents, relations }: State, currentClaims = claims) => {
    if (Object.values(relations).some((count) => count > 0) || documents.slice(3, collections.length).some((doc) => doc.exists)) {
      throw new Error("Incompatible related activity or administrative documents.");
    }
    const [user, student, teacher] = documents;
    const journal = documents[collections.length];
    if (journal.exists) {
      if (journal.get("migration") !== "teacher:student/v1" || journal.get("uid") !== uid ||
          !["firestore-committed", "complete"].includes(journal.get("status")) ||
          user.get("role") !== "student" || user.get("classLevel") !== target.classLevel || user.get("series") !== target.series ||
          !student.exists || teacher.get("archived") !== true || teacher.get("archivedByMigration") !== journalRef.id ||
          Object.keys(currentClaims).length !== 0) throw new Error("Incompatible migration replay.");
      planStudentProvision(input, uid, { user: user.data(), profile: student.data(), claims: currentClaims });
      if (student.get("preferences.academicLevelId") !== "fr_general_terminale" || student.get("preferences.streamOrSpeciality") !== "D") {
        throw new Error("Incompatible academic state after migration.");
      }
      return "resume" as const;
    }
    if (student.exists) throw new Error("Incompatible existing student profile.");
    assertConvertibleTeacher(user.data(), teacher.data(), claims);
    for (const doc of [user, teacher]) {
      if ((doc.get("uid") && doc.get("uid") !== uid) || (doc.get("email") && String(doc.get("email")).toLowerCase() !== target.email)) {
        throw new Error("Incompatible document identity.");
      }
    }
    return "convert" as const;
  };
  const before = await read();
  const mode = validate(before);
  const report = { uid, role: before.documents[0].get("role"), classLevel: target.classLevel, series: target.series, relations: before.relations };
  if (!options.apply) return { ...report, status: "dry-run", action: mode };

  if (mode === "convert") {
    await deps.saveBackup({
      projectId: deps.projectId, uid, email: target.email, disabled: identity.disabled, claims,
      providerIds: identity.providerData.map((provider) => provider.providerId),
      documents: before.documents.map((doc) => ({ path: doc.ref.path, data: doc.data() ?? null, updateTime: doc.updateTime ?? null })),
    });
    const sameRevision = (current: DocumentSnapshot[]) => current.every((doc, i) =>
      doc.exists === before.documents[i].exists && isDeepStrictEqual(doc.updateTime, before.documents[i].updateTime));
    const latestIdentity = await auth.getUser(uid);
    if (latestIdentity.disabled || latestIdentity.email?.toLowerCase() !== target.email || !isDeepStrictEqual(latestIdentity.customClaims ?? {}, claims)) {
      throw new Error("Concurrent Auth change; rerun preflight.");
    }
    try {
      if (Object.keys(claims).length > 0) await auth.setCustomUserClaims(uid, {});
      await db.runTransaction(async (transaction) => {
        const latest = await read(transaction);
        if (!sameRevision(latest.documents) || validate(latest) !== "convert") throw new Error("Concurrent profile change; rerun preflight.");
        const oldUser = latest.documents[0].data()!;
        const oldTeacher = latest.documents[2].data()!;
        const student = planStudentProvision(input, uid, {}).profile;
        const completed = oldUser.profileCompleted === true && Boolean(oldUser.firstName) && Boolean(oldUser.lastName);
        const stamp = FieldValue.serverTimestamp();
        transaction.update(refs[0], {
          role: "student", roles: [], classLevel: target.classLevel, series: target.series,
          accountStatus: "active", requiresValidation: false, profileCompleted: completed,
          establishmentId: FieldValue.delete(), establishmentName: FieldValue.delete(), establishmentVerified: FieldValue.delete(),
          updatedAt: stamp,
        });
        transaction.create(refs[1], {
          ...student, firstName: oldUser.firstName ?? "", lastName: oldUser.lastName ?? "", profileCompleted: completed,
          // Preserve only already-recorded consents; never invent a new acceptance.
          ...(oldTeacher.consents ? { consents: oldTeacher.consents } : {}), createdAt: stamp, updatedAt: stamp,
        });
        transaction.update(refs[2], { archived: true, archivedAt: stamp, archivedByMigration: journalRef.id });
        transaction.create(journalRef, { migration: "teacher:student/v1", uid, status: "firestore-committed", classLevel: target.classLevel, series: target.series, createdAt: stamp });
      });
    } catch (error) {
      // An ambiguous network result must never re-grant teacher claims after commit.
      // If these reads fail, leave claims stripped and resume after inspection.
      const after = await db.getAll(...refs, journalRef);
      if (!after[collections.length].exists && sameRevision(after) && Object.keys(claims).length > 0) {
        const latestAuth = await auth.getUser(uid);
        if (isDeepStrictEqual(latestAuth.customClaims ?? {}, {})) await auth.setCustomUserClaims(uid, claims);
      }
      throw error;
    }
  }
  const journal = await journalRef.get();
  if (journal.get("status") !== "complete") {
    // Credentials are never updated. Invalidate old refresh sessions only.
    await auth.revokeRefreshTokens(uid);
    await journalRef.update({ status: "complete", completedAt: FieldValue.serverTimestamp() });
  }
  const finalIdentity = await auth.getUser(uid);
  if (finalIdentity.disabled || Object.keys(finalIdentity.customClaims ?? {}).length > 0) throw new Error("Post-migration Auth verification failed.");
  const final = await read();
  validate(final, finalIdentity.customClaims ?? {});
  return { ...report, role: "student", status: mode === "resume" ? "already-migrated" : "migrated", profileCompleted: final.documents[0].get("profileCompleted"), claims: {} };
}
