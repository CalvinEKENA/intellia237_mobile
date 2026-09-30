import {
  FieldPath,
  type DocumentReference,
  type DocumentSnapshot,
  type Firestore,
  type DocumentData,
  type Query,
  type QueryDocumentSnapshot,
} from "firebase-admin/firestore";
import { HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import { z } from "zod";
import { db } from "../config/firebase";
import { audienceAllows, canonicalClass, learnAudienceContextClass, learnerFlowAudienceKeys } from "./contentAudience";
import { getEnv } from "../config/env";
import { publishedLessonAllows } from "./educationalMedia";

const segment = z.string().min(1).max(400).regex(/^[^/\\]+$/);
const inputSchema = z.object({ action: z.enum(["subjects", "subject", "chapters", "chapter", "lessons", "lesson", "flow"]),
  classLevel: segment, subjectId: segment.optional(), chapterId: segment.optional(), lessonId: segment.optional(),
  cursor: z.string().max(160).optional(), limit: z.number().int().min(1).max(100).default(100),
});
const clean = (data: DocumentData): DocumentData => {
  const result = { ...data };
  // These old denormalized indexes can contain titles outside the learner's audience.
  for (const key of ["chapterSummaries", "lessonPreviews", "lessonCountsByScope", "lessonsCount"]) delete result[key];
  return result;
};
const wire = (data: unknown): unknown => {
  if (data && typeof (data as { toDate?: unknown }).toDate === "function") return (data as { toDate(): Date }).toDate().toISOString();
  if (data instanceof Date) return data.toISOString();
  if (Array.isArray(data)) return data.map(wire);
  if (data && typeof data === "object") return Object.fromEntries(Object.entries(data).map(([k, v]) => [k, wire(v)]));
  return data;
};

/** True when a catalog document states which class(es) it is for. */
export function declaresClass(data: DocumentData): boolean {
  const list = (value: unknown) => Array.isArray(value) && value.some(v => typeof v === "string" && v.trim().length > 0);
  if (data.audience?.clauses && Array.isArray(data.audience.clauses)) {
    return data.audience.clauses.some((clause: DocumentData) => list(clause.classLevels));
  }
  return list(data.classLevels) || (typeof data.classLevel === "string" && data.classLevel.trim().length > 0);
}

export function createLearningCatalogHandler(firestore: Firestore = db) {
  return async (request: CallableRequest) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Connexion requise.");
    const parsed = inputSchema.safeParse(request.data);
    if (!parsed.success) throw new HttpsError("invalid-argument", "Référence de catalogue invalide.");
    const input = parsed.data;
    const [userDoc, profileDoc] = await Promise.all([firestore.doc(`users/${request.auth.uid}`).get(), firestore.doc(`student_profiles/${request.auth.uid}`).get()]);
    const actor = userDoc.data() || {}, profile = profileDoc.data() || {};
    const allowed = (data: DocumentData, level?: string) => !data.deleting && audienceAllows(data, actor, profile, level);
    const result = (docs: QueryDocumentSnapshot[], level: string) => docs.filter(d => allowed(d.data(), level))
      .sort((a, b) => (a.data().order || 0) - (b.data().order || 0))
      .map(d => ({ id: d.id, data: clean(d.data()) }));
    if (input.action === "flow") {
      return wire(await readFlowPage(firestore, {
        actor,
        profile,
        requestedClassLevel: input.classLevel,
        cursor: input.cursor,
        limit: input.limit,
        allowed,
      }));
    }
    if (input.action === "subjects") {
      const documents = [];
      let last: QueryDocumentSnapshot | undefined;
      do {
        let query = firestore.collectionGroup("subjects").where("status", "==", "published").orderBy(FieldPath.documentId()).limit(200);
        if (last) query = query.startAfter(last);
        const snapshot = await query.get();
        for (const doc of snapshot.docs) {
          const path = doc.ref.path.split("/");
          if (path.length !== 4 || path[0] !== "classes" || !allowed(doc.data(), path[1])) continue;
          // Opaque cross-class reference avoids collisions between historical subject IDs.
          const id = canonicalClass(path[1]) === canonicalClass(input.classLevel) ? doc.id : `${path[1]}~${doc.id}`;
          documents.push({ id, data: clean(doc.data()) });
        }
        last = snapshot.size === 200 ? snapshot.docs.at(-1) : undefined;
      } while (last);
      documents.sort((a, b) => (a.data.order || 0) - (b.data.order || 0));
      return wire({ documents });
    }
    if (!input.subjectId) throw new HttpsError("invalid-argument", "Matière requise.");
    const cross = input.subjectId.indexOf("~");
    let level = cross < 0 ? input.classLevel : input.subjectId.slice(0, cross);
    const subjectId = cross < 0 ? input.subjectId : input.subjectId.slice(cross + 1);
    let subjectRef = firestore.doc(`classes/${level}/subjects/${subjectId}`);
    let subject = await subjectRef.get();
    if (!subject.exists && canonicalClass(level) === "Premiere") {
      level = level === "Première" ? "Premiere" : "Première";
      subjectRef = firestore.doc(`classes/${level}/subjects/${subjectId}`); subject = await subjectRef.get();
    }
    if (!subject.exists || subject.data()!.status !== "published" || !allowed(subject.data()!, level)) return { documents: [] };
    if (input.action === "subject") return wire({ documents: [{ id: input.subjectId, data: clean(subject.data()!) }] });
    const inherited = (data: DocumentData) => data.audience === undefined && subject.data()!.audience
      ? { ...data, audience: subject.data()!.audience } : data;
    const visibleChapter = async (doc: FirebaseFirestore.DocumentSnapshot) => {
      if (!doc.exists || !allowed(inherited(doc.data()!), level)) return null;
      // A chapter whose class is declared nowhere (chapter or subject) is not
      // served: its location alone proves nothing (legacy seeds copied the
      // same first-cycle course under several classes).
      if (!declaresClass(doc.data()!) && !declaresClass(subject.data()!)) return null;
      const lessons = await doc.ref.collection("lessons").where("status", "==", "published").get();
      const previews = result(lessons.docs, level).map(item => ({ id: item.id, title: item.data.title || "",
        summary: item.data.summary || "", order: item.data.order || 0, estimatedMinutes: item.data.estimatedMinutes || 20,
        scope: item.data.scope || { type: "global" } }));
      return { id: doc.id, data: { ...clean(doc.data()!), lessonsCount: previews.length, lessonPreviews: previews } };
    };
    if (input.action === "chapters") {
      const documents = await Promise.all((await subjectRef.collection("chapters").get()).docs.map(visibleChapter));
      return wire({ documents: documents.filter(d => d != null && d.data.lessonsCount > 0) });
    }
    if (!input.chapterId) throw new HttpsError("invalid-argument", "Chapitre requis.");
    const chapterRef = subjectRef.collection("chapters").doc(input.chapterId);
    const chapter = await chapterRef.get();
    if (!chapter.exists || !allowed(inherited(chapter.data()!), level)) return { documents: [] };
    if (input.action === "chapter") return wire({ documents: [await visibleChapter(chapter)].filter(Boolean) });
    if (input.action === "lessons") return wire({ documents: result((await chapterRef.collection("lessons").where("status", "==", "published").get()).docs, level) });
    if (!input.lessonId) throw new HttpsError("invalid-argument", "Leçon requise.");
    const lesson = await chapterRef.collection("lessons").doc(input.lessonId).get();
    return wire({ documents: lesson.exists && lesson.data()!.status === "published" && allowed(lesson.data()!, level)
      ? [{ id: lesson.id, data: clean(lesson.data()!) }] : [] });
  };
}

