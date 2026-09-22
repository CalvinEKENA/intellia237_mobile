import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { beforeEach, describe, expect, it } from "vitest";

import { AskTutorUseCase, type TutorContextStore } from "../../services/askTutorUseCase";
import {
  FirestoreStudyReserveConsumptionStore,
  FirestoreThresholdNotifier,
  StudyReserveConsumption,
} from "../../services/studyReserveConsumption";
import { FirestoreStudyReserveProvisioningStore } from "../../services/studyReserveProvisioning";
import { FirestoreTutorQuotaStore } from "../../services/tutorDailyQuota";
import type { AskTutorCallableInput } from "../../utils/validation";

/**
 * Quota quotidien du tuteur contre l'émulateur Firestore, horloge injectée.
 * Une question appartient à la journée (Africa/Douala, UTC+1) de sa
 * réservation, même quand la réponse arrive après minuit.
 */
if (!process.env.FIRESTORE_EMULATOR_HOST) throw new Error("Emulator required.");

const app = initializeApp({ projectId: "demo-intellia237" }, "tutor-quota-integration");
const firestore = getFirestore(app);

// 23:59:59 à Douala le 21 septembre = 22:59:59 UTC ; 00:00:01 le 22 = 23:00:01 UTC.
const BEFORE_MIDNIGHT = Date.parse("2026-09-21T22:59:59.000Z");
const AFTER_MIDNIGHT = Date.parse("2026-09-21T23:00:01.000Z");
const DAY_J = "2026-09-21";
const DAY_J1 = "2026-09-22";
const LIMIT = 20;

let nowMs = BEFORE_MIDNIGHT;
const clock = () => new Date(nowMs);

async function bucket(userId: string, dayKey: string) {
  const snapshot = await firestore.doc(`ai_tutor_daily_usage/${userId}_${dayKey}`).get();
  return snapshot.data() ?? null;
}

async function clear() {
  const documents = await firestore.collection("ai_tutor_daily_usage").listDocuments();
  await Promise.all(documents.map((document) => document.delete()));
}

describe("tutor daily quota across midnight (Africa/Douala)", () => {
  beforeEach(async () => {
    nowMs = BEFORE_MIDNIGHT;
    await clear();
  });

  it("consumes the original reservation of day J, answered after midnight", async () => {
    const store = new FirestoreTutorQuotaStore(firestore, clock);
    const reservation = await store.reserve({ userId: "s-midnight", traceId: "q-1", limit: LIMIT });
    expect(reservation.dayKey).toBe(DAY_J);

    nowMs = AFTER_MIDNIGHT;
    const shown = await store.consume({
      userId: "s-midnight",
      traceId: "q-1",
      limit: LIMIT,
      dayKey: reservation.dayKey,
    });

    const dayJ = await bucket("s-midnight", DAY_J);
    expect(dayJ?.usedCount).toBe(1);
    expect(dayJ?.reservations).toEqual({});
    expect((await bucket("s-midnight", DAY_J1))?.usedCount ?? 0).toBe(0);
    // L'élève voit sa nouvelle journée, intacte.
    expect(shown.remaining).toBe(LIMIT);
    expect(shown.resetsAt).toBe("2026-09-22T23:00:00.000Z");
  });

  it("counts a question once, even when consume is replayed", async () => {
    const store = new FirestoreTutorQuotaStore(firestore, clock);
    const reservation = await store.reserve({ userId: "s-dup", traceId: "q-1", limit: LIMIT });
    const first = await store.consume({ userId: "s-dup", traceId: "q-1", limit: LIMIT, dayKey: reservation.dayKey });
    const again = await store.consume({ userId: "s-dup", traceId: "q-1", limit: LIMIT, dayKey: reservation.dayKey });
    expect((await bucket("s-dup", DAY_J))?.usedCount).toBe(1);
    expect(first.remaining).toBe(LIMIT - 1);
    expect(again.remaining).toBe(LIMIT - 1);
  });

  it("reserve J then consume J behaves as before", async () => {
    const store = new FirestoreTutorQuotaStore(firestore, clock);
    const reservation = await store.reserve({ userId: "s-same", traceId: "q-1", limit: LIMIT });
    expect(reservation.remaining).toBe(LIMIT - 1);
    nowMs = BEFORE_MIDNIGHT + 500;
    const shown = await store.consume({ userId: "s-same", traceId: "q-1", limit: LIMIT });
    expect(shown.remaining).toBe(LIMIT - 1);
    expect((await bucket("s-same", DAY_J))?.usedCount).toBe(1);
  });

  it("releases the original reservation after midnight, charging nothing", async () => {
    const store = new FirestoreTutorQuotaStore(firestore, clock);
    const reservation = await store.reserve({ userId: "s-release", traceId: "q-1", limit: LIMIT });
    nowMs = AFTER_MIDNIGHT;
    await store.release({ userId: "s-release", traceId: "q-1", dayKey: reservation.dayKey });
    const dayJ = await bucket("s-release", DAY_J);
    expect(dayJ?.reservations).toEqual({});
    expect(dayJ?.usedCount ?? 0).toBe(0);
  });

  it("askTutor charges the day of the question when the answer crosses midnight", async () => {
    const quota = new FirestoreTutorQuotaStore(firestore, clock);
    const context: TutorContextStore = {
      loadAuthorizedContext: async () => ({
        scope: { classLevel: "6eme", establishmentId: null },
        text: "",
        language: "fr",
      }),
    };
    const reserve = new StudyReserveConsumption(
      new FirestoreStudyReserveConsumptionStore(() => nowMs, firestore),
      new FirestoreThresholdNotifier(firestore),
      new FirestoreStudyReserveProvisioningStore(() => nowMs, firestore),
    );
    const useCase = new AskTutorUseCase(
      context,
      async (params) => {
        // Gemini répond après minuit.
        nowMs = AFTER_MIDNIGHT;
        params.onUsage?.({ promptTokenCount: 10, candidatesTokenCount: 20, totalTokenCount: 30 });
        return "Voici la réponse.";
      },
      quota,
      LIMIT,
      reserve,
    );
    const input = {
      userMessage: "Explique les fractions",
      history: [],
      classLevel: "6eme",
      tutorId: "kira",
    } as AskTutorCallableInput;

    const answer = await useCase.execute({ userId: "s-usecase", traceId: "trace-midnight", input });

    expect(answer.text).toBe("Voici la réponse.");
    const dayJ = await bucket("s-usecase", DAY_J);
    expect(dayJ?.usedCount).toBe(1);
    expect(dayJ?.reservations).toEqual({});
    expect((await bucket("s-usecase", DAY_J1))?.usedCount ?? 0).toBe(0);
  });
});
