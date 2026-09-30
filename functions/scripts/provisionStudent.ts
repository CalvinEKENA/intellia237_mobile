import { createHash, randomUUID } from "node:crypto";
import { mkdir, writeFile } from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";
import { applicationDefault, deleteApp, initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { normalizeStudentProvisionInput, planStudentProvision } from "../src/services/studentProvisioning";
import { encodeMigrationSnapshot, migrateTeacherToStudent, requireTeacherConversion } from "../src/services/studentRoleMigration";

function argument(name: string): string {
  const index = process.argv.indexOf(name);
  if (index < 0 || !process.argv[index + 1] || process.argv[index + 1].startsWith("--")) throw new Error(`Missing ${name}.`);
  return process.argv[index + 1];
}

async function main() {
  const input = { email: argument("--email"), role: argument("--role"), classLevel: argument("--class"), series: argument("--series") };
  const target = normalizeStudentProvisionInput(input);
  const projectId = argument("--project");
  const apply = process.argv.includes("--apply");
  const convertRole = process.argv.includes("--convert-role") ? argument("--convert-role") : undefined;
  const conversion = { convertRole, confirm: process.argv.includes("--confirm"), apply };
  if (convertRole || conversion.confirm) requireTeacherConversion(conversion);
  const app = initializeApp({ projectId, credential: applicationDefault() }, "student-provisioning");
  try {
    const auth = getAuth(app);
    const db = getFirestore(app);
    if (convertRole) {
      const result = await migrateTeacherToStudent({
        db, auth, projectId,
        saveBackup: async (snapshot) => {
          // Personal data stays outside the repository, never in a Git artifact.
          const directory = join(homedir(), ".intellia237-private", "role-migrations");
          await mkdir(directory, { recursive: true, mode: 0o700 });
          const path = join(directory, `${randomUUID()}.json`);
          await writeFile(path, JSON.stringify(encodeMigrationSnapshot(snapshot), null, 2), { flag: "wx", mode: 0o600 });
          console.log(`Logical backup saved outside Git: ${path}`);
        },
      }, input, conversion);
      console.log(JSON.stringify(result));
      return;
    }
    console.log("Checking the requested Auth identity (read-only).");
    const existing = await auth.getUserByEmail(target.email).catch((error) => {
      if (error.code === "auth/user-not-found") return null;
      throw error;
    });
    // Stable UID also permits safe retries if Auth succeeded before Firestore.
    const uid = existing?.uid ?? `student_${createHash("sha256").update(target.email).digest("hex").slice(0, 40)}`;
    const userRef = db.doc(`users/${uid}`);
    const profileRef = db.doc(`student_profiles/${uid}`);
    const readPlan = async (transaction?: FirebaseFirestore.Transaction) => {
      const refs = [userRef, profileRef, ...["parent_profiles", "teacher_profiles", "admin_profiles"].map((collection) => db.doc(`${collection}/${uid}`))];
      const docs = transaction ? await transaction.getAll(...refs) : await db.getAll(...refs);
      // Re-read Auth at application time; never alter credentials or claims.
      const identity = await auth.getUser(uid).catch((error) => {
        if (error.code === "auth/user-not-found") return null;
        throw error;
      });
      if (identity && identity.email?.toLowerCase() !== target.email) throw new Error("UID belongs to another identity.");
      if (!transaction) console.log(JSON.stringify({ existingRole: docs[0].get('role') ?? null, userClass: docs[0].get('classLevel') ?? null, userSeries: docs[0].get('series') ?? null, profileClass: docs[1].get('classLevel') ?? null, profileSeries: docs[1].get('series') ?? null, disabled: identity?.disabled ?? false, hasAdultProfile: docs.slice(2).some((doc) => doc.exists), hasPrivilegedClaims: Object.keys(identity?.customClaims ?? {}).some((key) => ['role', 'roles', 'parent', 'teacher', 'admin', 'superAdmin'].includes(key)) }));
      return planStudentProvision(input, uid, { user: docs[0].data(), profile: docs[1].data(), adultProfile: docs.slice(2).some((doc) => doc.exists), claims: identity?.customClaims, disabled: identity?.disabled });
    };
    console.log("Checking only the requested identity’s profile compatibility (read-only).");
    const plan = await readPlan();
    console.log(JSON.stringify({ mode: apply ? "apply" : "dry-run", projectId, email: target.email, authExists: existing !== null, role: target.role, classLevel: target.classLevel, series: target.series, userFields: Object.keys(plan.user), profileFields: Object.keys(plan.profile) }));
    if (!apply) return;
    if (!existing) {
      await auth.createUser({ uid, email: target.email, emailVerified: false }).catch(async (error) => {
        if (error.code !== "auth/email-already-exists" && error.code !== "auth/uid-already-exists") throw error;
        if ((await auth.getUserByEmail(target.email)).uid !== uid) throw new Error("Concurrent identity creation: rerun safely.");
      });
    }
    await db.runTransaction(async (transaction) => {
      const latest = await readPlan(transaction);
      for (const [ref, update] of [[userRef, latest.user], [profileRef, latest.profile]] as const) {
        if (Object.keys(update).length === 0) continue;
        const timestamps = { updatedAt: FieldValue.serverTimestamp(), ...(update.uid ? { createdAt: FieldValue.serverTimestamp() } : {}) };
        transaction.set(ref, { ...update, ...timestamps }, { merge: true });
      }
    });
    const [user, profile] = await db.getAll(userRef, profileRef);
    console.log(JSON.stringify({ verified: true, role: user.get("role"), classLevel: profile.get("classLevel"), series: profile.get("series"), profileCompleted: user.get("profileCompleted") === true }));
    console.log("Use the public email sign-in and Forgot password to choose a password. No password or reset link was generated here.");
  } finally { await deleteApp(app); }
}

main().catch((error) => {
  // Never print credential details, token-bearing URLs or arbitrary SDK messages.
  const code = typeof error?.code === "string" ? error.code : "provisioning-failed";
  const message = String(error?.message ?? '');
  const category = /invalid_grant|invalid_rapt|reauth|refresh token/i.test(message) ? 'admin-credentials-expired'
    : /default credentials|credential/i.test(message) ? 'admin-credentials-unavailable'
    : /Incompatible|authorization|another identity|Concurrent/.test(message) ? 'incompatible-existing-account'
    : /permission|PERMISSION_DENIED/i.test(message) ? 'admin-permission-denied'
    : /timeout|ETIMEDOUT|ENOTFOUND|fetch failed/i.test(message) ? 'network-unavailable'
    : 'unclassified-failure';
  console.error(`Provisioning stopped (${code}; ${category}). No success claimed.`);
  process.exitCode = 1;
});
