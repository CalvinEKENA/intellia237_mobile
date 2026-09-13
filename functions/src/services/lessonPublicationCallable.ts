import { createHash } from "node:crypto";
import { FieldValue, type DocumentData, type Firestore } from "firebase-admin/firestore";
import { HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import { z } from "zod";
import { db } from "../config/firebase";
import { buildScoringQuizRecord } from "./quizAnswerKeys";

const id = z.string().trim().min(1).max(160).regex(/^[^/]+$/);
const location = z.object({ classLevel: id, subjectId: id, chapterId: id, lessonId: id });
const miniQuestion = z.object({
  id: z.string().max(160), prompt: z.string().trim().min(1).max(3000),
  options: z.array(z.string().trim().min(1).max(2000)).min(2).max(8),
  correctIndex: z.number().int().min(0), explanation: z.string().max(6000),
}).refine(q => q.correctIndex < q.options.length, "Réponse correcte invalide.");
const content = z.object({
  title: z.string().trim().min(1).max(300), summary: z.string().max(6000),
  estimatedMinutes: z.number().int().min(1).max(600),
  contentSections: z.array(z.object({ title: z.string(), body: z.string() })).max(100),
  contentBlocks: z.array(z.record(z.unknown())).max(200).optional(),
  schemaVersion: z.number().int().optional(), miniQuiz: z.array(miniQuestion).max(50),
});

export function scopeId(data: DocumentData): string {
  return data.scope?.type === "establishment"
    ? data.scope.establishmentId : data.establishmentId || "global";
}

export function assertContentAuthor(actor: DocumentData, data: DocumentData): void {
  if (actor.accountStatus && actor.accountStatus !== "active") {
    throw new HttpsError("permission-denied", "Compte non actif.");
  }
  if (["superAdmin", "super_admin"].includes(actor.role)) return;
  if (!["teacher", "admin"].includes(actor.role) || !actor.establishmentId ||
      scopeId(data) !== actor.establishmentId) {
    throw new HttpsError("permission-denied", "Ce contenu ne relève pas de votre établissement.");
  }
}

export function publicationId(path: string): string {
  return `lesson_${createHash("sha256").update(path).digest("hex").slice(0, 32)}`;
}

export function lessonPreview(id: string, data: DocumentData): DocumentData {
  return Object.fromEntries(Object.entries({ id, title: data.title || "",
    summary: data.summary || "", estimatedMinutes: data.estimatedMinutes || 20,
    order: data.order || 0, scope: data.scope || { type: "global" },
    classLevel: data.classLevel, subjectId: data.subjectId, chapterId: data.chapterId,
  }).filter(([, value]) => value !== undefined));
}

function audienceCounts(previews: DocumentData[]): Record<string, number> {
  const counts: Record<string, number> = {};
  for (const preview of previews) { const scope = scopeId(preview); counts[scope] = (counts[scope] || 0) + 1; }
  return counts;
}

export function buildLessonCompanions(path: string, lesson: DocumentData, subject: DocumentData) {
  const questions = z.array(miniQuestion).parse(lesson.miniQuiz || []);
  const key = publicationId(path);
  const common = { status: "published", classLevels: [lesson.classLevel],
    scope: lesson.scope || { type: "global" }, sourceLessonId: path.split("/").at(-1),
    sourceLessonPath: path, managedBy: "lessonPublication" };
  const quiz = questions.length ? { ...common, title: lesson.title, subjectId: lesson.subjectId,
    subjectLabel: subject.title || "Cours", description: lesson.summary || "",
    difficultyLabel: "Entraînement", mode: "training", series: [], timerSeconds: null,
    questions: questions.map((q, index) => ({ id: q.id || `q${index + 1}`, type: "qcm",
      prompt: q.prompt, options: q.options, pointsReward: 10 })),
  } : null;
  const answers = questions.map((q, index) => ({ id: q.id || `q${index + 1}`,
    correctOptionIndex: q.correctIndex, explanation: q.explanation, pointsReward: 10 }));
  const flowBase = { ...common, subjectId: lesson.subjectId, chapterId: lesson.chapterId,
    ref: { lessonId: common.sourceLessonId }, title: lesson.title, hook: "",
    priority: 0, durationSeconds: 30, difficulty: 2, version: 1,
    origin: "lesson", pedagogicalIntent: "consolidate", tags: [],
  };
  const insight = String(lesson.summary || lesson.contentSections?.[0]?.body || "").slice(0, 600);
  const flow: Array<{ id: string; data: DocumentData }> = [];
  if (insight) flow.push({ id: `${key}_notion`, data: { ...flowBase, type: "notion",
    payload: { insight, points: [], subjectLabel: subject.title || "Cours" } } });
  questions.forEach((q, index) => flow.push({ id: `${key}_q${index + 1}`, data: {
    ...flowBase, type: "quiz", payload: { question: q.prompt, options: q.options,
      correctIndex: q.correctIndex, explanation: q.explanation, subjectLabel: subject.title || "Cours" },
  } }));
  return { key, quiz, answers, flow };
}

/** One commit makes the lesson and its index/companions visible together. */
export function createSaveLessonPublicationHandler(firestore: Firestore = db) {
  return async (request: CallableRequest) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Connexion requise.");
    const parsed = location.extend({ publish: z.boolean().default(false), content: content.optional() }).safeParse(request.data);
    if (!parsed.success) throw new HttpsError("invalid-argument", "Vérifiez le titre, les sections et les réponses du quiz.");
    const input = parsed.data;
    const subjectRef = firestore.doc(`classes/${input.classLevel}/subjects/${input.subjectId}`);
    const chapterRef = subjectRef.collection("chapters").doc(input.chapterId);
    const lessonRef = chapterRef.collection("lessons").doc(input.lessonId);
    return firestore.runTransaction(async transaction => {
      const [actorDoc, subjectDoc, chapterDoc, currentDoc, lessons, chapters, quizzes, cards] = await Promise.all([
        transaction.get(firestore.doc(`users/${request.auth!.uid}`)), transaction.get(subjectRef),
        transaction.get(chapterRef), transaction.get(lessonRef),
        transaction.get(chapterRef.collection("lessons")), transaction.get(subjectRef.collection("chapters")),
        transaction.get(firestore.collection("quizzes").where("sourceLessonId", "==", input.lessonId)),
        transaction.get(firestore.collection("flow_items").where("ref.lessonId", "==", input.lessonId)),
      ]);
      if (!actorDoc.exists || !currentDoc.exists || !subjectDoc.exists || !chapterDoc.exists) {
        throw new HttpsError("not-found", "Leçon, chapitre ou matière introuvable.");
      }
      const current = currentDoc.data()!;
      const actor = actorDoc.data()!;
      assertContentAuthor(actor, current);
      if (subjectDoc.data()?.deleting || chapterDoc.data()?.deleting || current.deleting) {
        throw new HttpsError("failed-precondition", "Ce contenu est en cours de suppression.");
      }
      const published = input.publish || current.status === "published";
      const lesson: DocumentData = { ...current, ...input.content,
        classLevel: input.classLevel, subjectId: input.subjectId, chapterId: input.chapterId,
        status: published ? "published" : "draft", updatedAt: FieldValue.serverTimestamp(),
        updatedBy: request.auth!.uid,
      };
      if (published && !(lesson.contentSections?.some((s: DocumentData) => s.body?.trim()) || lesson.contentBlocks?.length)) {
        throw new HttpsError("failed-precondition", "Ajoutez du contenu avant de publier cette leçon.");
      }
      if (published) lesson.editorialWorkflow = { ...(current.editorialWorkflow || {}), status: "published",
        publishedAt: current.editorialWorkflow?.publishedAt || new Date().toISOString(), publishedByUid: request.auth!.uid };
      const previews = lessons.docs
        .map(d => ({ id: d.id, data: d.id === input.lessonId ? lesson : d.data() }))
        .filter(d => d.data.status === "published").map(d => lessonPreview(d.id, d.data))
        .sort((a, b) => a.order - b.order);
      const summaries = chapters.docs.filter(d => !d.data().deleting).map(d => ({ id: d.id,
        title: d.data().title || "", description: d.data().description || "", order: d.data().order || 0,
        lessonsCount: d.id === input.chapterId ? previews.length : d.data().lessonsCount || 0,
        lessonCountsByScope: d.id === input.chapterId ? audienceCounts(previews) : d.data().lessonCountsByScope || { global: d.data().lessonsCount || 0 },
      })).sort((a, b) => a.order - b.order);
      const writes: Array<{ path: string; data: DocumentData }> = [];
      if (published) {
        const companions = buildLessonCompanions(lessonRef.path, lesson, subjectDoc.data()!);
        // Imported companions retain editorial content. Only derived companions
        // are regenerated; IDs stay stable across retries and later edits.
        const importedQuizzes = quizzes.docs.filter(d => d.data().managedBy !== "lessonPublication");
        const importedCards = cards.docs.filter(d => d.data().managedBy !== "lessonPublication");
        for (const quiz of importedQuizzes) {
          const key = await transaction.get(firestore.doc(`quiz_answer_keys/${quiz.id}`));
          try {
            const validated = buildScoringQuizRecord({ id: quiz.id, quizData: quiz.data(), answerKeyData: key.data() });
            if (!validated.questions.length) throw new Error("Empty quiz");
          } catch (_) { throw new HttpsError("failed-precondition", "Complétez le quiz associé et ses réponses avant de publier."); }
        }
        for (const card of importedCards) {
          const item = card.data();
          const p = item.payload || {};
          const valid = item.type === "quiz" ? typeof p.question === "string" && p.question.trim() && Array.isArray(p.options) && p.options.length >= 2 && Number.isInteger(p.correctIndex) && p.correctIndex >= 0 && p.correctIndex < p.options.length
            : item.type === "question" ? p.question?.trim() && p.answer?.trim()
            : ["notion", "infographic"].includes(item.type) ? p.insight?.trim() || p.points?.length
            : ["audio", "shortVideo", "image"].includes(item.type) ? !!item.ref?.storagePath
            : item.type === "interactiveNative" && p.componentKey && p.summary;
          if (!valid) throw new HttpsError("failed-precondition", "Complétez les cartes FLOW associées avant de publier.");
        }
        for (const linked of [...importedQuizzes, ...importedCards]) {
          assertContentAuthor(actor, linked.data());
          if (scopeId(linked.data()) !== scopeId(current)) throw new HttpsError("failed-precondition", "Les contenus associés ont des publics différents.");
          writes.push({ path: linked.ref.path, data: { status: "published", classLevels: [input.classLevel],
            scheduledAt: null,
            ...(linked.ref.parent.id === "flow_items" ? { priority: linked.data().priority || 0,
              payload: { ...linked.data().payload, subjectLabel: subjectDoc.data()!.title || "Cours" } } : {}),
            publishedAt: linked.data().publishedAt || new Date().toISOString(), updatedAt: new Date().toISOString() } });
        }
        if (!importedQuizzes.length && companions.quiz) {
          writes.push({ path: `quizzes/${companions.key}`, data: companions.quiz },
            { path: `quiz_answer_keys/${companions.key}`, data: { answers: companions.answers, scope: lesson.scope || { type: "global" } } });
        }
        if (!importedCards.length) for (const item of companions.flow) {
          const existing = cards.docs.find(d => d.id === item.id)?.data();
          writes.push({ path: `flow_items/${item.id}`, data: { ...item.data,
            createdBy: current.createdBy || request.auth!.uid,
            createdAt: existing?.createdAt || new Date().toISOString(),
            publishedAt: existing?.publishedAt || new Date().toISOString(), updatedAt: new Date().toISOString() } });
        }
        const keep = new Set(writes.map(w => w.path));
        for (const old of [...quizzes.docs, ...cards.docs]) {
          if (old.data().managedBy === "lessonPublication" && !keep.has(old.ref.path)) {
            transaction.delete(old.ref);
            if (old.ref.parent.id === "quizzes") transaction.delete(firestore.doc(`quiz_answer_keys/${old.id}`));
          }
        }
      }
      if (writes.length + cards.size + quizzes.size > 400) throw new HttpsError("resource-exhausted", "Trop de contenus associés pour une publication unique.");
      transaction.update(lessonRef, lesson);
      transaction.update(chapterRef, { lessonPreviews: previews, lessonsCount: previews.length, lessonCountsByScope: audienceCounts(previews) });
      transaction.update(subjectRef, { chapterSummaries: summaries,
        ...(published ? { status: "published" } : {}), updatedAt: FieldValue.serverTimestamp() });
      for (const write of writes) transaction.set(firestore.doc(write.path), write.data, { merge: true });
      return { published, lessonId: input.lessonId, companionsUpdated: writes.length };
    });
  };
}

