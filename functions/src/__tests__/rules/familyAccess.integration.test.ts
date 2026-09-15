import { deleteApp, initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore } from "firebase-admin/firestore";
import { afterAll, beforeEach, describe, expect, it } from "vitest";

import {
  AdminMigrationAuthPort,
  createMigrateStudentPhoneToParentHandler,
  familyPhoneKey,
  FirestoreFamilyPhoneMigrationStore,
  migrationLeaseMs,
  type MigrationAuthPort,
} from "../../services/familyPhoneMigration";
import {
  AdminChildIdentityPort,
  createCreateChildStudentAccessHandler,
  FirestoreChildAccessCreationStore,
} from "../../services/childStudentAccessCallable";
import {
  createListParentChildrenHandler,
  FirestoreParentChildrenStore,
} from "../../services/parentChildrenCallable";
import {
  createIssueStudentAccessCodeHandler,
  createSignInWithStudentAccessCodeHandler,
  FirestoreStudentAccessStore,
  studentAccessRateLimit,
} from "../../services/studentAccessCode";
import { resolveEmulatorAddress } from "./emulator-address";

/**
 * Migration du téléphone familial et code d'accès élève contre les VRAIS
 * émulateurs Firebase Auth et Firestore : unicité des numéros, retrait du
 * téléphone, jetons personnalisés, transactions. Les pannes sont injectées
 * autour du vrai client Auth, au milieu du parcours.
 */

if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
  throw new Error("This test requires the Firestore and Auth emulators (--only firestore,auth).");
}

const projectId = "demo-intellia237";
const app = initializeApp({ projectId }, "family-access-tests");
const firestore = getFirestore(app);
const auth = getAuth(app);
const pepper = "integration-pepper";
const phone = "+237699000111";
const accessStore = new FirestoreStudentAccessStore(firestore);
const migrationStore = new FirestoreFamilyPhoneMigrationStore(firestore);

class FaultyAuth implements MigrationAuthPort {
  readonly real = new AdminMigrationAuthPort(auth);
  faults = { createPhoneUser: 0, attachPhone: 0 };
  getPhoneNumber(uid: string) { return this.real.getPhoneNumber(uid); }
  detachPhone(uid: string) { return this.real.detachPhone(uid); }
  createCustomToken(uid: string) { return this.real.createCustomToken(uid); }
  async attachPhone(uid: string, phoneE164: string) {
    if (this.faults.attachPhone-- > 0) throw Object.assign(new Error("injected"), { code: "test/attach" });
    return this.real.attachPhone(uid, phoneE164);
  }
  async createPhoneUser(uid: string, phoneE164: string) {
    if (this.faults.createPhoneUser-- > 0) throw Object.assign(new Error("injected"), { code: "test/create" });
    return this.real.createPhoneUser(uid, phoneE164);
  }
}

function migrationHandler(port: MigrationAuthPort, now = () => Date.now()) {
  return createMigrateStudentPhoneToParentHandler({
    pepper: () => pepper,
    store: migrationStore,
    access: accessStore,
    auth: port,
    now,
  });
}

function phoneSession(uid: string, authTimeMs = Date.now() - 10_000) {
  return {
    uid,
    token: {
      phone_number: phone,
      auth_time: Math.floor(authTimeMs / 1000),
      firebase: { sign_in_provider: "phone" },
    },
  };
}

const confirmation = { requestId: "2b1c9a8e-3f4d-4e5a-8b6c-7d8e9f0a1b2c", confirmed: true };

const signIn = (code: string, ip = "203.0.113.20") =>
  createSignInWithStudentAccessCodeHandler(() => pepper, accessStore, auth)(
    { data: { code }, rawRequest: { ip, headers: {} }, app: { appId: "android" } } as never,
  );

function tokenUid(token: string): string {
  const payload = JSON.parse(Buffer.from(token.split(".")[1], "base64url").toString("utf8"));
  return payload.uid as string;
}

async function clearEmulators() {
  const address = resolveEmulatorAddress("auth", "FIREBASE_AUTH_EMULATOR_HOST");
  await fetch(`http://${address.host}:${address.port}/emulator/v1/projects/${projectId}/accounts`, {
    method: "DELETE",
  });
  const collections = await firestore.listCollections();
  await Promise.all(collections.map((collection) => firestore.recursiveDelete(collection)));
}

/** La famille du propriétaire : un seul numéro, porté par l'accès de l'enfant. */
async function seedOwnerFamily() {
  await auth.createUser({ uid: "student-old", phoneNumber: phone });
  await firestore.doc("users/student-old").set({
    uid: "student-old",
    role: "student",
    firstName: "Awa",
    lastName: "Mbarga",
    phoneNumber: phone,
    establishmentId: "school-a",
    classLevel: "Terminale",
    profileCompleted: true,
  });
  await firestore.doc("student_profiles/student-old").set({
    uid: "student-old",
    firstName: "Awa",
    classLevel: "Terminale",
    phoneNumber: phone,
    linkCode: "ABCDEFGH",
  });
  await firestore.doc("study_reserves/student-old").set({ studentId: "student-old", remaining: 12 });
  await firestore.doc("users/student-old/progress/math").set({ mastered: 42 });
}

