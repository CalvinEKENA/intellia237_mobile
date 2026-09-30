import type { DocumentData } from "firebase-admin/firestore";
import { beforeAll, describe, expect, it } from "vitest";

import { db } from "../../config/firebase";
import { audienceAllows, flowAudienceKeys } from "../../services/contentAudience";
import {
  FLOW_MAX_ITEMS_PER_PAGE,
  FLOW_MAX_SCAN,
  readFlowPage,
} from "../../services/learningCatalogCallable";

/**
 * Pagination du fil Parcours contre le VRAI émulateur Firestore.
 */

if (!process.env.FIRESTORE_EMULATOR_HOST) {
  throw new Error("This test requires the Firestore emulator (--only firestore).");
}

const actor = { role: "student", establishmentId: "school-a", classLevel: "Terminale" };
const profile = { classLevel: "Terminale", preferences: { educationalSubsystem: "francophone" } };
const allowed = (data: DocumentData) => !data.deleting && audienceAllows(data, actor, profile);

async function clear() {
  for (const name of ["flow_items", "classes"]) {
    const snapshot = await db.collection(name).get();
    for (const doc of snapshot.docs) await db.recursiveDelete(doc.ref);
  }
}

function item(overrides: DocumentData = {}): DocumentData {
  const base = {
    status: "published",
    type: "notion",
    title: "Carte",
    classLevels: ["Terminale"],
    scope: { type: "global" },
    publishedAt: "2026-09-01T00:00:00.000Z",
    ...overrides,
  };
  return { ...base, audienceKeys: flowAudienceKeys(base) };
}

async function seedCatalog() {
  const batch = db.batch();
  // 60 publications visibles pour une élève de Terminale (ids m-000 … m-059).
  for (let index = 0; index < 60; index++) {
    const id = `m-${String(index).padStart(3, "0")}`;
    batch.set(db.collection("flow_items").doc(id), item({
      publishedAt: `2026-09-${String(1 + (index % 28)).padStart(2, "0")}T00:00:${String(index % 60).padStart(2, "0")}.000Z`,
    }));
  }
  // Invisibles : autre niveau, autre école, brouillon, programmée plus tard.
  batch.set(db.collection("flow_items").doc("x-6eme"), item({ classLevels: ["6eme"] }));
  batch.set(db.collection("flow_items").doc("x-school-b"), item({ scope: { type: "establishment", establishmentId: "school-b" } }));
  batch.set(db.collection("flow_items").doc("x-draft"), item({ status: "draft" }));
  batch.set(db.collection("flow_items").doc("x-scheduled"), item({ scheduledAt: "2099-01-01T00:00:00.000Z" }));
  // Leçon source : l'une publiée, l'autre non.
  batch.set(db.doc("classes/Terminale/subjects/svt"), { status: "published" });
  batch.set(db.doc("classes/Terminale/subjects/svt/chapters/c1"), { status: "published" });
  batch.set(db.doc("classes/Terminale/subjects/svt/chapters/c1/lessons/ok"), { status: "published" });
  batch.set(db.doc("classes/Terminale/subjects/svt/chapters/c1/lessons/draft"), { status: "draft" });
  batch.set(db.collection("flow_items").doc("m-lesson-ok"), item({ sourceLessonPath: "classes/Terminale/subjects/svt/chapters/c1/lessons/ok" }));
  batch.set(db.collection("flow_items").doc("x-lesson-draft"), item({ sourceLessonPath: "classes/Terminale/subjects/svt/chapters/c1/lessons/draft" }));
  await batch.commit();
}

async function readAll(indexed: boolean, limit: number) {
  const ids: string[] = [];
  let cursor: string | undefined;
  let calls = 0;
  do {
    const page = await readFlowPage(db, { actor, profile, requestedClassLevel: "Terminale", cursor, limit, allowed, indexed });
    calls += 1;
    expect(page.documents.length).toBeLessThanOrEqual(Math.min(limit, FLOW_MAX_ITEMS_PER_PAGE));
    ids.push(...page.documents.map((doc) => doc.id));
    cursor = page.nextCursor ?? undefined;
  } while (cursor && calls < 50);
  return { ids, calls };
}

