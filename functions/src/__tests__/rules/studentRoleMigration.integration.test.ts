import { randomUUID } from "node:crypto";
import { deleteApp, initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { afterAll, beforeEach, describe, expect, it, vi } from "vitest";
import { encodeMigrationSnapshot, migrateTeacherToStudent, type MigrationSnapshot } from "../../services/studentRoleMigration";

if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
  throw new Error("Auth and Firestore emulators required.");
}
const projectId = "demo-intellia237";
const app = initializeApp({ projectId }, "student-role-migration-tests");
const db = getFirestore(app);
const auth = getAuth(app);
const input = { email: "migration-test@yahoo.fr", role: "student", classLevel: "terminale", series: "D" };
const options = { convertRole: "teacher:student", confirm: true, apply: true };
const uid = "teacher-test";
let password: string;
let backup: MigrationSnapshot | undefined;
const saveBackup = vi.fn(async (snapshot: MigrationSnapshot) => {
  encodeMigrationSnapshot(snapshot);
  backup = snapshot;
});
const deps = { db, auth, projectId, saveBackup };
const userRef = db.doc(`users/${uid}`);
const teacherRef = db.doc(`teacher_profiles/${uid}`);
const studentRef = db.doc(`student_profiles/${uid}`);

async function signIn() {
  const response = await fetch(`http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=emulator`, {
    method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify({ email: input.email, password, returnSecureToken: true }),
  });
  if (!response.ok) throw new Error("Emulated password sign-in failed.");
  return await response.json() as { localId: string; idToken: string };
}

beforeEach(async () => {
  vi.restoreAllMocks();
  saveBackup.mockClear();
  backup = undefined;
  const collections = await db.listCollections();
  await Promise.all(collections.map((collection) => db.recursiveDelete(collection)));
  await auth.deleteUser(uid).catch((error) => { if (error.code !== "auth/user-not-found") throw error; });
  password = `${randomUUID()}Aa1!`;
  await auth.createUser({ uid, email: input.email, password });
  await userRef.set({ uid, email: input.email, role: "teacher", roles: ["teacher"], accountStatus: "pending_validation", requiresValidation: true, profileCompleted: true, firstName: "Compte", lastName: "Test", createdAt: new Timestamp(100, 123) });
  await teacherRef.set({ uid, email: input.email, subjects: ["Anglais"], levels: ["Terminale"], workload: { activeClasses: 0, activeStudents: 0 }, consents: { termsAccepted: true, privacyAccepted: true, acceptedAt: new Timestamp(100, 123) } });
});
afterAll(async () => { await deleteApp(app); });

