import { deleteApp, initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore } from "firebase-admin/firestore";
import { afterAll, beforeEach, describe, expect, it } from "vitest";

import { db as defaultDb } from "../../config/firebase";
import { fanoutAnnouncementHandler } from "../../services/announcementNotificationFanout";
import { FirestoreMobileMoneyStore } from "../../services/mobileMoneyCallables";
import {
  createListParentChildrenHandler,
  FirestoreParentChildrenStore,
  type ParentChildSummary,
} from "../../services/parentChildrenCallable";
import {
  createIssueStudentAccessCodeHandler,
  createSignInWithStudentAccessCodeHandler,
  FirestoreStudentAccessStore,
} from "../../services/studentAccessCode";
import {
  FirestoreStudyReserveConsumptionStore,
  FirestoreThresholdNotifier,
  StudyReserveConsumption,
} from "../../services/studyReserveConsumption";
import { FirestoreStudyReserveProvisioningStore } from "../../services/studyReserveProvisioning";
import { resolveEmulatorAddress } from "./emulator-address";

/**
 * Une famille réelle, avec les stores de PRODUCTION sur les émulateurs :
 * un parent, trois enfants aux accès différents, deux écoles aux offres
 * différentes, un second parent. Identité, relation, école, accès et payeur
 * restent cinq dimensions indépendantes.
 */

if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
  throw new Error("This test requires the Firestore and Auth emulators (--only firestore,auth).");
}

const projectId = "demo-intellia237";
const app = initializeApp({ projectId }, "family-billing-tests");
const firestore = getFirestore(app);
const auth = getAuth(app);
const pepper = "integration-pepper";
const DAY = 24 * 60 * 60 * 1000;

const mobileMoney = new FirestoreMobileMoneyStore(firestore);
const accessStore = new FirestoreStudentAccessStore(firestore);
const listChildren = createListParentChildrenHandler(new FirestoreParentChildrenStore(firestore, () => auth));
const provisioning = new FirestoreStudyReserveProvisioningStore(() => Date.now(), firestore);
const consumption = new StudyReserveConsumption(
  new FirestoreStudyReserveConsumptionStore(() => Date.now(), firestore),
  new FirestoreThresholdNotifier(firestore),
  provisioning,
);

const PARENT_PHONE = "+237699000001";

async function clearEmulators() {
  const address = resolveEmulatorAddress("auth", "FIREBASE_AUTH_EMULATOR_HOST");
  await fetch(`http://${address.host}:${address.port}/emulator/v1/projects/${projectId}/accounts`, {
    method: "DELETE",
  });
  const collections = await firestore.listCollections();
  await Promise.all(collections.map((collection) => firestore.recursiveDelete(collection)));
}

async function seedFamily() {
  const set = (path: string, data: Record<string, unknown>) => firestore.doc(path).set(data);
  await set("establishments/school-a", { name: "Lycée A" });
  await set("establishments/school-b", { name: "Collège B" });
  const offer = (establishmentId: string, title: string, amountXaf: number, durationDays: number) => ({
    status: "active",
    establishmentId,
    title,
    description: `Accès INTELLIA237 — ${title}.`,
    amountXaf,
    currency: "XAF",
    durationDays,
    operators: [{ code: "mtn", label: "MTN Mobile Money", recipientPhone: "+237670000000" }],
  });
  await set("mobile_money_offers/school-a", offer("school-a", "Offre Lycée A", 2500, 30));
  await set("mobile_money_offers/school-b", offer("school-b", "Offre Collège B", 4000, 90));
  await set("study_reserve_plans/school-a", { allowanceInternal: 600_000, cycleDays: 30 });
  await set("study_reserve_plans/school-b", { allowanceInternal: 900_000, cycleDays: 30 });

  await set("users/root", { role: "superAdmin", accountStatus: "active" });
  await set("users/head-a", { role: "admin", establishmentId: "school-a", accountStatus: "active" });
  await set("users/head-b", { role: "admin", establishmentId: "school-b", accountStatus: "active" });

  // Parents : aucun rattachement à une école.
  await auth.createUser({ uid: "parent-p", phoneNumber: PARENT_PHONE });
  await set("users/parent-p", { role: "parent", firstName: "Paul", phoneNumber: PARENT_PHONE, accountStatus: "active" });
  await auth.createUser({ uid: "parent-q", phoneNumber: "+237699000002" });
  await set("users/parent-q", { role: "parent", firstName: "Querida", accountStatus: "active" });

  const child = async (
    uid: string,
    firstName: string,
    establishmentId: string,
    phoneNumber: string | null,
  ) => {
    await auth.createUser(phoneNumber ? { uid, phoneNumber } : { uid });
    await set(`users/${uid}`, { role: "student", firstName, establishmentId, classLevel: "Terminale" });
    await set(`student_profiles/${uid}`, { firstName, classLevel: "Terminale", establishmentId });
  };
  await child("child-code-a", "Awa", "school-a", null);
  await child("child-phone-b", "Bilal", "school-b", "+237677000002");
  await child("child-both-a", "Chloé", "school-a", "+237677000003");
  const link = (parentId: string, studentId: string) =>
    set(`children_links/${parentId}_${studentId}`, { parentId, studentId, status: "approved", linkedVia: "code" });
  await link("parent-p", "child-code-a");
  await link("parent-p", "child-phone-b");
  await link("parent-p", "child-both-a");
  await link("parent-q", "child-phone-b");

  const issue = createIssueStudentAccessCodeHandler(() => pepper, accessStore);
  await issue({ auth: { uid: "parent-p" }, data: { studentId: "child-code-a" } } as never);
  await issue({ auth: { uid: "parent-p" }, data: { studentId: "child-both-a" } } as never);
}