async function everyDocumentText(): Promise<string> {
  const texts: string[] = [];
  const walk = async (collections: FirebaseFirestore.CollectionReference[]) => {
    for (const collection of collections) {
      const snapshot = await collection.get();
      for (const document of snapshot.docs) {
        texts.push(document.id, JSON.stringify(document.data()));
        await walk(await document.ref.listCollections());
      }
    }
  };
  await walk(await firestore.listCollections());
  return texts.join("\n");
}

beforeEach(clearEmulators);
afterAll(async () => {
  await firestore.terminate();
  await deleteApp(app);
});

describe("owner regression — the family phone opened the student", () => {
  it("offers the migration, opens the parent, links the child, keeps the student, and the access code signs the student in", async () => {
    await seedOwnerFamily();
    const port = new FaultyAuth();
    const result = await migrationHandler(port)({ auth: phoneSession("student-old"), data: confirmation } as never);

    // Le numéro ouvre désormais un parent distinct.
    const parent = await auth.getUserByPhoneNumber(phone);
    expect(parent.uid).toBe(result.parentUid);
    expect(parent.uid).not.toBe("student-old");
    expect(tokenUid(result.parentToken!)).toBe(result.parentUid);
    // L'élève : même UID, plus de téléphone, toutes ses données.
    expect((await auth.getUser("student-old")).phoneNumber).toBeUndefined();
    const student = (await firestore.doc("users/student-old").get()).data()!;
    expect(student).toMatchObject({ role: "student", firstName: "Awa", establishmentId: "school-a", classLevel: "Terminale" });
    expect(student.phoneNumber).toBeUndefined();
    expect((await firestore.doc("study_reserves/student-old").get()).data()).toEqual({ studentId: "student-old", remaining: 12 });
    expect((await firestore.doc("users/student-old/progress/math").get()).data()).toEqual({ mastered: 42 });
    expect((await firestore.doc("student_profiles/student-old").get()).data()?.linkCode).toBe("ABCDEFGH");
    // Le lien parent ↔ enfant est approuvé.
    expect((await firestore.doc(`children_links/${result.parentUid}_student-old`).get()).data())
      .toMatchObject({ parentId: result.parentUid, studentId: "student-old", status: "approved" });
    // Le code d'accès fonctionne et n'est écrit nulle part en clair.
    const code = result.studentAccessCode!;
    expect(tokenUid((await signIn(code)).token)).toBe("student-old");
    const everything = await everyDocumentText();
    expect(everything).not.toContain(code);
    expect(everything).not.toContain(code.replaceAll("-", ""));
    // Le journal est terminé.
    expect((await firestore.doc(`auth_phone_migrations/${familyPhoneKey(phone, pepper)}`).get()).data()?.status)
      .toBe("completed");
  });

  it("the parent can rotate the code afterwards; the old code stops working at once", async () => {
    await seedOwnerFamily();
    const result = await migrationHandler(new FaultyAuth())({ auth: phoneSession("student-old"), data: confirmation } as never);
    const issue = createIssueStudentAccessCodeHandler(() => pepper, accessStore);
    // Tant que le parent n'a pas rempli son profil, il n'agit pas encore en parent.
    await expect(issue({ auth: { uid: result.parentUid }, data: { studentId: "student-old" } } as never))
      .rejects.toMatchObject({ code: "permission-denied" });
    // Profil parent créé par l'inscription téléphone d'abord de l'application.
    await firestore.doc(`users/${result.parentUid}`).set({ role: "parent", phoneNumber: phone, profileCompleted: true });
    const rotated = await issue({ auth: { uid: result.parentUid }, data: { studentId: "student-old" } } as never);
    await expect(signIn(result.studentAccessCode!)).rejects.toMatchObject({ code: "permission-denied" });
    expect(tokenUid((await signIn(rotated.code)).token)).toBe("student-old");
    const audit = await firestore.collection("student_access_audit").where("studentId", "==", "student-old").get();
    expect(audit.docs.map((entry) => entry.data().type).sort())
      .toEqual(["issued", "phone_moved_to_parent", "rotated"]);
  });
});

