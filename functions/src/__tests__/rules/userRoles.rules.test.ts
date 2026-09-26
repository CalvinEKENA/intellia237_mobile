import { readFileSync } from "node:fs";
import { join } from "node:path";
import {
  RulesTestEnvironment,
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from "@firebase/rules-unit-testing";
import { doc, getDoc, setDoc, updateDoc } from "firebase/firestore";
import { afterAll, afterEach, beforeAll, beforeEach, describe, it } from "vitest";

import { resolveEmulatorAddress } from "./emulator-address";

/**
 * `roles: string[]` (espaces additifs) : lecture par les règles, et aucune
 * écriture possible depuis un client autre que la super-administration.
 * Refonte Auth V2 — voir functions/src/auth/userRoles.ts.
 */
const projectId = "demo-intellia237";
let testEnv: RulesTestEnvironment;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: {
      ...resolveEmulatorAddress("firestore", "FIRESTORE_EMULATOR_HOST"),
      rules: readFileSync(join(process.cwd(), "../firestore.rules"), "utf8"),
    },
  });
});

beforeEach(async () => {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, "users/root"), { role: "superAdmin" });
    await setDoc(doc(db, "users/parent-a"), { uid: "parent-a", role: "parent", firstName: "Awa" });
    await setDoc(doc(db, "users/teacher-a"), {
      uid: "teacher-a",
      role: "teacher",
      establishmentId: "school-a",
      accountStatus: "active",
    });
    // Parent ET enseignante : rôle principal enseignant, espace parent additif.
    await setDoc(doc(db, "users/teacher-parent"), {
      uid: "teacher-parent",
      role: "teacher",
      roles: ["teacher", "parent"],
      establishmentId: "school-a",
      accountStatus: "active",
    });
    // Données incohérentes plantées côté serveur : jamais d'effet.
    await setDoc(doc(db, "users/student-with-roles"), {
      uid: "student-with-roles",
      role: "student",
      roles: ["student", "teacher", "admin"],
      establishmentId: "school-a",
    });
    await setDoc(doc(db, "users/parent-claims-root"), {
      uid: "parent-claims-root",
      role: "parent",
      roles: ["parent", "superAdmin"],
    });
    await setDoc(doc(db, "users/student-a"), {
      uid: "student-a",
      role: "student",
      establishmentId: "school-a",
    });
    await setDoc(doc(db, "users/student-b"), {
      uid: "student-b",
      role: "student",
      establishmentId: "school-b",
    });
    await setDoc(doc(db, "student_profiles/student-a"), { firstName: "Noah", points: 0 });
    await setDoc(doc(db, "children_links/teacher-parent_student-b"), {
      parentId: "teacher-parent",
      studentId: "student-b",
      status: "approved",
    });
    await setDoc(doc(db, "student_profiles/student-b"), { firstName: "Lina", points: 0 });
  });
});

afterEach(async () => {
  await testEnv.clearFirestore();
});

afterAll(async () => {
  await testEnv.cleanup();
});

const googleToken = {
  firebase: { sign_in_provider: "google.com" as const },
  email: "someone@example.cm",
};

describe("roles[] writes", () => {
  it("denies a new Google identity creating its profile with roles ['admin']", async () => {
    const db = testEnv.authenticatedContext("google-new", googleToken).firestore();
    await assertFails(
      setDoc(doc(db, "users/google-new"), {
        uid: "google-new",
        role: "parent",
        roles: ["admin"],
        firstName: "G",
      }),
    );
    // Sans `roles`, l'auto-création parent reste possible.
    await assertSucceeds(
      setDoc(doc(db, "users/google-new"), { uid: "google-new", role: "parent", firstName: "G" }),
    );
  });

  it("denies a parent adding the teacher space to itself", async () => {
    const db = testEnv.authenticatedContext("parent-a").firestore();
    await assertFails(updateDoc(doc(db, "users/parent-a"), { roles: ["parent", "teacher"] }));
  });

  it("denies a teacher adding the parent space to itself", async () => {
    const db = testEnv.authenticatedContext("teacher-a").firestore();
    await assertFails(updateDoc(doc(db, "users/teacher-a"), { roles: ["teacher", "parent"] }));
  });

  it("denies a multi-space owner removing or reshaping its spaces", async () => {
    const db = testEnv.authenticatedContext("teacher-parent").firestore();
    await assertFails(updateDoc(doc(db, "users/teacher-parent"), { roles: ["teacher", "parent", "admin"] }));
    await assertFails(updateDoc(doc(db, "users/teacher-parent"), { role: "admin" }));
  });

  it("denies an owner changing its own establishment", async () => {
    const db = testEnv.authenticatedContext("teacher-a").firestore();
    await assertFails(updateDoc(doc(db, "users/teacher-a"), { establishmentId: "school-b" }));
  });

  it("allows the super-administration to write roles", async () => {
    const db = testEnv.authenticatedContext("root").firestore();
    await assertSucceeds(
      updateDoc(doc(db, "users/parent-a"), { role: "parent", roles: ["parent", "teacher"] }),
    );
  });
});

describe("roles[] reads", () => {
  it("lets a teacher+parent read its linked child as a parent", async () => {
    const db = testEnv.authenticatedContext("teacher-parent").firestore();
    await assertSucceeds(getDoc(doc(db, "student_profiles/student-b")));
  });

  it("lets a teacher+parent act as a teacher of its establishment", async () => {
    const db = testEnv.authenticatedContext("teacher-parent").firestore();
    await assertSucceeds(getDoc(doc(db, "users/student-a")));
  });

  it("never grants staff spaces through roles to a student account", async () => {
    const db = testEnv.authenticatedContext("student-with-roles").firestore();
    await assertFails(getDoc(doc(db, "student_profiles/student-a")));
    await assertFails(getDoc(doc(db, "users/student-a")));
  });

  it("never grants the super-administration through roles", async () => {
    const db = testEnv.authenticatedContext("parent-claims-root").firestore();
    await assertFails(getDoc(doc(db, "users/student-a")));
  });

  it("revocation: once the server removes the parent space, the link no longer opens the child", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), "users/teacher-parent"), {
        uid: "teacher-parent",
        role: "teacher",
        establishmentId: "school-a",
        accountStatus: "active",
      });
    });
    const db = testEnv.authenticatedContext("teacher-parent").firestore();
    await assertFails(getDoc(doc(db, "student_profiles/student-b")));
  });
});