/** Recursive deletion is server-only; attempts/earned points are history. */
export function createDeleteCatalogContentHandler(firestore: Firestore = db) {
  return async (request: CallableRequest) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Connexion requise.");
    const parsed = location.partial({ chapterId: true, lessonId: true }).safeParse(request.data);
    if (!parsed.success || (parsed.data.lessonId && !parsed.data.chapterId)) throw new HttpsError("invalid-argument", "Référence invalide.");
    const actor = (await firestore.doc(`users/${request.auth.uid}`).get()).data() || {};
    if (!["superAdmin", "super_admin"].includes(actor.role) || (actor.accountStatus && actor.accountStatus !== "active")) {
      throw new HttpsError("permission-denied", "Suppression réservée à l’administration générale.");
    }
    const input = parsed.data;
    const subject = firestore.doc(`classes/${input.classLevel}/subjects/${input.subjectId}`);
    const chapter = input.chapterId ? subject.collection("chapters").doc(input.chapterId) : null;
    const target = input.lessonId ? chapter!.collection("lessons").doc(input.lessonId) : chapter || subject;
    // Mark before walking descendants so the publication callable cannot race
    // with a deletion. A retry resumes cleanup of this same subtree.
    await target.set({ deleting: true, status: "archived" }, { merge: true });
    const chapterDocs = chapter ? [await chapter.get()] : (await subject.collection("chapters").get()).docs;
    for (const chapterDoc of chapterDocs) {
      const lessons = input.lessonId ? [await target.get()] : (await chapterDoc.ref.collection("lessons").get()).docs;
      for (const lesson of lessons) {
        const [quizzes, cards] = await Promise.all([
          firestore.collection("quizzes").where("sourceLessonId", "==", lesson.id).get(),
          firestore.collection("flow_items").where("ref.lessonId", "==", lesson.id).get(),
        ]);
        for (const quiz of quizzes.docs) { await firestore.recursiveDelete(quiz.ref); await firestore.doc(`quiz_answer_keys/${quiz.id}`).delete(); }
        for (const card of cards.docs) await firestore.recursiveDelete(card.ref);
      }
    }
    await firestore.recursiveDelete(target);
    await firestore.runTransaction(async transaction => {
      const [subjectDoc, chapterDoc] = await Promise.all([transaction.get(subject), chapter ? transaction.get(chapter) : Promise.resolve(null)]);
      const lessons = chapterDoc?.exists ? await transaction.get(chapter!.collection("lessons")) : null;
      const chapters = subjectDoc.exists ? await transaction.get(subject.collection("chapters")) : null;
      const previews = lessons?.docs.filter(d => d.data().status === "published").map(d => lessonPreview(d.id, d.data())) || [];
      if (chapterDoc?.exists) transaction.update(chapter!, { lessonPreviews: previews, lessonsCount: previews.length, lessonCountsByScope: audienceCounts(previews) });
      if (chapters) transaction.update(subject, { chapterSummaries: chapters.docs.filter(d => !d.data().deleting).map(d => ({ id: d.id,
        title: d.data().title || "", description: d.data().description || "", order: d.data().order || 0,
        lessonsCount: d.id === input.chapterId ? previews.length : d.data().lessonsCount || 0,
        lessonCountsByScope: d.id === input.chapterId ? audienceCounts(previews) : d.data().lessonCountsByScope || { global: d.data().lessonsCount || 0 },
      })).sort((a, b) => a.order - b.order) });
    });
    return { deleted: true };
  };
}

