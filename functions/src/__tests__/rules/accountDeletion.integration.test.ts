import { Timestamp } from "firebase-admin/firestore";
import { beforeEach, describe, expect, it } from "vitest";

import { db } from "../../config/firebase";
import {
  ACCOUNT_DELETION_GRACE_MS,
  AccountDeletionProcessor,
  createCancelAccountDeletionHandler,
  createRequestAccountDeletionHandler,
  type DeletionAuthPort,
  type DeletionStoragePort,
} from "../../services/accountDeletionCallable";

/**
 * Suppression de compte contre le VRAI émulateur Firestore. Auth et Storage
 * sont des ports enregistreurs : on vérifie l'ordre et l'idempotence.
 */

if (!process.env.FIRESTORE_EMULATOR_HOST) {
  throw new Error("This test requires the Firestore emulator (--only firestore).");
}

const COLLECTIONS = [
  "users", "student_profiles", "parent_profiles", "children_links", "notifications",
  "notification_devices", "quiz_attempts", "progress", "flow_completions", "flow_events",
  "flow_daily_points", "student_link_codes", "ai_tutor_daily_usage", "tutor_requests",
  "streaks", "settings", "study_reserve", "classes", "mobile_money_payment_requests",
  "entitlements", "account_management_audit", "account_deletion_requests",
  "student_access_credentials", "student_access_codes", "lessons",
];

class RecordingAuth implements DeletionAuthPort {
  readonly calls: string[] = [];
  failDeleteTimes = 0;
  async disable(uid: string) {
    this.calls.push(`disable:${uid}`);
  }
  async deleteUser(uid: string) {
    if (this.failDeleteTimes-- > 0) throw Object.assign(new Error("boom"), { code: "auth/internal-error" });
    this.calls.push(`delete:${uid}`);
  }
}

class RecordingStorage implements DeletionStoragePort {
  readonly prefixes: string[] = [];
  async deletePrefix(prefix: string) {
    this.prefixes.push(prefix);
    return 1;
  }
}

async function clear() {
  for (const name of COLLECTIONS) {
    const snapshot = await db.collection(name).get();
    for (const document of snapshot.docs) await db.recursiveDelete(document.ref);
  }
}

async function seedStudent(uid: string) {
  await db.doc(`users/${uid}`).set({ role: "student", firstName: "Amina", email: "amina@example.com", phoneNumber: "+237600000000", establishmentId: "school-a" });
  await db.doc(`student_profiles/${uid}`).set({ firstName: "Amina", classLevel: "Terminale" });
  await db.doc(`student_profiles/${uid}/lessonProgress/l1`).set({ isFavorite: true });
  await db.doc(`children_links/parent-p_${uid}`).set({ parentId: "parent-p", studentId: uid, status: "approved" });
  await db.doc(`users/parent-p`).set({ role: "parent", firstName: "Parent" });
  await db.doc(`notifications/n1`).set({ userId: uid, title: "x" });
  await db.doc(`notification_devices/d1`).set({ userId: uid, token: "t" });
  await db.doc(`quiz_attempts/a1`).set({ studentId: uid, score: 3 });
  await db.doc(`progress/${uid}_q1`).set({ studentId: uid, score: 3 });
  await db.doc(`flow_completions/c1`).set({ studentId: uid });
  await db.doc(`flow_events/e1`).set({ studentId: uid });
  await db.doc(`flow_daily_points/${uid}_2026-09-21`).set({ studentId: uid });
  await db.doc(`student_link_codes/ABCDEFGH`).set({ studentId: uid });
  await db.doc(`ai_tutor_daily_usage/${uid}_2026-09-21`).set({ userId: uid });
  await db.doc(`tutor_requests/${uid}__req-00000001`).set({ userId: uid, state: "completed" });
  await db.doc(`streaks/${uid}`).set({ current: 3 });
  await db.doc(`settings/${uid}`).set({ theme: "light" });
  await db.doc(`study_reserve/${uid}`).set({ consumed: 10 });
  await db.doc(`study_reserve/${uid}/ledger/x`).set({ billableUnits: 10 });
  await db.doc(`student_access_credentials/${uid}`).set({ lookupKey: "hmac-key", status: "active" });
  await db.doc(`student_access_codes/hmac-key`).set({ studentId: uid });
  await db.doc(`classes/class-a`).set({ establishmentId: "school-a", studentIds: [uid, "other-student"], teacherIds: ["teacher-t"] });
  // Conservés : pièces comptables, audit, contenus institutionnels, autres élèves.
  await db.doc(`mobile_money_payment_requests/p1`).set({ parentId: "parent-p", beneficiaryStudentId: uid, amountXaf: 7500 });
  await db.doc(`entitlements/parent-p_school-a`).set({ userId: "parent-p", status: "active" });
  await db.doc(`account_management_audit/e1`).set({ targetUid: uid, action: "suspend" });
  await db.doc(`quiz_attempts/other`).set({ studentId: "other-student", score: 5 });
}

