import { readFileSync } from "node:fs";
import { join } from "node:path";
import {
  RulesTestEnvironment,
  assertFails,
  assertSucceeds,
  initializeTestEnvironment
} from "@firebase/rules-unit-testing";
import { getBytes, ref, uploadBytes } from "firebase/storage";
import { doc, setDoc } from "firebase/firestore";
import { afterAll, afterEach, beforeAll, describe, it } from "vitest";

const projectId = "demo-intellia237";

let testEnv: RulesTestEnvironment;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: {
      host: "127.0.0.1", port: 8085,
      rules: readFileSync(join(process.cwd(), "../firestore.rules"), "utf8"),
    },
    storage: {
      host: "127.0.0.1",
      port: 9200,
      rules: readFileSync(join(process.cwd(), "../storage.rules"), "utf8")
    }
  });
});

afterEach(async () => {
  await testEnv.clearStorage();
  await testEnv.clearFirestore();
});

afterAll(async () => {
  await testEnv.cleanup();
});

function storageFor(uid?: string) {
  return uid
    ? testEnv.authenticatedContext(uid).storage()
    : testEnv.unauthenticatedContext().storage();
}

async function seedAvatar() {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await uploadBytes(
      ref(context.storage(), "avatars/student-a/avatar.png"),
      new Uint8Array([1, 2, 3]),
      { contentType: "image/png" }
    );
  });
}

describe("Storage security rules", () => {
  it("blocks avatar writes from a suspended user holding an old token", async () => {
    await testEnv.withSecurityRulesDisabled(async context => {
      await setDoc(doc(context.firestore(), "users/student-a"), {
        role: "student", accountStatus: "suspended",
      });
    });
    await assertFails(uploadBytes(ref(storageFor("student-a"), "avatars/student-a/avatar.png"),
      new Uint8Array([1, 2, 3]), {contentType: "image/png"}));
  });
  it("blocks unauthenticated avatar reads", async () => {
    await seedAvatar();

    await assertFails(getBytes(ref(storageFor(), "avatars/student-a/avatar.png")));
  });

  it("allows authenticated users to read avatars according to current rules", async () => {
    await seedAvatar();

    await assertSucceeds(getBytes(ref(storageFor("student-b"), "avatars/student-a/avatar.png")));
  });

  it("allows writing to the authenticated user's own avatar folder", async () => {
    await assertSucceeds(uploadBytes(
      ref(storageFor("student-a"), "avatars/student-a/avatar.png"),
      new Uint8Array([1, 2, 3]),
      { contentType: "image/png" }
    ));
  });

  it("allows supported avatar image MIME types", async () => {
    await assertSucceeds(uploadBytes(
      ref(storageFor("student-a"), "avatars/student-a/avatar.webp"),
      new Uint8Array([1, 2, 3]),
      { contentType: "image/webp" }
    ));
    await assertSucceeds(uploadBytes(
      ref(storageFor("student-a"), "avatars/student-a/avatar.jpg"),
      new Uint8Array([1, 2, 3]),
      { contentType: "image/jpeg" }
    ));
  });

  it("blocks writing to another user's avatar folder", async () => {
    await assertFails(uploadBytes(
      ref(storageFor("student-b"), "avatars/student-a/avatar.png"),
      new Uint8Array([1, 2, 3]),
      { contentType: "image/png" }
    ));
  });

  it("blocks client writes to course images", async () => {
    await assertFails(uploadBytes(
      ref(storageFor("teacher-a"), "courses/course-a/images/image.png"),
      new Uint8Array([1, 2, 3]),
      { contentType: "image/png" }
    ));
  });

  it("blocks avatar uploads larger than five megabytes", async () => {
    await assertFails(uploadBytes(
      ref(storageFor("student-a"), "avatars/student-a/large-avatar.bin"),
      new Uint8Array(6 * 1024 * 1024),
      { contentType: "image/png" }
    ));
  });

  it("blocks unsupported or missing avatar MIME types", async () => {
    await assertFails(uploadBytes(
      ref(storageFor("student-a"), "avatars/student-a/avatar.txt"),
      new Uint8Array([1, 2, 3]),
      { contentType: "text/plain" }
    ));
    await assertFails(uploadBytes(
      ref(storageFor("student-a"), "avatars/student-a/avatar.bin"),
      new Uint8Array([1, 2, 3])
    ));
  });
});