describe("Parcours feed pagination", () => {
  beforeAll(async () => {
    await clear();
    await seedCatalog();
  });

  it("serves a small first page with a cursor instead of the whole catalog", async () => {
    const page = await readFlowPage(db, { actor, profile, requestedClassLevel: "Terminale", limit: 12, allowed, indexed: false });
    expect(page.documents).toHaveLength(12);
    expect(page.nextCursor).not.toBeNull();
  });

  it("walks every visible publication exactly once, and nothing else", async () => {
    const { ids } = await readAll(false, 12);
    expect(new Set(ids).size).toBe(ids.length);
    expect(ids).toHaveLength(61);
    expect(ids).toContain("m-lesson-ok");
    for (const hidden of ["x-6eme", "x-school-b", "x-draft", "x-scheduled", "x-lesson-draft"]) {
      expect(ids).not.toContain(hidden);
    }
  });

  it("caps a single call even when an old client asks for 100", async () => {
    const page = await readFlowPage(db, { actor, profile, requestedClassLevel: "Terminale", limit: 100, allowed, indexed: false });
    expect(page.documents).toHaveLength(FLOW_MAX_ITEMS_PER_PAGE);
    expect(page.nextCursor).not.toBeNull();
  });

  it("stops scanning after its read budget and returns a short page with a cursor", async () => {
    await clear();
    const batch = db.batch();
    // Plus de publications invisibles que le budget d'un appel, placées avant
    // la seule visible dans l'ordre de lecture.
    for (let index = 0; index < FLOW_MAX_SCAN + 20; index++) {
      batch.set(db.collection("flow_items").doc(`a-${String(index).padStart(4, "0")}`), item({ classLevels: ["6eme"] }));
    }
    batch.set(db.collection("flow_items").doc("z-visible"), item());
    await batch.commit();

    const first = await readFlowPage(db, { actor, profile, requestedClassLevel: "Terminale", limit: 12, allowed, indexed: false });
    expect(first.documents).toHaveLength(0);
    expect(first.nextCursor).not.toBeNull();
    const second = await readFlowPage(db, { actor, profile, requestedClassLevel: "Terminale", cursor: first.nextCursor!, limit: 12, allowed, indexed: false });
    expect(second.documents.map((doc) => doc.id)).toEqual(["z-visible"]);
    expect(second.nextCursor).toBeNull();

    // La lecture indexée ignore les publications d'un autre niveau sans les lire.
    const indexed = await readFlowPage(db, { actor, profile, requestedClassLevel: "Terminale", limit: 12, allowed, indexed: true });
    expect(indexed.documents.map((doc) => doc.id)).toEqual(["z-visible"]);
    expect(indexed.nextCursor).toBeNull();
    await clear();
    await seedCatalog();
  });

  it("with the audience index, serves the newest publications first, without duplicates", async () => {
    const { ids } = await readAll(true, 12);
    expect(new Set(ids).size).toBe(ids.length);
    expect(ids).toHaveLength(61);
    const first = await readFlowPage(db, { actor, profile, requestedClassLevel: "Terminale", limit: 5, allowed, indexed: true });
    const dates = await Promise.all(first.documents.map(async (doc) => (await db.doc(`flow_items/${doc.id}`).get()).get("publishedAt") as string));
    expect([...dates].sort().reverse()).toEqual(dates);
  });
});

describe("flow audience keys", () => {
  it("are a superset of the learners the audience admits", () => {
    expect(flowAudienceKeys({ classLevels: ["Terminale", "tle"] })).toEqual(["lvl:Terminale"]);
    expect(flowAudienceKeys({})).toEqual(["lvl:*"]);
    expect(flowAudienceKeys({
      audience: { version: 1, clauses: [{ classLevels: ["6e"] }, { educationSystems: ["anglophone"] }] },
    })).toEqual(["lvl:*", "lvl:6eme"]);
  });
});
