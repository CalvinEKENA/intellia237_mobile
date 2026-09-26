import { deleteApp, initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import type { CallableRequest } from "firebase-functions/v2/https";
import { afterAll, beforeEach, describe, expect, it } from "vitest";

import { AskTutorUseCase, type TutorContextStore } from "../../services/askTutorUseCase";
import { FirestoreMobileMoneyStore } from "../../services/mobileMoneyCallables";
import { classifyNotificationDelivery } from "../../services/notificationDelivery";
import { createGetStudyReserveHandler, FirestoreStudyReserveStore } from "../../services/studyReserve";
import {
  FirestoreStudyReserveConsumptionStore,
  FirestoreThresholdNotifier,
  StudyReserveConsumption,
} from "../../services/studyReserveConsumption";
import {
  ensureCurrentStudyReserveCycle,
  FirestoreStudyReserveProvisioningStore,
} from "../../services/studyReserveProvisioning";
import type { TutorQuotaStore } from "../../services/tutorDailyQuota";

/**
 * Chaîne Réserve d'étude complète contre l'émulateur Firestore, avec les stores
 * de PRODUCTION : paiement Mobile Money réel → entitlement → offre → plan →
 * provisionnement → réservation transactionnelle → commit → notification.
 */
if (!process.env.FIRESTORE_EMULATOR_HOST) throw new Error("Emulator required.");

const app = initializeApp({ projectId: "demo-intellia237" }, "study-reserve-integration");
const firestore = getFirestore(app);
const DAY = 24 * 60 * 60 * 1000;

// En production, l'offre Mobile Money est indexée par établissement : offerId === establishmentId.
const ESTABLISHMENT = "lycee-bilingue-etoug-ebe";
const PLAN = { allowanceInternal: 600_000, cycleDays: 30 };

const mobileMoney = new FirestoreMobileMoneyStore(firestore);
const provisioningAt = (nowMs: number) =>
  new FirestoreStudyReserveProvisioningStore(() => nowMs, firestore);
const provisioning = new FirestoreStudyReserveProvisioningStore(() => Date.now(), firestore);
const consumptionStore = new FirestoreStudyReserveConsumptionStore(() => Date.now(), firestore);
const consumption = new StudyReserveConsumption(
  consumptionStore,
  new FirestoreThresholdNotifier(firestore),
  provisioning,
);
const getStudyReserve = createGetStudyReserveHandler(new FirestoreStudyReserveStore(firestore), provisioning);
const call = (uid: string, data: Record<string, unknown> = {}) =>
  ({ auth: { uid }, data }) as unknown as CallableRequest<{ studentId?: unknown }>;

const reserveDoc = (studentId: string) => firestore.doc(`study_reserve/${studentId}`);

let paymentCounter = 0;
async function payMobileMoney(): Promise<void> {
  paymentCounter++;
  const submitted = await mobileMoney.submitParentPayment("parent-p", {
    offerId: ESTABLISHMENT,
    operatorCode: "mtn",
    payerPhone: "670000000",
    transactionReference: `TX-SR-${1000 + paymentCounter}`,
    clientRequestId: `sr_request_${1000 + paymentCounter}`,
  });
  await mobileMoney.reviewPayment("admin-root", { requestId: submitted.requestId, decision: "approved" });
}

function tutorFor(billableUnits: number, onCall?: () => void) {
  const context: TutorContextStore = {
    loadAuthorizedContext: async () => ({
      scope: { classLevel: "Terminale", establishmentId: ESTABLISHMENT },
      text: "CONTEXTE",
    }),
  };
  const quota: TutorQuotaStore = {
    reserve: async ({ limit }) => ({ limit, remaining: limit - 1, resetsAt: "2026-09-15T23:00:00.000Z" }),
    consume: async ({ limit }) => ({ limit, remaining: limit - 1, resetsAt: "2026-09-15T23:00:00.000Z" }),
    release: async () => undefined,
  };
  return new AskTutorUseCase(
    context,
    async ({ onUsage }) => {
      onCall?.();
      onUsage?.({
        promptTokenCount: Math.floor(billableUnits / 2),
        candidatesTokenCount: Math.ceil(billableUnits / 2),
        totalTokenCount: billableUnits,
      });
      return "Réponse du tuteur";
    },
    quota,
    20,
    consumption,
  );
}

const input = {
  classLevel: "Terminale",
  userMessage: "Explique la photosynthèse.",
  history: [],
  tutorId: "kira" as const,
};

beforeEach(async () => {
  for (const name of [
    "users",
    "student_profiles",
    "parent_profiles",
    "children_links",
    "mobile_money_offers",
    "mobile_money_payment_requests",
    "mobile_money_reference_keys",
    "entitlements",
    "study_reserve",
    "study_reserve_plans",
    "notifications",
  ]) {
    await firestore.recursiveDelete(firestore.collection(name));
  }
  await firestore.doc("users/admin-root").set({ role: "superAdmin", accountStatus: "active" });
  await firestore.doc("users/parent-p").set({ role: "parent", accountStatus: "active" });
  await firestore.doc("parent_profiles/parent-p").set({ preferences: { language: "fr" } });
  for (const [child, lang] of [["child-a", "fr"], ["child-b", "en"]] as const) {
    await firestore.doc(`users/${child}`).set({
      role: "student",
      classLevel: "Terminale",
      establishmentId: ESTABLISHMENT,
    });
    await firestore.doc(`student_profiles/${child}`).set({
      classLevel: "Terminale",
      preferences: { interfaceLanguage: lang },
    });
    await firestore.doc(`children_links/parent-p_${child}`).set({
      parentId: "parent-p",
      studentId: child,
      status: "approved",
      linkedVia: "code",
    });
  }
  await firestore.doc(`mobile_money_offers/${ESTABLISHMENT}`).set({
    status: "active",
    establishmentId: ESTABLISHMENT,
    title: "Abonnement mensuel",
    description: "Accès INTELLIA237 pour la famille.",
    amountXaf: 2500,
    currency: "XAF",
    durationDays: 30,
    operators: [{ code: "mtn", label: "MTN Mobile Money", recipientPhone: "+237670000000" }],
  });
  await firestore.doc(`study_reserve_plans/${ESTABLISHMENT}`).set(PLAN);
  await payMobileMoney();
});

afterAll(() => deleteApp(app));

describe("Study Reserve — production stores on the emulator", () => {
  it("joins student → school → approved parent → Mobile Money entitlement.offerId → plan", async () => {
    const entitlement = (await firestore.doc(`entitlements/parent-p_${ESTABLISHMENT}`).get()).data();
    expect(entitlement).toMatchObject({ status: "active", offerId: ESTABLISHMENT, establishmentId: ESTABLISHMENT });

    const resolved = await provisioning.resolveEntitlement("child-a");
    expect(resolved).toMatchObject({ offerId: ESTABLISHMENT, active: true });
    expect(resolved!.windowEndMs - resolved!.windowStartMs).toBe(30 * DAY);
    expect(await provisioning.planConfig(resolved!.offerId)).toEqual(PLAN);
  });

  it("getStudyReserve auto-provisions each child independently, readable by the linked parent", async () => {
    expect((await reserveDoc("child-a").get()).exists).toBe(false);

    const own = await getStudyReserve(call("child-a"));
    expect(own).toMatchObject({ percentRemaining: 100, status: "healthy" });
    expect(Object.keys(own)).not.toContain("allowanceInternal");
    const viaParent = await getStudyReserve(call("parent-p", { studentId: "child-b" }));
    expect(viaParent).toMatchObject({ studentId: "child-b", percentRemaining: 100 });

    const a = (await reserveDoc("child-a").get()).data()!;
    const b = (await reserveDoc("child-b").get()).data()!;
    expect(a).toMatchObject({ allowanceInternal: 600_000, consumed: 0, latestThresholdEmitted: null, holds: {} });
    expect(b).toMatchObject({ allowanceInternal: 600_000, consumed: 0 });
    expect(a.cycleId).toMatch(new RegExp(`^${ESTABLISHMENT}_\\d+_0$`));
    await expect(getStudyReserve(call("child-b", { studentId: "child-a" }))).rejects.toMatchObject({
      code: "permission-denied",
    });
  });

  it("askTutor provisions, charges real usage to one child only, and notifies once per recipient", async () => {
    await getStudyReserve(call("child-b"));
    const before = (await reserveDoc("child-b").get()).data();

    await tutorFor(300_000).execute({ userId: "child-a", traceId: "trace-a-1", input });

    expect(await getStudyReserve(call("child-a"))).toMatchObject({ percentRemaining: 50, status: "warning" });
    expect(await getStudyReserve(call("parent-p", { studentId: "child-b" }))).toMatchObject({ percentRemaining: 100 });
    expect((await reserveDoc("child-b").get()).data()).toEqual(before);

    const a = (await reserveDoc("child-a").get()).data()!;
    expect(a).toMatchObject({ consumed: 300_000, holds: {}, latestThresholdEmitted: 50 });
    const ledger = await reserveDoc("child-a").collection("ledger").doc(`${a.cycleId}__trace-a-1`).get();
    expect(ledger.data()).toMatchObject({ billableUnits: 300_000, provider: "vertex-ai" });

    const notes = await firestore.collection("notifications").get();
    const byUser = Object.fromEntries(notes.docs.map((d) => [d.data().userId, d.data()]));
    expect(Object.keys(byUser).sort()).toEqual(["child-a", "parent-p"]);
    expect(byUser["child-a"]).toMatchObject({ deliveryMode: "push", title: "Réserve d’étude", type: "study_reserve_threshold" });
    expect(classifyNotificationDelivery(byUser["child-a"])).toBe("deliverable");
    // Parent : aucune langue choisie de façon fiable → boîte de réception seule.
    expect(byUser["parent-p"]).toMatchObject({ deliveryMode: "inbox_only", title: "", body: "" });
    expect(classifyNotificationDelivery(byUser["parent-p"])).toBe("inbox_only");

    // Rejeu du même identifiant : aucun second débit, aucune seconde notification.
    await tutorFor(300_000).execute({ userId: "child-a", traceId: "trace-a-1", input });
    expect((await reserveDoc("child-a").get()).data()!.consumed).toBe(300_000);
    expect((await firestore.collection("notifications").get()).size).toBe(2);
  });

  it("real transactions: only one of two concurrent holds fits; commit removes only its own hold", async () => {
    await getStudyReserve(call("child-a"));
    await reserveDoc("child-a").update({ consumed: 598_500 }); // reste 1500

    const results = await Promise.allSettled([
      consumptionStore.reserve({ studentId: "child-a", requestId: "A", estimateUnits: 1000 }),
      consumptionStore.reserve({ studentId: "child-a", requestId: "B", estimateUnits: 1000 }),
    ]);
    expect(results.filter((r) => r.status === "fulfilled")).toHaveLength(1);
    const rejected = results.find((r) => r.status === "rejected") as PromiseRejectedResult;
    expect(rejected.reason).toMatchObject({ code: "resource-exhausted", details: { reason: "study_reserve_exhausted" } });

    // Deux réservations coexistantes : le commit de l'une ne laisse pas la sienne.
    await reserveDoc("child-a").update({ consumed: 0, holds: {} });
    await consumptionStore.reserve({ studentId: "child-a", requestId: "C", estimateUnits: 1000 });
    await consumptionStore.reserve({ studentId: "child-a", requestId: "D", estimateUnits: 1000 });
    await consumptionStore.commit({
      studentId: "child-a",
      requestId: "C",
      provider: "vertex-ai",
      model: "gemini",
      usage: { inputUnits: 200, outputUnits: 200, billableUnits: 400 },
    });
    const after = (await reserveDoc("child-a").get()).data()!;
    expect(after.consumed).toBe(400); // réel < estimation : seul le réel est débité
    expect(Object.keys(after.holds)).toEqual(["D"]);
    await consumptionStore.release({ studentId: "child-a", requestId: "D" });
    expect(Object.keys((await reserveDoc("child-a").get()).data()!.holds)).toEqual([]);
  });

  it("never calls the provider when the estimate does not fit; actual > hold floors at 0% and blocks", async () => {
    await getStudyReserve(call("child-a"));
    await reserveDoc("child-a").update({ consumed: 599_700 }); // reste 300 < 1000
    let calls = 0;
    await expect(
      tutorFor(10, () => calls++).execute({ userId: "child-a", traceId: "trace-small", input }),
    ).rejects.toMatchObject({ code: "resource-exhausted", details: { reason: "study_reserve_exhausted" } });
    expect(calls).toBe(0);

    await reserveDoc("child-a").update({ consumed: 599_000 }); // reste 1000 = estimation
    await tutorFor(1500).execute({ userId: "child-a", traceId: "trace-over", input });
    expect((await reserveDoc("child-a").get()).data()!.consumed).toBe(600_500); // réel enregistré tel quel
    expect(await getStudyReserve(call("child-a"))).toMatchObject({ percentRemaining: 0, status: "depleted" });
    await expect(
      tutorFor(10, () => calls++).execute({ userId: "child-a", traceId: "trace-after", input }),
    ).rejects.toMatchObject({ code: "resource-exhausted" });
    expect(calls).toBe(0); // bloqué avant tout appel fournisseur
  });

  it("provider failure releases the hold and charges nothing", async () => {
    await getStudyReserve(call("child-a"));
    const failing = new AskTutorUseCase(
      { loadAuthorizedContext: async () => ({ scope: { classLevel: "Terminale", establishmentId: ESTABLISHMENT }, text: "" }) },
      async () => {
        throw new Error("Vertex indisponible");
      },
      { reserve: async ({ limit }) => ({ limit, remaining: 1, resetsAt: "x" }), consume: async ({ limit }) => ({ limit, remaining: 1, resetsAt: "x" }), release: async () => undefined },
      20,
      consumption,
    );
    await expect(failing.execute({ userId: "child-a", traceId: "trace-fail", input })).rejects.toThrow("Vertex indisponible");
    expect((await reserveDoc("child-a").get()).data()).toMatchObject({ consumed: 0, holds: {} });
  });

  it("mid-cycle allowance change keeps consumption; missing config is a legitimate unavailable", async () => {
    await getStudyReserve(call("child-a"));
    await reserveDoc("child-a").update({ consumed: 300_000 });
    await firestore.doc(`study_reserve_plans/${ESTABLISHMENT}`).set({ allowanceInternal: 700_000, cycleDays: 30 });
    expect(await getStudyReserve(call("child-a"))).toMatchObject({ percentRemaining: 57 });
    expect((await reserveDoc("child-a").get()).data()).toMatchObject({ allowanceInternal: 700_000, consumed: 300_000 });

    await firestore.doc(`study_reserve_plans/${ESTABLISHMENT}`).set({ allowanceInternal: "700000" });
    expect(await getStudyReserve(call("child-a"))).toMatchObject({ status: "unavailable", percentRemaining: 0 });
    let calls = 0;
    await tutorFor(5000, () => calls++).execute({ userId: "child-a", traceId: "trace-unavailable", input });
    expect(calls).toBe(1); // le tuteur reste disponible (quota quotidien)
    expect((await reserveDoc("child-a").get()).data()).toMatchObject({ consumed: 300_000 }); // rien débité
  });

  it("early Mobile Money renewal keeps 30-day cycles; renewal resets only that child; expiry is unavailable", async () => {
    await getStudyReserve(call("child-a"));
    await getStudyReserve(call("child-b"));
    const first = (await firestore.doc(`entitlements/parent-p_${ESTABLISHMENT}`).get()).data()!;
    await payMobileMoney(); // renouvellement anticipé
    const renewed = (await firestore.doc(`entitlements/parent-p_${ESTABLISHMENT}`).get()).data()!;
    expect(renewed.startsAt.toMillis()).toBe(first.startsAt.toMillis());
    expect(renewed.endsAt.toMillis()).toBe(first.endsAt.toMillis() + 30 * DAY);

    await tutorFor(100_000).execute({ userId: "child-a", traceId: "trace-cycle0", input });
    await reserveDoc("child-a").update({ "holds.stale": { units: 1000, tsMs: Date.now() } });
    const startMs = first.startsAt.toMillis();
    const cycle0 = (await reserveDoc("child-a").get()).data()!;
    const childB0 = (await reserveDoc("child-b").get()).data();

    // Même tranche, juste avant la frontière : aucun reset.
    const sameSlice = await ensureCurrentStudyReserveCycle("child-a", provisioningAt(startMs + 30 * DAY - 1), startMs + 30 * DAY - 1);
    expect(sameSlice).toMatchObject({ cycleId: cycle0.cycleId, consumed: 100_000 });

    // Jour 30 : la fenêtre prolongée n'est pas un cycle géant, la tranche 1 s'ouvre.
    const slice1 = await ensureCurrentStudyReserveCycle("child-a", provisioningAt(startMs + 30 * DAY), startMs + 30 * DAY);
    expect(slice1).toMatchObject({ cycleId: `${ESTABLISHMENT}_${startMs}_1`, consumed: 0, latestThresholdEmitted: null });
    const a1 = (await reserveDoc("child-a").get()).data()!;
    expect(a1).toMatchObject({ consumed: 0, holds: {}, latestThresholdEmitted: null });
    expect(a1.cycleStart).toBe(new Date(startMs + 30 * DAY).toISOString());
    expect(a1.cycleEnd).toBe(new Date(startMs + 60 * DAY).toISOString());
    const ledger = await reserveDoc("child-a").collection("ledger").get();
    expect(ledger.docs.map((d) => d.id)).toEqual([`${cycle0.cycleId}__trace-cycle0`]); // historique conservé
    expect((await reserveDoc("child-b").get()).data()).toEqual(childB0);

    // Après la fin payée : réserve indisponible, documents conservés.
    const expired = createGetStudyReserveHandler(
      new FirestoreStudyReserveStore(firestore),
      provisioningAt(renewed.endsAt.toMillis() + 1),
    );
    expect(await expired(call("child-a"))).toMatchObject({ status: "unavailable" });
    expect((await reserveDoc("child-a").get()).exists).toBe(true);
  });
});
