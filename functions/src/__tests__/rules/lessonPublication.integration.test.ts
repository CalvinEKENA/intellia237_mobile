import { initializeApp, deleteApp } from "firebase-admin/app";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import type { CallableRequest } from "firebase-functions/v2/https";
import { afterAll, beforeEach, describe, expect, it } from "vitest";
import { createSaveLessonPublicationHandler, createDeleteCatalogContentHandler, createCatalogChapterHandler, createListEditorialFlowHandler, publicationId } from "../../services/lessonPublicationCallable";
import { createListRegistrationEstablishmentsHandler } from "../../services/registrationEstablishmentsCallable";
import { FirestoreFlowPointsStore } from "../../services/flowPointsCallable";
import { FirestoreQuizContentStore } from "../../services/quizContentStore";

if (!process.env.FIRESTORE_EMULATOR_HOST) throw new Error("Emulator required.");
const app = initializeApp({ projectId: "demo-intellia237" }, "lesson-publication-tests");
const firestore = getFirestore(app);
const publish = createSaveLessonPublicationHandler(firestore);
const remove = createDeleteCatalogContentHandler(firestore);
const loc = { classLevel: "6eme", subjectId: "svt-real-id", chapterId: "climat", lessonId: "vegetaux" };
const subject = firestore.doc("classes/6eme/subjects/svt-real-id");
const chapter = subject.collection("chapters").doc(loc.chapterId);
const lesson = chapter.collection("lessons").doc(loc.lessonId);
const derived = publicationId(lesson.path);
const call = (data: unknown, uid = "root") => ({ data, auth: { uid } }) as CallableRequest;
const draft = { title: "Influence du climat", summary: "Le climat influence la croissance.", estimatedMinutes: 20,
  status: "draft", order: 0, scope: { type: "global" }, classLevel: "6eme", subjectId: loc.subjectId, chapterId: loc.chapterId,
  contentSections: [{ title: "Lumière", body: "La lumière permet la photosynthèse." }],
  miniQuiz: [{ id: "q1", prompt: "La lumière permet…", options: ["la photosynthèse", "la pluie"], correctIndex: 0, explanation: "Elle fournit l’énergie." }],
};

beforeEach(async () => {
  for (const collection of ["users", "student_profiles", "classes", "quizzes", "quiz_answer_keys", "flow_items", "flow_events", "flow_completions", "flow_daily_points", "establishments"]) {
    await firestore.recursiveDelete(firestore.collection(collection));
  }
  await firestore.doc("users/root").set({ role: "superAdmin", accountStatus: "active" });
  await firestore.doc("users/teacher").set({ role: "teacher", establishmentId: "school-a", accountStatus: "active" });
  await firestore.doc("users/student").set({ role: "student", classLevel: "6eme", establishmentId: "school-a" });
  await firestore.doc("student_profiles/student").set({ classLevel: "6eme", points: 0 });
  await subject.set({ title: "SVT", status: "draft", chapterSummaries: [] });
  await chapter.set({ title: "Climat", order: 0, lessonPreviews: [], lessonsCount: 0 });
  await lesson.set(draft);
});
afterAll(() => deleteApp(app));