/**
 * Page Parcours bornée.
 *
 * - au plus FLOW_MAX_ITEMS_PER_PAGE publications visibles par appel ;
 * - au plus FLOW_MAX_SCAN documents lus par appel, jamais tout `flow_items` ;
 * - une page peut revenir courte avec un curseur : le client ne boucle pas,
 *   il redemande quand l'élève approche de la fin ;
 * - les leçons sources, leurs chapitres et matières sont lus une fois chacun
 *   par appel, en parallèle, au lieu d'une chaîne de lectures par carte ;
 * - avec FLOW_AUDIENCE_INDEX, la requête ne lit que les publications dont la
 *   clé d'audience peut concerner l'élève, les plus récentes d'abord.
 */
export const FLOW_MAX_ITEMS_PER_PAGE = 30;
export const FLOW_SCAN_BATCH = 50;
export const FLOW_MAX_SCAN = 200;

export async function readFlowPage(
  firestore: Firestore,
  params: {
    actor: DocumentData;
    profile: DocumentData;
    requestedClassLevel: string;
    cursor?: string;
    limit: number;
    allowed: (data: DocumentData) => boolean;
    indexed?: boolean;
  },
): Promise<{ documents: Array<{ id: string; data: DocumentData }>; nextCursor: string | null }> {
  const wanted = Math.max(1, Math.min(params.limit, FLOW_MAX_ITEMS_PER_PAGE));
  const indexed = params.indexed ?? getEnv().FLOW_AUDIENCE_INDEX;
  let query: Query = firestore.collection("flow_items").where("status", "==", "published");
  let after: DocumentSnapshot | string | undefined = params.cursor;
  if (indexed) {
    const level = learnAudienceContextClass(params.actor, params.profile) || params.requestedClassLevel;
    query = query
      .where("audienceKeys", "array-contains-any", learnerFlowAudienceKeys(level))
      .orderBy("publishedAt", "desc")
      .orderBy(FieldPath.documentId(), "desc");
    if (params.cursor) {
      const cursorDoc = await firestore.collection("flow_items").doc(params.cursor).get();
      after = cursorDoc.exists ? cursorDoc : undefined;
    }
  } else {
    query = query.orderBy(FieldPath.documentId());
  }

  const lessonReads = new Map<string, Promise<DocumentSnapshot>>();
  const memoRead = (ref: DocumentReference) => {
    let read = lessonReads.get(ref.path);
    if (!read) {
      read = ref.get();
      lessonReads.set(ref.path, read);
    }
    return read;
  };

  const items: Array<{ id: string; data: DocumentData }> = [];
  let scanned = 0;
  let lastConsumed: QueryDocumentSnapshot | undefined;
  let exhausted = false;
  const now = Date.now();
  while (items.length < wanted && scanned < FLOW_MAX_SCAN) {
    let page = query.limit(Math.min(FLOW_SCAN_BATCH, FLOW_MAX_SCAN - scanned));
    const start = lastConsumed ?? after;
    if (start !== undefined) page = page.startAfter(start);
    const snapshot = await page.get();
    scanned += snapshot.size;
    const verdicts = await Promise.all(snapshot.docs.map(async (doc) => {
      const data = doc.data();
      if (!params.allowed(data)) return false;
      if (data.scheduledAt && new Date(String(wire(data.scheduledAt))).getTime() > now) return false;
      if (data.sourceLessonPath) {
        return publishedLessonAllows(firestore, data.sourceLessonPath, params.actor, params.profile, memoRead);
      }
      return true;
    }));
    let stoppedEarly = false;
    for (let index = 0; index < snapshot.docs.length; index++) {
      if (items.length >= wanted) {
        stoppedEarly = true;
        break;
      }
      const doc = snapshot.docs[index];
      lastConsumed = doc;
      if (verdicts[index]) items.push({ id: doc.id, data: doc.data() });
    }
    if (!stoppedEarly && snapshot.size < FLOW_SCAN_BATCH) {
      exhausted = true;
      break;
    }
    if (snapshot.empty) {
      exhausted = true;
      break;
    }
  }
  return {
    documents: items,
    nextCursor: exhausted || lastConsumed === undefined ? null : lastConsumed.id,
  };
}