describe("controlled teacher migration on real emulators", () => {
  it("preserves credentials, archives history, writes the official academic profile and replays without writes", async () => {
    await auth.setCustomUserClaims(uid, { teacher: true, role: "teacher", roles: ["teacher"] });
    expect((await signIn()).localId).toBe(uid);
    const originalTeacher = (await teacherRef.get()).data();
    const result = await migrateTeacherToStudent(deps, input, options);
    expect(result).toMatchObject({ status: "migrated", role: "student", profileCompleted: true, claims: {} });
    expect(backup?.documents[0].data?.role).toBe("teacher");
    expect(backup?.claims).toEqual({ teacher: true, role: "teacher", roles: ["teacher"] });
    expect((await teacherRef.get()).data()).toMatchObject({ ...originalTeacher, archived: true });
    expect((await userRef.get()).data()).toMatchObject({ role: "student", roles: [], requiresValidation: false, accountStatus: "active", classLevel: "Terminale", series: "D" });
    const profile = (await studentRef.get()).data()!;
    expect(profile).toMatchObject({ uid, classLevel: "Terminale", series: "D", preferences: { academicLevelId: "fr_general_terminale", streamOrSpeciality: "D" } });
    expect(profile.consents).not.toHaveProperty("dataPolicyAccepted");
    expect(profile).not.toHaveProperty("password");
    expect((await signIn()).localId).toBe(uid);
    const before = (await studentRef.get()).updateTime;
    const revoke = vi.spyOn(auth, "revokeRefreshTokens");
    expect((await migrateTeacherToStudent(deps, input, options)).status).toBe("already-migrated");
    expect((await studentRef.get()).updateTime).toEqual(before);
    expect(saveBackup).toHaveBeenCalledTimes(1);
    expect(revoke).not.toHaveBeenCalled();
  });
  it("does not write or back up on a dry run", async () => {
    expect((await migrateTeacherToStudent(deps, input, { ...options, apply: false })).status).toBe("dry-run");
    expect(saveBackup).not.toHaveBeenCalled();
    expect((await userRef.get()).get("role")).toBe("teacher");
  });
  it.each(["classes", "lesson_assets", "parent_profiles", "entitlements"])("refuses existing activity in %s", async (collection) => {
    await db.doc(`${collection}/${uid}`).set({ teacherIds: [uid], teacherUid: uid, userId: uid });
    await expect(migrateTeacherToStudent(deps, input, options)).rejects.toThrow("Incompatible");
    expect(saveBackup).not.toHaveBeenCalled();
  });
  it("requires a completed backup before changing claims or documents", async () => {
    await auth.setCustomUserClaims(uid, { teacher: true });
    await expect(migrateTeacherToStudent({ ...deps, saveBackup: async () => { throw new Error("backup unavailable"); } }, input, options)).rejects.toThrow("backup unavailable");
    expect((await auth.getUser(uid)).customClaims).toEqual({ teacher: true });
    expect((await userRef.get()).get("role")).toBe("teacher");
  });
  it("rolls claims back when the Firestore transaction fails before commit", async () => {
    await auth.setCustomUserClaims(uid, { teacher: true });
    vi.spyOn(db, "runTransaction").mockRejectedValueOnce(new Error("injected transaction failure"));
    await expect(migrateTeacherToStudent(deps, input, options)).rejects.toThrow("injected transaction failure");
    expect((await auth.getUser(uid)).customClaims).toEqual({ teacher: true });
    expect((await userRef.get()).get("role")).toBe("teacher");
    expect((await studentRef.get()).exists).toBe(false);
    expect((await teacherRef.get()).get("archived")).toBeUndefined();
  });
  it("detects a profile change after the backup without overwriting it", async () => {
    await expect(migrateTeacherToStudent({ ...deps, saveBackup: async (snapshot) => {
      await saveBackup(snapshot); await userRef.update({ firstName: "Edited concurrently" });
    } }, input, options)).rejects.toThrow("Concurrent profile change");
    expect((await userRef.get()).get("firstName")).toBe("Edited concurrently");
    expect((await studentRef.get()).exists).toBe(false);
  });
  it("resumes safely after a token-revocation failure without restoring teacher rights", async () => {
    await auth.setCustomUserClaims(uid, { teacher: true });
    vi.spyOn(auth, "revokeRefreshTokens").mockRejectedValueOnce(new Error("injected Auth outage"));
    await expect(migrateTeacherToStudent(deps, input, options)).rejects.toThrow("injected Auth outage");
    expect((await auth.getUser(uid)).customClaims).toEqual({});
    expect((await userRef.get()).get("role")).toBe("student");
    expect((await migrateTeacherToStudent(deps, input, options)).status).toBe("already-migrated");
    expect(saveBackup).toHaveBeenCalledTimes(1);
  });
  it("never restores teacher claims when a transaction committed but its response was lost", async () => {
    await auth.setCustomUserClaims(uid, { teacher: true });
    const runTransaction = db.runTransaction.bind(db);
    vi.spyOn(db, "runTransaction").mockImplementationOnce(async (update) => {
      await runTransaction(update);
      throw new Error("response lost after commit");
    });
    await expect(migrateTeacherToStudent(deps, input, options)).rejects.toThrow("response lost after commit");
    expect((await auth.getUser(uid)).customClaims).toEqual({});
    expect((await userRef.get()).get("role")).toBe("student");
    expect((await migrateTeacherToStudent(deps, input, options)).status).toBe("already-migrated");
  });
  it("does not grant teacher rights through the archived profile or an old report", async () => {
    await migrateTeacherToStudent(deps, input, options);
    await db.doc("reports/old-teacher-report").set({ generatedBy: uid, establishmentId: "old-school" });
    const session = await signIn();
    const response = await fetch(`http://${process.env.FIRESTORE_EMULATOR_HOST}/v1/projects/${projectId}/databases/(default)/documents/reports/old-teacher-report`, { headers: { authorization: `Bearer ${session.idToken}` } });
    expect(response.status).toBe(403);
  });
});
