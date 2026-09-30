/**
 * Primitives pures de la Réserve d'étude, sans dépendance Firestore.
 *
 * Module feuille : importé par la lecture (studyReserve), le provisionnement et
 * la consommation sans créer de cycle d'import au chargement des Functions.
 */

/** Seuils d'alerte, du plus haut au plus bas (une seule émission par cycle). */
export const RESERVE_THRESHOLDS = [75, 50, 25, 5, 0] as const;
export type ReserveThreshold = (typeof RESERVE_THRESHOLDS)[number];

/** Seuil lu depuis une donnée héritée : seules les valeurs connues sont gardées. */
export function sanitizeThreshold(value: unknown): ReserveThreshold | null {
  return (RESERVE_THRESHOLDS as readonly unknown[]).includes(value)
    ? (value as ReserveThreshold)
    : null;
}

/** Quantité interne lue depuis une donnée héritée : fini et positif, sinon 0. */
export function safeUnits(value: unknown): number {
  const n = typeof value === "number" ? value : Number(value);
  return Number.isFinite(n) && n > 0 ? n : 0;
}