export const saveLessonPublicationHandler = createSaveLessonPublicationHandler();
export const deleteCatalogContentHandler = createDeleteCatalogContentHandler();

export function createCatalogChapterHandler(firestore: Firestore = db) {
  return async (request: CallableRequest) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Connexion requise.");
    const parsed = z.object({ classLevel: id, subjectId: id, title: z.string().trim().min(1).max(300), description: z.string().max(6000) }).safeParse(request.data);
    if (!parsed.success) throw new HttpsError("invalid-argument", "Saisissez un titre de chapitre.");
    const input = parsed.data;
    const subject = firestore.doc(`classes/${input.classLevel}/subjects/${input.subjectId}`);
    const chapter = subject.collection("chapters").doc();
    return firestore.runTransaction(async transaction => {
      const [author, parent, chapters] = await Promise.all([
        transaction.get(firestore.doc(`users/${request.auth!.uid}`)), transaction.get(subject),
        transaction.get(subject.collection("chapters")),
      ]);
      const actor = author.data() || {};
      const scope = ["superAdmin", "super_admin"].includes(actor.role) ? { type: "global" }
        : { type: "establishment", establishmentId: actor.establishmentId || "" };
      assertContentAuthor(actor, { scope });
      if (!parent.exists || parent.data()?.deleting) throw new HttpsError("not-found", "Matière indisponible.");
      if (scopeId(parent.data()!) !== "global") assertContentAuthor(actor, parent.data()!);
      const normalize = (value: string) => value.trim().toLocaleLowerCase("fr").replace(/\s+/g, " ");
      if (chapters.docs.some(d => normalize(d.data().title || "") === normalize(input.title))) {
        throw new HttpsError("already-exists", "Ce chapitre existe déjà. Ouvrez-le pour ajouter votre leçon.");
      }
      const order = Math.max(-1, ...chapters.docs.map(d => Number(d.data().order) || 0)) + 1;
      transaction.create(chapter, { ...input, scope, order, createdBy: request.auth!.uid,
        lessonsCount: 0, lessonPreviews: [], lessonCountsByScope: {}, createdAt: FieldValue.serverTimestamp() });
      const summaries = chapters.docs.map(d => ({ id: d.id, title: d.data().title || "", description: d.data().description || "",
        order: d.data().order || 0, lessonsCount: d.data().lessonsCount || 0,
        lessonCountsByScope: d.data().lessonCountsByScope || { global: d.data().lessonsCount || 0 } }));
      summaries.push({ id: chapter.id, title: input.title, description: input.description, order, lessonsCount: 0, lessonCountsByScope: {} });
      transaction.update(subject, { chapterSummaries: summaries.sort((a,b) => a.order-b.order), updatedAt: FieldValue.serverTimestamp() });
      return { chapterId: chapter.id };
    });
  };
}

export function createListEditorialFlowHandler(firestore: Firestore = db) {
  return async (request: CallableRequest) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Connexion requise.");
    const parsed = id.safeParse(request.data?.classLevel);
    if (!parsed.success) throw new HttpsError("invalid-argument", "Classe invalide.");
    const actor = (await firestore.doc(`users/${request.auth.uid}`).get()).data() || {};
    const unrestricted = ["superAdmin", "super_admin"].includes(actor.role);
    assertContentAuthor(actor, { scope: unrestricted ? { type: "global" } : { type: "establishment", establishmentId: actor.establishmentId || "" } });
    const snapshot = await firestore.collection("flow_items").where("classLevels", "array-contains", parsed.data).get();
    return { items: snapshot.docs.filter(d => unrestricted || scopeId(d.data()) === actor.establishmentId)
      .map(d => {
        const data = d.data();
        for (const field of ["createdAt", "updatedAt", "publishedAt", "scheduledAt"]) {
          if (typeof data[field]?.toDate === "function") data[field] = data[field].toDate().toISOString();
        }
        return { ...data, id: d.id };
      }).sort((a: DocumentData,b: DocumentData) => String(b.updatedAt || "").localeCompare(String(a.updatedAt || ""))) };
  };
}