const childrenOf = async (uid: string) =>
  (await listChildren({ auth: { uid }, data: {} } as never)).children;
const byId = (children: ParentChildSummary[]) => new Map(children.map((child) => [child.studentId, child]));

let payments = 0;
async function pay(parentId: string, beneficiaryStudentId: string, offerId: string, payerPhone = "670000009") {
  payments++;
  return mobileMoney.submitParentPayment(parentId, {
    offerId,
    beneficiaryStudentId,
    operatorCode: "mtn",
    payerPhone,
    transactionReference: `TX-FAMILY-${1000 + payments}`,
    clientRequestId: `family_request_${1000 + payments}`,
  });
}

const usage = (billableUnits: number) => ({ inputUnits: billableUnits / 2, outputUnits: billableUnits / 2, billableUnits });

beforeEach(async () => {
  await clearEmulators();
  await seedFamily();
});

afterAll(async () => {
  await firestore.terminate();
  await deleteApp(app);
});

describe("students with their own phones — parental visibility and payer (addendum 1)", () => {
  it("A/B/D — a parent sees three children with mixed access, never a credential", async () => {
    const children = byId(await childrenOf("parent-p"));
    expect([...children.keys()].sort()).toEqual(["child-both-a", "child-code-a", "child-phone-b"]);
    expect(children.get("child-code-a")!.access).toMatchObject({ ownPhone: false, accessCode: true });
    expect(children.get("child-phone-b")!.access).toMatchObject({ ownPhone: true, accessCode: false });
    expect(children.get("child-both-a")!.access).toMatchObject({ ownPhone: true, accessCode: true });
    const serialized = JSON.stringify([...children.values()]);
    expect(serialized).not.toContain("+23767700000");
    expect(serialized).not.toMatch(/lookupKey|[0-9a-f]{64}/);
  });

  it("C — adding an access code to an own-phone child keeps ONE student UID for both methods", async () => {
    const { code } = await createIssueStudentAccessCodeHandler(() => pepper, accessStore)(
      { auth: { uid: "parent-q" }, data: { studentId: "child-phone-b" } } as never,
    );
    const { token } = await createSignInWithStudentAccessCodeHandler(() => pepper, accessStore, auth)(
      { data: { code }, rawRequest: { ip: "203.0.113.30", headers: {} } } as never,
    );
    const payload = JSON.parse(Buffer.from(token.split(".")[1], "base64url").toString("utf8"));
    expect(payload.uid).toBe("child-phone-b");
    expect((await auth.getUserByPhoneNumber("+237677000002")).uid).toBe("child-phone-b");
    expect(byId(await childrenOf("parent-p")).get("child-phone-b")!.access)
      .toMatchObject({ ownPhone: true, accessCode: true });
  });

  it("E/F — a parent pays for an own-phone child with another phone; identity comes from Auth, never from the payer phone", async () => {
    const submitted = await pay("parent-p", "child-phone-b", "school-b", "690111222");
    const request = (await firestore.doc(`mobile_money_payment_requests/${submitted.requestId}`).get()).data()!;
    expect(request).toMatchObject({
      parentId: "parent-p",
      payerType: "parent",
      payerId: "parent-p",
      beneficiaryStudentId: "child-phone-b",
      establishmentId: "school-b",
      offerId: "school-b",
      payerPhone: "+237690111222",
    });
    expect(request.payerPhone).not.toBe(PARENT_PHONE);
    await expect(auth.getUserByPhoneNumber("+237690111222")).rejects.toMatchObject({ code: "auth/user-not-found" });
    // Un enfant qui n'est pas le sien est refusé.
    await expect(pay("parent-q", "child-code-a", "school-a")).rejects.toMatchObject({ code: "permission-denied" });
  });

  it("G — two parents see the same child; the payer is named relative to each viewer", async () => {
    const submitted = await pay("parent-p", "child-phone-b", "school-b");
    await mobileMoney.reviewPayment("head-b", { requestId: submitted.requestId, decision: "approved" });
    expect(byId(await childrenOf("parent-p")).get("child-phone-b")!.subscription)
      .toMatchObject({ status: "active", paidBy: "you", offerId: "school-b" });
    const forQ = byId(await childrenOf("parent-q"));
    expect([...forQ.keys()]).toEqual(["child-phone-b"]);
    expect(forQ.get("child-phone-b")!.subscription).toMatchObject({ status: "active", paidBy: "another_guardian" });
  });

  it("H — the Study Reserve is per child", async () => {
    for (const [beneficiary, school, reviewer] of [["child-code-a", "school-a", "head-a"], ["child-phone-b", "school-b", "head-b"]]) {
      const submitted = await pay("parent-p", beneficiary, school);
      await mobileMoney.reviewPayment(reviewer, { requestId: submitted.requestId, decision: "approved" });
    }
    await consumption.run(
      { studentId: "child-code-a", requestId: "tutor-1", provider: "vertex", model: "gemini", estimateUnits: 1000 },
      async () => ({ result: "ok", usage: usage(300_000) }),
    );
    const reserve = async (id: string) => (await firestore.doc(`study_reserve/${id}`).get()).data();
    expect(await reserve("child-code-a")).toMatchObject({ consumed: 300_000, allowanceInternal: 600_000 });
    for (const other of ["child-both-a", "child-phone-b"]) {
      await consumption.run(
        { studentId: other, requestId: `tutor-${other}`, provider: "vertex", model: "gemini", estimateUnits: 1 },
        async () => ({ result: "ok", usage: usage(0) }),
      );
      expect((await reserve(other))?.consumed).toBe(0);
    }
  });
});