function processor(auth = new RecordingAuth(), storage = new RecordingStorage(), now = () => Date.now() + ACCOUNT_DELETION_GRACE_MS + 1000) {
  return { processor: new AccountDeletionProcessor(db, auth, storage, now), auth, storage };
}

describe("account deletion end to end", () => {
  beforeEach(clear);

  it("schedules, lets the owner cancel, and never erases at request time", async () => {
    await seedStudent("stu-cancel");
    const request = createRequestAccountDeletionHandler(db);
    const result = await request({ auth: { uid: "stu-cancel" }, data: {} } as never);
    expect(result.status).toBe("scheduled");
    // Même demande rejouée : même échéance.
    expect((await request({ auth: { uid: "stu-cancel" }, data: {} } as never)).dueAt).toBe(result.dueAt);
    expect((await db.doc("student_profiles/stu-cancel").get()).exists).toBe(true);
    // Les parents liés sont informés.
    const notice = await db.doc("notifications/account_deletion_stu-cancel_parent-p").get();
    expect(notice.get("type")).toBe("account_deletion_scheduled");

    await createCancelAccountDeletionHandler(db)({ auth: { uid: "stu-cancel" }, data: {} } as never);
    const { processor: run } = processor();
    expect(await run.processDue()).toEqual({ completed: 0, failed: 0 });
    expect((await db.doc("users/stu-cancel").get()).get("firstName")).toBe("Amina");
  });

  it("does not process a request before its grace period ends", async () => {
    await seedStudent("stu-early");
    await createRequestAccountDeletionHandler(db)({ auth: { uid: "stu-early" }, data: {} } as never);
    const { processor: run, auth } = processor(new RecordingAuth(), new RecordingStorage(), () => Date.now());
    expect(await run.processDue()).toEqual({ completed: 0, failed: 0 });
    expect(auth.calls).toEqual([]);
  });

  it("never processes a request left by the previous app version", async () => {
    // Ancien format : statut « pending », sans échéance ni délai de grâce
    // annoncé. Décision du propriétaire : jamais traité automatiquement ;
    // visible dans Studio, et l'élève peut refaire une demande explicite.
    await seedStudent("stu-legacy");
    await db.doc("account_deletion_requests/stu-legacy").set({
      uid: "stu-legacy",
      status: "pending",
      requestedAt: Timestamp.fromMillis(Date.now() - 30 * 24 * 60 * 60 * 1000),
    });
    const { processor: run, auth } = processor();
    expect(await run.processDue()).toEqual({ completed: 0, failed: 0 });
    expect(auth.calls).toEqual([]);
    expect((await db.doc("users/stu-legacy").get()).get("firstName")).toBe("Amina");
    expect((await db.doc("account_deletion_requests/stu-legacy").get()).get("status")).toBe("pending");

    // Une nouvelle demande explicite repart avec 7 jours de grâce.
    const again = await createRequestAccountDeletionHandler(db)({ auth: { uid: "stu-legacy" }, data: {} } as never);
    expect(again.status).toBe("scheduled");
    expect(Date.parse(again.dueAt)).toBeGreaterThan(Date.now() + ACCOUNT_DELETION_GRACE_MS - 60_000);
  });

  it("OWNER DECISION: a legacy pending request stays untouched even with a past dueAt", async () => {
    // Même si une ancienne demande portait une échéance, son statut
    // « pending » suffit à l'exclure : aucune migration vers « scheduled ».
    await seedStudent("stu-legacy-dated");
    await db.doc("account_deletion_requests/stu-legacy-dated").set({
      uid: "stu-legacy-dated",
      status: "pending",
      requestedAt: Timestamp.fromMillis(Date.now() - 40 * 24 * 60 * 60 * 1000),
      dueAt: Timestamp.fromMillis(Date.now() - 30 * 24 * 60 * 60 * 1000),
    });
    const { processor: run, auth } = processor();
    expect(await run.processDue()).toEqual({ completed: 0, failed: 0 });
    expect(await run.processOne("stu-legacy-dated")).toBe("skipped");
    expect(auth.calls).toEqual([]);
    const request = (await db.doc("account_deletion_requests/stu-legacy-dated").get()).data()!;
    expect(request.status).toBe("pending");
    expect(request.attempts).toBeUndefined();
    expect((await db.doc("users/stu-legacy-dated").get()).get("firstName")).toBe("Amina");
  });

  it("erases a student's personal data, keeps what must be kept, deletes Auth last", async () => {
    await seedStudent("stu-1");
    await createRequestAccountDeletionHandler(db)({ auth: { uid: "stu-1" }, data: {} } as never);
    const { processor: run, auth, storage } = processor();

    expect(await run.processDue()).toEqual({ completed: 1, failed: 0 });

    const user = (await db.doc("users/stu-1").get()).data();
    expect(user).toMatchObject({ uid: "stu-1", accountStatus: "deleted", role: "student" });
    expect(user).not.toHaveProperty("firstName");
    expect(user).not.toHaveProperty("email");
    expect(user).not.toHaveProperty("phoneNumber");
    for (const path of [
      "student_profiles/stu-1", "student_profiles/stu-1/lessonProgress/l1", "children_links/parent-p_stu-1",
      "notifications/n1", "notification_devices/d1", "quiz_attempts/a1", "progress/stu-1_q1",
      "flow_completions/c1", "flow_events/e1", "flow_daily_points/stu-1_2026-09-21", "student_link_codes/ABCDEFGH",
      "ai_tutor_daily_usage/stu-1_2026-09-21", "tutor_requests/stu-1__req-00000001", "streaks/stu-1",
      "settings/stu-1", "study_reserve/stu-1", "study_reserve/stu-1/ledger/x",
      "student_access_credentials/stu-1", "student_access_codes/hmac-key",
    ]) {
      expect((await db.doc(path).get()).exists, path).toBe(false);
    }
    expect((await db.doc("classes/class-a").get()).get("studentIds")).toEqual(["other-student"]);
    // Conservés.
    expect((await db.doc("mobile_money_payment_requests/p1").get()).exists).toBe(true);
    expect((await db.doc("entitlements/parent-p_school-a").get()).exists).toBe(true);
    expect((await db.doc("account_management_audit/e1").get()).exists).toBe(true);
    expect((await db.doc("quiz_attempts/other").get()).exists).toBe(true);
    expect((await db.doc("users/parent-p").get()).exists).toBe(true);
    // Ordre : désactivation d'abord, suppression Auth en dernier.
    expect(auth.calls).toEqual(["disable:stu-1", "delete:stu-1"]);
    expect(storage.prefixes).toEqual(["avatars/stu-1/"]);
    // Trace minimale, sans donnée personnelle.
    const trace = (await db.doc("account_deletion_requests/stu-1").get()).data()!;
    expect(trace.status).toBe("completed");
    expect(JSON.stringify(trace)).not.toMatch(/Amina|amina@|\+237/);
  });

  it("records a failure, retries later, and completes idempotently", async () => {
    await seedStudent("stu-retry");
    await createRequestAccountDeletionHandler(db)({ auth: { uid: "stu-retry" }, data: {} } as never);
    const auth = new RecordingAuth();
    auth.failDeleteTimes = 1;
    let clock = Date.now() + ACCOUNT_DELETION_GRACE_MS + 1000;
    const run = new AccountDeletionProcessor(db, auth, new RecordingStorage(), () => clock);

    expect(await run.processDue()).toEqual({ completed: 0, failed: 1 });
    const failed = (await db.doc("account_deletion_requests/stu-retry").get()).data()!;
    expect(failed.status).toBe("failed");
    expect(failed.lastErrorCode).toBe("auth/internal-error");
    expect(failed.attempts).toBe(1);
    // Pas de reprise avant l'échéance du recul.
    expect(await run.processDue()).toEqual({ completed: 0, failed: 0 });

    clock += 60 * 60 * 1000 + 1000;
    expect(await run.processDue()).toEqual({ completed: 1, failed: 0 });
    expect((await db.doc("account_deletion_requests/stu-retry").get()).get("attempts")).toBe(2);
    expect((await db.doc("student_profiles/stu-retry").get()).exists).toBe(false);
  });

  it("refuses to delete a general administration account through this path", async () => {
    await db.doc("users/root").set({ role: "superAdmin" });
    await expect(createRequestAccountDeletionHandler(db)({ auth: { uid: "root" }, data: {} } as never))
      .rejects.toMatchObject({ code: "failed-precondition" });
  });

  it("removes a parent's links without touching the child or the payments", async () => {
    await seedStudent("stu-kept");
    await db.doc("account_deletion_requests/parent-p").set({
      uid: "parent-p",
      role: "parent",
      status: "scheduled",
      dueAt: Timestamp.fromMillis(Date.now() - 1000),
      attempts: 0,
    });
    const { processor: run } = processor();
    expect(await run.processOne("parent-p")).toBe("completed");
    expect((await db.doc("children_links/parent-p_stu-kept").get()).exists).toBe(false);
    expect((await db.doc("student_profiles/stu-kept").get()).exists).toBe(true);
    expect((await db.doc("mobile_money_payment_requests/p1").get()).exists).toBe(true);
  });
});
