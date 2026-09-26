import { readFileSync } from "node:fs";
import { join } from "node:path";

import { describe, expect, it } from "vitest";

import {
  TUTOR_REQUEST_COLLECTION,
  TUTOR_REQUEST_RETENTION_MS,
} from "../services/tutorRequestLedger";

/**
 * La suppression des réponses du compagnon conservées pour l'idempotence
 * repose sur une politique TTL Firestore. Elle est versionnée avec les index
 * (`firebase deploy --only firestore:indexes`) : ce test empêche qu'elle
 * disparaisse du fichier sans bruit.
 */
describe("tutor_requests TTL declaration", () => {
  const indexes = JSON.parse(
    readFileSync(join(__dirname, "..", "..", "..", "firestore.indexes.json"), "utf8"),
  ) as { fieldOverrides?: Array<Record<string, unknown>> };

  it("declares a TTL policy on tutor_requests.expireAt", () => {
    const override = (indexes.fieldOverrides ?? []).find(
      (field) => field.collectionGroup === TUTOR_REQUEST_COLLECTION && field.fieldPath === "expireAt",
    );
    expect(override).toBeDefined();
    expect(override?.ttl).toBe(true);
    // Champ TTL non indexé : aucune requête ne le lit.
    expect(override?.indexes).toEqual([]);
  });

  it("keeps the logical retention at 15 minutes", () => {
    expect(TUTOR_REQUEST_RETENTION_MS).toBe(15 * 60 * 1000);
  });
});
