import { readFileSync } from "node:fs";
import { join } from "node:path";

import { describe, expect, it } from "vitest";

/**
 * `readLearningCatalog` (action « subjects ») lit toutes les matières
 * publiées par une requête de groupe de collections filtrée sur `status`.
 * Firestore n'indexe pas un champ à l'échelle d'un groupe de collections par
 * défaut : sans cette déclaration, la requête est refusée en production alors
 * que l'émulateur l'accepte, et l'onglet Apprendre reste vide pour tout le
 * monde (QA appareil, 23/09/2026).
 */
describe("learning catalog index declaration", () => {
  const indexes = JSON.parse(
    readFileSync(join(__dirname, "..", "..", "..", "firestore.indexes.json"), "utf8"),
  ) as { fieldOverrides?: Array<{ collectionGroup: string; fieldPath: string; indexes: Array<Record<string, string>> }> };

  it("indexes subjects.status for collection-group queries", () => {
    const override = (indexes.fieldOverrides ?? []).find(
      (field) => field.collectionGroup === "subjects" && field.fieldPath === "status",
    );
    expect(override).toBeDefined();
    expect(override?.indexes).toContainEqual({ order: "ASCENDING", queryScope: "COLLECTION_GROUP" });
    // Les index de collection automatiques restent déclarés : une surcharge
    // les remplace, elle ne s'y ajoute pas.
    expect(override?.indexes).toContainEqual({ order: "ASCENDING", queryScope: "COLLECTION" });
    expect(override?.indexes).toContainEqual({ order: "DESCENDING", queryScope: "COLLECTION" });
  });
});
