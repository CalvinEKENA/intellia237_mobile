import { readFileSync } from "node:fs";
import { join } from "node:path";
import {
  RulesTestEnvironment,
  assertFails,
  assertSucceeds,
  initializeTestEnvironment
} from "@firebase/rules-unit-testing";
import { doc, setDoc } from "firebase/firestore";
import { ref, uploadBytes } from "firebase/storage";
import { afterAll, afterEach, beforeAll, describe, it } from "vitest";

/**
 * Règles des ressources pédagogiques.
 *
 * Deux garanties s'y jouent : le cloisonnement — un établissement ne touche
 * pas aux ressources d'un autre — et les plafonds par nature de média. Un
 * plafond global unique laissait passer une image de 300 Mo.
 *
 * Ces règles interrogent Firestore pour le rôle et l'établissement de
 * l'appelant : l'émulateur Firestore est donc requis en plus du Storage.
 */
const projectId = "demo-intellia237";

let testEnv: RulesTestEnvironment;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: {
      host: "127.0.0.1",
      port: 8080,
      rules: readFileSync(join(process.cwd(), "../firestore.rules"), "utf8")
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
});

afterAll(async () => {
  await testEnv.cleanup();
});

/** Les règles lisent `users/{uid}` : chaque acteur doit y exister. */
async function seedActors() {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, "users/admin-a"), {
      uid: "admin-a",
      role: "admin",
      establishmentId: "lycee-a",
      status: "active"
    });
    await setDoc(doc(db, "users/teacher-a"), {
      uid: "teacher-a",
      role: "teacher",
      establishmentId: "lycee-a",
      status: "active"
    });
    await setDoc(doc(db, "users/teacher-b"), {
      uid: "teacher-b",
      role: "teacher",
      establishmentId: "lycee-b",
      status: "active"
    });
    await setDoc(doc(db, "users/student-a"), {
      uid: "student-a",
      role: "student",
      establishmentId: "lycee-a",
      status: "active"
    });
  });
}

function storageFor(uid?: string) {
  return uid
    ? testEnv.authenticatedContext(uid).storage()
    : testEnv.unauthenticatedContext().storage();
}

function assetPath(scopeId: string, fileName: string) {
  return `educational_assets/${scopeId}/terminale/maths/lesson-1/asset-1/${fileName}`;
}

function bytes(size: number) {
  return new Uint8Array(size);
}

describe("Educational asset rules", () => {
  beforeAll(seedActors);

  describe("cloisonnement", () => {
    it("lets an administrator write the national curriculum", async () => {
      await assertSucceeds(
        uploadBytes(
          ref(storageFor("admin-a"), assetPath("global", "schema.png")),
          bytes(1024),
          { contentType: "image/png" }
        )
      );
    });

    it("blocks a teacher from writing the national curriculum", async () => {
      await assertFails(
        uploadBytes(
          ref(storageFor("teacher-a"), assetPath("global", "schema.png")),
          bytes(1024),
          { contentType: "image/png" }
        )
      );
    });

    it("lets a teacher write inside their own establishment", async () => {
      await assertSucceeds(
        uploadBytes(
          ref(storageFor("teacher-a"), assetPath("lycee-a", "schema.png")),
          bytes(1024),
          { contentType: "image/png" }
        )
      );
    });

    it("blocks a teacher from writing another establishment", async () => {
      await assertFails(
        uploadBytes(
          ref(storageFor("teacher-b"), assetPath("lycee-a", "schema.png")),
          bytes(1024),
          { contentType: "image/png" }
        )
      );
    });

    it("blocks a student from writing anywhere", async () => {
      await assertFails(
        uploadBytes(
          ref(storageFor("student-a"), assetPath("lycee-a", "schema.png")),
          bytes(1024),
          { contentType: "image/png" }
        )
      );
    });

    it("blocks unauthenticated writes", async () => {
      await assertFails(
        uploadBytes(
          ref(storageFor(), assetPath("global", "schema.png")),
          bytes(1024),
          { contentType: "image/png" }
        )
      );
    });
  });

  describe("plafonds par nature de média", () => {
    it("accepts an image under ten megabytes", async () => {
      await assertSucceeds(
        uploadBytes(
          ref(storageFor("admin-a"), assetPath("global", "schema.png")),
          bytes(2 * 1024 * 1024),
          { contentType: "image/png" }
        )
      );
    });

    it("blocks an image over ten megabytes", async () => {
      // C'est précisément ce que l'ancien plafond global laissait passer.
      await assertFails(
        uploadBytes(
          ref(storageFor("admin-a"), assetPath("global", "enorme.png")),
          bytes(11 * 1024 * 1024),
          { contentType: "image/png" }
        )
      );
    });

    it("accepts a JPEG and a WebP", async () => {
      await assertSucceeds(
        uploadBytes(
          ref(storageFor("admin-a"), assetPath("global", "photo.jpg")),
          bytes(1024),
          { contentType: "image/jpeg" }
        )
      );
      await assertSucceeds(
        uploadBytes(
          ref(storageFor("admin-a"), assetPath("global", "photo.webp")),
          bytes(1024),
          { contentType: "image/webp" }
        )
      );
    });

    it("blocks SVG", async () => {
      // Document actif, porteur de script, non assaini par le pipeline.
      await assertFails(
        uploadBytes(
          ref(storageFor("admin-a"), assetPath("global", "schema.svg")),
          bytes(1024),
          { contentType: "image/svg+xml" }
        )
      );
    });

    it("accepts the audio formats the pipeline handles", async () => {
      for (const contentType of [
        "audio/mpeg",
        "audio/mp4",
        "audio/m4a",
        "audio/aac"
      ]) {
        await assertSucceeds(
          uploadBytes(
            ref(
              storageFor("admin-a"),
              assetPath("global", `capsule-${contentType.split("/")[1]}`)
            ),
            bytes(1024),
            { contentType }
          )
        );
      }
    });

    it("accepts a PDF under twenty-five megabytes", async () => {
      await assertSucceeds(
        uploadBytes(
          ref(storageFor("admin-a"), assetPath("global", "fiche.pdf")),
          bytes(2 * 1024 * 1024),
          { contentType: "application/pdf" }
        )
      );
    });

    it("blocks an unsupported content type", async () => {
      await assertFails(
        uploadBytes(
          ref(storageFor("admin-a"), assetPath("global", "slides.pptx")),
          bytes(1024),
          { contentType: "application/vnd.ms-powerpoint" }
        )
      );
    });

    it("blocks an empty file", async () => {
      await assertFails(
        uploadBytes(
          ref(storageFor("admin-a"), assetPath("global", "vide.png")),
          bytes(0),
          { contentType: "image/png" }
        )
      );
    });
  });

  describe("lecture", () => {
    it("keeps establishment content inside its walls", async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await uploadBytes(
          ref(context.storage(), assetPath("lycee-a", "schema.png")),
          bytes(1024),
          { contentType: "image/png" }
        );
      });

      const { getBytes } = await import("firebase/storage");
      await assertFails(
        getBytes(ref(storageFor("teacher-b"), assetPath("lycee-a", "schema.png")))
      );
      await assertSucceeds(
        getBytes(ref(storageFor("teacher-a"), assetPath("lycee-a", "schema.png")))
      );
    });
  });
});