describe("publication to learner", () => {
  it("lets a teacher create a school chapter in a shared subject, rejects duplicates and foreign scopes", async () => {
    const create = createCatalogChapterHandler(firestore);
    const input = { classLevel: "6eme", subjectId: loc.subjectId, title: "La plante", description: "Croissance" };
    const result = await create(call(input, "teacher"));
    expect((await subject.collection("chapters").doc(result.chapterId).get()).data()?.scope).toEqual({ type: "establishment", establishmentId: "school-a" });
    expect((await subject.get()).data()?.chapterSummaries).toEqual(expect.arrayContaining([expect.objectContaining({ id: result.chapterId, lessonsCount: 0 })]));
    await expect(create(call({ ...input, title: "  LA   PLANTE " }, "teacher"))).rejects.toMatchObject({ code: "already-exists" });
    await expect(create(call({ ...input, title: "Autre" }, "student"))).rejects.toMatchObject({ code: "permission-denied" });
    await subject.update({ scope: { type: "establishment", establishmentId: "school-b" } });
    await expect(create(call({ ...input, title: "Autre" }, "teacher"))).rejects.toMatchObject({ code: "permission-denied" });
  });

  it("exposes editorial FLOW only to its school or the super admin and serializes dates", async () => {
    for (const [key, scope] of Object.entries({ own: { type: "establishment", establishmentId: "school-a" }, foreign: { type: "establishment", establishmentId: "school-b" }, global: { type: "global" } })) {
      await firestore.doc(`flow_items/${key}`).set({ classLevels: ["6eme"], status: "draft", scope, updatedAt: Timestamp.fromDate(new Date("2026-09-13T10:00:00Z")) });
    }
    const list = createListEditorialFlowHandler(firestore);
    const own = await list(call({ classLevel: "6eme" }, "teacher"));
    expect(own.items).toEqual([expect.objectContaining({ id: "own", updatedAt: "2026-09-13T10:00:00.000Z" })]);
    expect((await list(call({ classLevel: "6eme" }))).items).toHaveLength(3);
    await expect(list(call({ classLevel: "6eme" }, "student"))).rejects.toMatchObject({ code: "permission-denied" });
  });

  it("keeps a save private, then publishes lesson, parent index, quiz and FLOW together", async () => {
    await publish(call({ ...loc, publish: false }));
    expect((await chapter.get()).data()?.lessonPreviews).toEqual([]);
    expect((await firestore.collection("flow_items").get()).empty).toBe(true);
    await publish(call({ ...loc, publish: true }));
    expect((await lesson.get()).data()?.editorialWorkflow.status).toBe("published");
    expect((await subject.get()).data()?.status).toBe("published");
    expect((await chapter.get()).data()?.lessonsCount).toBe(1);
    const quiz = (await firestore.doc(`quizzes/${derived}`).get()).data()!;
    expect(quiz.questions[0].correctOptionIndex).toBeUndefined();
    expect((await firestore.doc(`quiz_answer_keys/${derived}`).get()).data()?.answers[0].correctOptionIndex).toBe(0);
    const store = new FirestoreQuizContentStore(firestore);
    expect((await store.listPublished({ classLevel: "6eme" })).map(q => q.id)).toContain(derived);
    expect((await store.checkTrainingAnswer({ quizId: derived, questionId: "q1", answer: "0" })).isCorrect).toBe(true);
    const result = await new FirestoreFlowPointsStore(firestore).submit({ studentId: "student", clientEventId: "event-00001", cardId: `${derived}_q1`, kind: "choice", answer: 0 });
    expect(result.pointsAwarded).toBe(25);
    const again = await new FirestoreFlowPointsStore(firestore).submit({ studentId: "student", clientEventId: "event-00001", cardId: `${derived}_q1`, kind: "choice", answer: 0 });
    expect(again.idempotentReplay).toBe(true);
  });

  it("does not duplicate companions and removes obsolete generated questions", async () => {
    await publish(call({ ...loc, publish: true }));
    await publish(call({ ...loc, publish: true }));
    expect((await firestore.collection("flow_items").get()).size).toBe(2);
    expect((await firestore.collection("quizzes").get()).size).toBe(1);
    await publish(call({ ...loc, content: { ...draft, miniQuiz: [] }, publish: false }));
    expect((await firestore.collection("flow_items").get()).size).toBe(1);
    expect((await firestore.collection("quiz_answer_keys").get()).empty).toBe(true);
  });

  it("rejects invalid content atomically and never reports a partial publication", async () => {
    await expect(publish(call({ ...loc, publish: true, content: { ...draft, contentSections: [] } }))).rejects.toMatchObject({ code: "failed-precondition" });
    expect((await lesson.get()).data()?.status).toBe("draft");
    expect((await subject.get()).data()?.status).toBe("draft");
    await expect(publish(call({ ...loc, publish: true, content: { ...draft, miniQuiz: [{ ...draft.miniQuiz[0], correctIndex: 9 }] } }))).rejects.toMatchObject({ code: "invalid-argument" });
  });

  it("allows teachers only in their school and preserves the stored audience", async () => {
    await expect(publish(call({ ...loc, publish: true }, "teacher"))).rejects.toMatchObject({ code: "permission-denied" });
    await lesson.update({ scope: { type: "establishment", establishmentId: "school-a" } });
    await publish(call({ ...loc, publish: true, content: draft }, "teacher"));
    expect((await lesson.get()).data()?.scope.establishmentId).toBe("school-a");
    await firestore.doc("users/student").update({ establishmentId: "school-b" });
    await expect(new FirestoreFlowPointsStore(firestore).submit({ studentId: "student", clientEventId: "event-00002", cardId: `${derived}_q1`, kind: "choice", answer: 0 })).rejects.toMatchObject({ code: "not-found" });
  });

  it("publishes imported companions without generating duplicates", async () => {
    await firestore.doc("quizzes/imported").set({ sourceLessonId: loc.lessonId, status: "draft", title: draft.title, subjectId: loc.subjectId, subjectLabel: "SVT", classLevels: ["6eme"], mode: "training",
      questions: [{ id: "q1", type: "qcm", prompt: draft.miniQuiz[0].prompt, options: draft.miniQuiz[0].options, correctOptionIndex: 0 }] });
    await firestore.doc("quiz_answer_keys/imported").set({ answers: [{ id: "q1", correctOptionIndex: 0, correctBooleanValue: null, acceptedAnswers: [] }] });
    await firestore.doc("flow_items/imported").set({ ref: { lessonId: loc.lessonId }, type: "notion", payload: { insight: "Climat" }, subjectId: "svt", classLevels: ["6eme"], priority: 0, status: "draft" });
    await publish(call({ ...loc, publish: true }));
    expect((await firestore.doc("flow_items/imported").get()).data()?.status).toBe("published");
    expect((await firestore.collection("flow_items").get()).size).toBe(1);
    expect((await firestore.collection("quizzes").get()).size).toBe(1);
  });

  it("removes the subtree and all companions, then allows an idempotent retry", async () => {
    await publish(call({ ...loc, publish: true }));
    await expect(remove(call(loc, "teacher"))).rejects.toMatchObject({ code: "permission-denied" });
    await remove(call({ classLevel: loc.classLevel, subjectId: loc.subjectId, chapterId: loc.chapterId }));
    expect((await lesson.get()).exists).toBe(false);
    expect((await firestore.collection("quizzes").get()).empty).toBe(true);
    expect((await firestore.collection("quiz_answer_keys").get()).empty).toBe(true);
    expect((await firestore.collection("flow_items").get()).empty).toBe(true);
    expect((await subject.get()).data()?.chapterSummaries).toEqual([]);
    await remove(call({ classLevel: loc.classLevel, subjectId: loc.subjectId, chapterId: loc.chapterId }));
    expect((await chapter.get()).exists).toBe(false);
  });

  it("lists only active schools created by the super admin, with no private fields", async () => {
    await firestore.doc("establishments/official").set({ name: "Collège F.X VOGT", city: "Yaoundé", status: "active", createdBy: "root", contactEmail: "private@example.com" });
    await firestore.doc("establishments/untrusted").set({ name: "Not approved", status: "active", createdBy: "teacher" });
    await firestore.doc("establishments/inactive").set({ name: "Inactive", status: "inactive", createdBy: "root" });
    const result = await createListRegistrationEstablishmentsHandler(firestore)(call({}));
    expect(result.establishments).toEqual([{ id: "official", name: "Collège F.X VOGT", city: "Yaoundé", region: "" }]);
  });
});
