/**
 * Rattrapage des clés d'audience Parcours sur les publications existantes.
 *
 * Pourquoi : la lecture indexée (FLOW_AUDIENCE_INDEX=true) ne voit que les
 * documents porteurs de `audienceKeys` et de `publishedAt`. Les nouvelles
 * publications les reçoivent à l'écriture ; les anciennes doivent être
 * complétées une fois, AVANT d'activer le drapeau.
 *
 * Sûreté :
 * - à blanc par défaut : affiche ce qui changerait, n'écrit rien ;
 * - `--apply` écrit, par lots de 400, uniquement `audienceKeys` (et
 *   `publishedAt` quand une publication publiée n'en a pas) ;
 * - idempotent : un document déjà à jour n'est pas réécrit ;
 * - aucun autre champ n'est touché.
 *
 * Usage (ADC du projet cible) :
 *   npx tsx scripts/backfillFlowAudienceKeys.ts --project edunova-aabd1
 *   npx tsx scripts/backfillFlowAudienceKeys.ts --project edunova-aabd1 --apply
 */
import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

import { flowAudienceKeys } from "../src/services/contentAudience";

function argument(name: string): string | undefined {
  const index = process.argv.indexOf(name);
  return index >= 0 ? process.argv[index + 1] : undefined;
}

async function main() {
  const projectId = argument("--project");
  if (!projectId) throw new Error("--project est obligatoire (aucun projet implicite).");
  const apply = process.argv.includes("--apply");
  const app = initializeApp({ projectId }, "flow-audience-backfill");
  const firestore = getFirestore(app);

  const snapshot = await firestore.collection("flow_items").get();
  let changed = 0;
  let batch = firestore.batch();
  let pending = 0;
  for (const doc of snapshot.docs) {
    const data = doc.data();
    const keys = flowAudienceKeys(data);
    const current = Array.isArray(data.audienceKeys) ? [...data.audienceKeys].sort() : null;
    const update: Record<string, unknown> = {};
    if (JSON.stringify(current) !== JSON.stringify(keys)) update.audienceKeys = keys;
    if (data.status === "published" && typeof data.publishedAt !== "string") {
      update.publishedAt = typeof data.updatedAt === "string" ? data.updatedAt : new Date(doc.createTime.toMillis()).toISOString();
    }
    if (Object.keys(update).length === 0) continue;
    changed += 1;
    console.log(`${apply ? "UPDATE" : "WOULD UPDATE"} flow_items/${doc.id}`, update);
    if (!apply) continue;
    batch.update(doc.ref, update);
    pending += 1;
    if (pending === 400) {
      await batch.commit();
      batch = firestore.batch();
      pending = 0;
    }
  }
  if (apply && pending > 0) await batch.commit();
  console.log(`${snapshot.size} publications lues, ${changed} ${apply ? "mises à jour" : "à mettre à jour (à blanc)"}.`);
}

main().catch((error) => {
  console.error(error instanceof Error ? error.message : error);
  process.exitCode = 1;
});