describe("one parent, children in different establishments (addendum 2)", () => {
  it("A — both schools are visible, named per child, with no single family school", async () => {
    const children = byId(await childrenOf("parent-p"));
    expect(children.get("child-code-a")).toMatchObject({ establishmentId: "school-a", establishmentName: "Lycée A", offerAvailable: true });
    expect(children.get("child-phone-b")).toMatchObject({ establishmentId: "school-b", establishmentName: "Collège B", offerAvailable: true });
    expect((await firestore.doc("users/parent-p").get()).data()?.establishmentId).toBeUndefined();
  });

  it("B/C — choosing the child chooses the school and its own offer; the legacy call keeps its refusal", async () => {
    const forA = await mobileMoney.getParentOverview("parent-p", { beneficiaryStudentId: "child-code-a" });
    expect(forA).toMatchObject({ availability: "available", offer: { id: "school-a", amountXaf: 2500 } });
    const forB = await mobileMoney.getParentOverview("parent-p", { beneficiaryStudentId: "child-phone-b" });
    expect(forB).toMatchObject({ availability: "available", offer: { id: "school-b", amountXaf: 4000, durationDays: 90 } });
    const legacy = await mobileMoney.getParentOverview("parent-p");
    expect(legacy).toMatchObject({ availability: "multiple_schools", offer: null });
    expect(legacy.children.map((child) => child.studentId).sort()).toEqual(["child-both-a", "child-code-a", "child-phone-b"]);

    const requestA = await pay("parent-p", "child-code-a", "school-a");
    const requestB = await pay("parent-p", "child-phone-b", "school-b");
    expect((await firestore.doc(`mobile_money_payment_requests/${requestA.requestId}`).get()).data())
      .toMatchObject({ establishmentId: "school-a", offerId: "school-a", amountXaf: 2500 });
    expect((await firestore.doc(`mobile_money_payment_requests/${requestB.requestId}`).get()).data())
      .toMatchObject({ establishmentId: "school-b", offerId: "school-b", amountXaf: 4000 });
    // L'offre d'une autre école que celle de l'enfant est refusée.
    await expect(pay("parent-p", "child-code-a", "school-b")).rejects.toMatchObject({ code: "permission-denied" });
  });

  it("D/E — each child gets its school's offer and plan; consuming A's reserve leaves B unchanged", async () => {
    const requestA = await pay("parent-p", "child-code-a", "school-a");
    const requestB = await pay("parent-p", "child-phone-b", "school-b");
    await mobileMoney.reviewPayment("head-a", { requestId: requestA.requestId, decision: "approved" });
    await mobileMoney.reviewPayment("head-b", { requestId: requestB.requestId, decision: "approved" });

    const entitlementA = (await firestore.doc("entitlements/parent-p_school-a").get()).data()!;
    const entitlementB = (await firestore.doc("entitlements/parent-p_school-b").get()).data()!;
    expect(entitlementA).toMatchObject({ offerId: "school-a", payerId: "parent-p", lastBeneficiaryStudentId: "child-code-a" });
    expect(entitlementB).toMatchObject({ offerId: "school-b", payerId: "parent-p", lastBeneficiaryStudentId: "child-phone-b" });
    expect(entitlementB.endsAt.toMillis() - entitlementB.startsAt.toMillis()).toBe(90 * DAY);
    expect((await provisioning.resolveEntitlement("child-code-a"))?.offerId).toBe("school-a");
    expect((await provisioning.resolveEntitlement("child-phone-b"))?.offerId).toBe("school-b");

    await consumption.run(
      { studentId: "child-phone-b", requestId: "warmup-b", provider: "vertex", model: "gemini", estimateUnits: 1 },
      async () => ({ result: "ok", usage: usage(0) }),
    );
    const before = (await firestore.doc("study_reserve/child-phone-b").get()).data()!;
    await consumption.run(
      { studentId: "child-code-a", requestId: "tutor-a", provider: "vertex", model: "gemini", estimateUnits: 1000 },
      async () => ({ result: "ok", usage: usage(450_000) }),
    );
    expect((await firestore.doc("study_reserve/child-code-a").get()).data())
      .toMatchObject({ consumed: 450_000, allowanceInternal: 600_000 });
    expect((await firestore.doc("study_reserve/child-phone-b").get()).data())
      .toMatchObject({ consumed: before.consumed, allowanceInternal: 900_000 });
  });

  it("F/G — school head A never sees or reviews B's payment for the same parent; the super admin sees both", async () => {
    const requestA = await pay("parent-p", "child-code-a", "school-a");
    const requestB = await pay("parent-p", "child-phone-b", "school-b");
    const seenByA = await mobileMoney.listRequestsForReviewer("head-a", "pending");
    expect(seenByA.map((request) => request.requestId)).toEqual([requestA.requestId]);
    await expect(mobileMoney.reviewPayment("head-a", { requestId: requestB.requestId, decision: "approved" }))
      .rejects.toMatchObject({ code: "permission-denied" });
    const seenByRoot = await mobileMoney.listRequestsForReviewer("root", "pending");
    expect(seenByRoot.map((request) => request.requestId).sort()).toEqual([requestA.requestId, requestB.requestId].sort());
    // Le modèle de lecture parent n'est pas une porte d'entrée pour une direction.
    await expect(listChildren({ auth: { uid: "head-a" }, data: {} } as never)).rejects.toMatchObject({ code: "permission-denied" });
    await expect(listChildren({ auth: { uid: "head-a" }, data: { parentUid: "parent-p" } } as never))
      .rejects.toMatchObject({ code: "permission-denied" });
    expect((await listChildren({ auth: { uid: "root" }, data: { parentUid: "parent-p" } } as never)).children).toHaveLength(3);
  });

  it("H — two children in the same school: one payment covers both, explicitly, and not the child elsewhere", async () => {
    const submitted = await pay("parent-p", "child-code-a", "school-a");
    const request = (await firestore.doc(`mobile_money_payment_requests/${submitted.requestId}`).get()).data()!;
    expect(request.beneficiaryScope).toBe("parent_children_in_establishment");
    expect([...request.coveredStudentIds].sort()).toEqual(["child-both-a", "child-code-a"]);
    await mobileMoney.reviewPayment("head-a", { requestId: submitted.requestId, decision: "approved" });
    const children = byId(await childrenOf("parent-p"));
    expect(children.get("child-code-a")!.subscription.status).toBe("active");
    expect(children.get("child-both-a")!.subscription.status).toBe("active");
    expect(children.get("child-phone-b")!.subscription.status).toBe("inactive");
  });

  it("announcements reach linked parents through each child's school, once, and never another school's parents", async () => {
    const publish = async (id: string, establishmentId: string, audience: string) => {
      await defaultDb.doc(`announcements/${id}`).set({
        title: "Réunion",
        message: "Réunion des familles vendredi.",
        audience,
        establishmentId,
        createdBy: "head-a",
      });
      await fanoutAnnouncementHandler({ data: await defaultDb.doc(`announcements/${id}`).get() } as never);
    };
    const recipients = async (id: string) =>
      (await firestore.collection("notifications").where("sourceId", "==", id).get()).docs
        .map((document) => document.data().userId as string)
        .sort();

    await publish("news-a", "school-a", "Tout l'établissement");
    expect(await recipients("news-a")).toEqual(["child-both-a", "child-code-a", "head-a", "parent-p"]);
    await publish("news-b-parents", "school-b", "Parents");
    expect(await recipients("news-b-parents")).toEqual(["parent-p", "parent-q"]);
    await publish("news-b-students", "school-b", "Élèves");
    expect(await recipients("news-b-students")).toEqual(["child-phone-b"]);
  });
});
