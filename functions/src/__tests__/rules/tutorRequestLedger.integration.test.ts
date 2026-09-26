import { initializeApp } from "firebase-admin/app";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { beforeEach, describe, expect, it } from "vitest";

import {
  FirestoreTutorRequestLedger,
  TUTOR_REQUEST_COLLECTION,
  TUTOR_REQUEST_RETENTION_MS,
  tutorRequestDocumentId,
} from "../../services/tutorRequestLedger";

/**
 * Contrat de rétention du registre d'idempotence du tuteur : chaque document
 * `tutor_requests` porte un `expireAt` valide (création + 15 min), jamais
 * repoussé par les écritures suivantes, et aucune écriture ne recrée un
 * document sans échéance. La politique TTL Firestore s'appuie sur ce champ.
 */
if (!process.env.FIRESTORE_EMULATOR_HOST) throw new Error("Emulator required.");

const app = initializeApp({ projectId: "demo-intellia237" }, "tutor-ledger-integration");
const firestore = getFirestore(app);
const T0 = Date.parse("2026-09-22T08:00:00.000Z");
let nowMs = T0;
const ledger = new FirestoreTutorRequestLedger(firestore, () => nowMs);
const LEASE = 75_000;

async function document(userId: string, requestId: string) {
  return (await firestore
    .collection(TUTOR_REQUEST_COLLECTION)
    .doc(tutorRequestDocumentId(userId, requestId))
    .get()).data();
}

function expectValidExpireAt(data: FirebaseFirestore.DocumentData | undefined, createdAt: number) {
  expect(data?.expireAt).toBeInstanceOf(Timestamp);
  expect((data!.expireAt as Timestamp).toMillis()).toBe(createdAt + TUTOR_REQUEST_RETENTION_MS);
}

describe("tutor_requests expireAt contract", () => {
  beforeEach(async () => {
    nowMs = T0;
    const documents = await firestore.collection(TUTOR_REQUEST_COLLECTION).listDocuments();
    await Promise.all(documents.map((ref) => ref.delete()));
  });

  it("the claim creates the document with expireAt and its owner", async () => {
    await ledger.claim({ userId: "s1", requestId: "req-00000001", payloadHash: "h", leaseMs: LEASE });
    const data = await document("s1", "req-00000001");
    expectValidExpireAt(data, T0);
    expect(data?.userId).toBe("s1");
  });

  it("complete and fail keep the original expireAt", async () => {
    await ledger.claim({ userId: "s1", requestId: "req-completed", payloadHash: "h", leaseMs: LEASE });
    nowMs = T0 + 30_000;
    await ledger.complete({
      userId: "s1",
      requestId: "req-completed",
      response: { text: "Réponse", limit: 20, remaining: 19, resetsAt: "2026-09-22T23:00:00.000Z" },
    });
    expectValidExpireAt(await document("s1", "req-completed"), T0);

    nowMs = T0;
    await ledger.claim({ userId: "s1", requestId: "req-failed", payloadHash: "h", leaseMs: LEASE });
    nowMs = T0 + 30_000;
    await ledger.fail({ userId: "s1", requestId: "req-failed", quotaCharged: false });
    expectValidExpireAt(await document("s1", "req-failed"), T0);
  });

  it("a retry keeps the first expireAt instead of extending it", async () => {
    await ledger.claim({ userId: "s1", requestId: "req-retry", payloadHash: "h", leaseMs: LEASE });
    await ledger.fail({ userId: "s1", requestId: "req-retry", quotaCharged: false });
    nowMs = T0 + 60_000;
    const claim = await ledger.claim({ userId: "s1", requestId: "req-retry", payloadHash: "h", leaseMs: LEASE });
    expect(claim.kind).toBe("execute");
    expectValidExpireAt(await document("s1", "req-retry"), T0);
  });

  it("never recreates a vanished record without expireAt", async () => {
    await expect(ledger.complete({
      userId: "s1",
      requestId: "req-vanished",
      response: { text: "Réponse", limit: 20, remaining: 19, resetsAt: "2026-09-22T23:00:00.000Z" },
    })).rejects.toBeDefined();
    await expect(ledger.fail({ userId: "s1", requestId: "req-vanished", quotaCharged: true }))
      .rejects.toBeDefined();
    expect(await document("s1", "req-vanished")).toBeUndefined();
  });

  it("every stored record carries a valid expireAt", async () => {
    for (const requestId of ["req-a-000001", "req-b-000002", "req-c-000003"]) {
      await ledger.claim({ userId: "s2", requestId, payloadHash: requestId, leaseMs: LEASE });
    }
    await ledger.complete({
      userId: "s2",
      requestId: "req-a-000001",
      response: { text: "Réponse", limit: 20, remaining: 19, resetsAt: "2026-09-22T23:00:00.000Z" },
    });
    await ledger.fail({ userId: "s2", requestId: "req-b-000002", quotaCharged: true });
    const all = await firestore.collection(TUTOR_REQUEST_COLLECTION).get();
    expect(all.size).toBe(3);
    for (const stored of all.docs) {
      expect(stored.get("expireAt"), stored.id).toBeInstanceOf(Timestamp);
      expect((stored.get("expireAt") as Timestamp).toMillis(), stored.id)
        .toBeGreaterThan(T0);
    }
  });
});