describe("failure halfway through, on real Auth", () => {
  it("parent creation fails: the student gets the number back and a retry completes", async () => {
    await seedOwnerFamily();
    const port = new FaultyAuth();
    port.faults.createPhoneUser = 1;
    await expect(migrationHandler(port)({ auth: phoneSession("student-old"), data: confirmation } as never))
      .rejects.toMatchObject({ code: "unavailable", details: { reason: "migration-compensated" } });
    expect((await auth.getUserByPhoneNumber(phone)).uid).toBe("student-old");
    expect((await firestore.collection("children_links").get()).size).toBe(0);
    expect((await firestore.doc("users/student-old").get()).data()?.phoneNumber).toBe(phone);

    const retry = await migrationHandler(port)({ auth: phoneSession("student-old"), data: confirmation } as never);
    expect((await auth.getUserByPhoneNumber(phone)).uid).toBe(retry.parentUid);
    expect(tokenUid((await signIn(retry.studentAccessCode!)).token)).toBe("student-old");
  });

  it("parent creation and compensation fail: the code opens the student, a new SMS adopts the fresh identity as parent", async () => {
    await seedOwnerFamily();
    const port = new FaultyAuth();
    port.faults.createPhoneUser = 1;
    port.faults.attachPhone = 1;
    const failure = await migrationHandler(port)({ auth: phoneSession("student-old"), data: confirmation } as never)
      .catch((error: { code: string; details: { reason: string; studentAccessCode: string } }) => error);
    expect(failure).toMatchObject({ code: "unavailable", details: { reason: "migration-needs-recovery" } });
    const code = (failure as { details: { studentAccessCode: string } }).details.studentAccessCode;
    expect(tokenUid((await signIn(code)).token)).toBe("student-old");
    await expect(auth.getUserByPhoneNumber(phone)).rejects.toMatchObject({ code: "auth/user-not-found" });

    // Nouvelle vérification SMS du numéro libre : Firebase crée une identité vierge.
    const fresh = await auth.createUser({ phoneNumber: phone });
    const later = Date.now() + migrationLeaseMs + 1000;
    const resumed = await migrationHandler(port, () => later)(
      { auth: phoneSession(fresh.uid, later - 5000), data: confirmation } as never,
    );
    expect(resumed).toMatchObject({ parentUid: fresh.uid, parentToken: null, studentId: "student-old" });
    expect((await firestore.doc(`children_links/${fresh.uid}_student-old`).get()).data()?.status).toBe("approved");
    expect(tokenUid((await signIn(code)).token)).toBe("student-old");
  });
});

describe("a new family whose child has no phone, on real Auth", () => {
  it("the parent opens the child's access: phoneless identity, approved link, a code that signs the child in, and a pending child in the parent's list", async () => {
    await auth.createUser({ uid: "parent-p", phoneNumber: "+237699000555" });
    await firestore.doc("users/parent-p").set({ role: "parent", accountStatus: "active" });
    const create = createCreateChildStudentAccessHandler({
      pepper: () => pepper,
      store: new FirestoreChildAccessCreationStore(firestore),
      access: accessStore,
      identities: new AdminChildIdentityPort(() => auth),
    });
    const payload = { firstName: "Awa", requestId: "7c9e6679-7425-40de-944b-e07fc1f90ae7" };
    const created = await create({ auth: { uid: "parent-p" }, data: payload } as never);

    // Une identité élève sans téléphone ni e-mail.
    const identity = await auth.getUser(created.studentId);
    expect(identity.phoneNumber).toBeUndefined();
    expect(identity.email).toBeUndefined();
    expect((await firestore.doc(`children_links/parent-p_${created.studentId}`).get()).data())
      .toMatchObject({ status: "approved", linkedVia: "parent_created_access" });

    // Le code ouvre cet élève, sans SMS.
    expect(tokenUid((await signIn(created.code!)).token)).toBe(created.studentId);

    // Le parent le voit, en attente de première connexion.
    const listChildren = createListParentChildrenHandler(new FirestoreParentChildrenStore(firestore, () => auth));
    const { children } = await listChildren({ auth: { uid: "parent-p" }, data: {} } as never);
    expect(children).toHaveLength(1);
    expect(children[0]).toMatchObject({
      studentId: created.studentId,
      status: "pending_first_sign_in",
      firstName: "Awa",
      access: { ownPhone: false, accessCode: true },
    });

    // Réponse perdue : pas de second enfant, pas de second code révélé.
    const replay = await create({ auth: { uid: "parent-p" }, data: payload } as never);
    expect(replay).toEqual({ studentId: created.studentId, firstName: "Awa", code: null });
    expect((await auth.listUsers()).users).toHaveLength(2);

    // Le parent remplace le code : l'ancien cesse aussitôt de fonctionner.
    const rotated = await createIssueStudentAccessCodeHandler(() => pepper, accessStore)(
      { auth: { uid: "parent-p" }, data: { studentId: created.studentId } } as never,
    );
    await expect(signIn(created.code!, "203.0.113.77")).rejects.toMatchObject({ code: "permission-denied" });
    expect(tokenUid((await signIn(rotated.code, "203.0.113.78")).token)).toBe(created.studentId);
  });
});

describe("student access code on real Firestore", () => {
  it("blocks a client after repeated failures and survives across handler instances", async () => {
    await seedOwnerFamily();
    for (let attempt = 0; attempt < studentAccessRateLimit.maxFailures; attempt++) {
      await expect(signIn("ZZZZ-ZZZZ-ZZZZ", "198.51.100.9")).rejects.toMatchObject({ code: "permission-denied" });
    }
    await expect(signIn("ZZZZ-ZZZZ-ZZZZ", "198.51.100.9")).rejects.toMatchObject({ code: "resource-exhausted" });
    const stored = await firestore.collection("student_access_attempts").get();
    expect(stored.size).toBe(1);
    expect(stored.docs[0].id).not.toContain("198.51.100.9");
  });
});
