import { readFileSync } from "node:fs";
import { join } from "node:path";
import {
  RulesTestEnvironment,
  assertFails,
  assertSucceeds,
  initializeTestEnvironment
} from "@firebase/rules-unit-testing";
import { getBytes, ref, uploadBytes } from "firebase/storage";
import { afterAll, afterEach, beforeAll, describe, it } from "vitest";

const projectId = "edunova-aabd1";

let testEnv: RulesTestEnvironment;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    storage: {
      host: "127.0.0.1",
      port: 9200,
      rules: readFileSync(join(process.cwd(), "../storage.rules"), "utf8")
    }
  });
});

afterEach(async () => {
  await testEnv.clearStorage();
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

  it("documents current risk: avatar rules do not limit file size", async () => {
    await assertSucceeds(uploadBytes(
      ref(storageFor("student-a"), "avatars/student-a/large-avatar.bin"),
      new Uint8Array(6 * 1024 * 1024),
      { contentType: "application/octet-stream" }
    ));
  });

  it("documents current risk: avatar rules do not restrict MIME type", async () => {
    await assertSucceeds(uploadBytes(
      ref(storageFor("student-a"), "avatars/student-a/avatar.txt"),
      new Uint8Array([1, 2, 3]),
      { contentType: "text/plain" }
    ));
  });
});
