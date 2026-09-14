import { FieldValue } from "firebase-admin/firestore";

import { db } from "../config/firebase";
import type { ReserveAggregate } from "./studyReserve";
import { sanitizeThreshold, safeUnits } from "./studyReserveUnits";

/**
 * Provisionnement autoritaire du cycle de Réserve d'étude à partir de
 * l'**entitlement réel** de l'élève (aucun seed manuel, aucune valeur inventée).
 *
 * Sources canoniques trouvées à l'audit :
 * - `entitlements/{parentId}_{establishmentId}` (écrit à l'approbation Mobile
 *   Money) : `status`, `startsAt`, `endsAt`, `offerId` — portée parent + école ;
 * - `mobile_money_offers/{establishmentId}` : titre, montant XAF, durée —
 *   **sans aucune allocation de Réserve d'étude**.
 *
 * L'allocation et la cadence de cycle sont donc une décision produit, lue dans
 * la configuration serveur `study_reserve_plans/{offerId}` :
 *   { allowanceInternal: entier > 0, cycleDays?: entier 1..366 }
 * Tant qu'elle n'existe pas, la réserve reste **unavailable** : ce module
 * n'invente ni allocation ni cadence.
 */

const DAY_MS = 24 * 60 * 60 * 1000;

export interface StudentEntitlement {
  offerId: string;
  /** Début de la fenêtre payée (préservé par Mobile Money lors d'un renouvellement anticipé). */
  windowStartMs: number;
  /** Fin de la fenêtre payée. */
  windowEndMs: number;
  active: boolean;
}

export interface StudyReservePlanConfig {
  allowanceInternal: number;
  /** Durée d'un cycle ; null → un cycle couvre toute la fenêtre payée. */
  cycleDays: number | null;
}

export interface CurrentCycle {
  cycleId: string;
  startMs: number;
  endMs: number;
}

export interface StudyReserveProvisioningStore {
  resolveEntitlement(studentId: string): Promise<StudentEntitlement | null>;
  planConfig(offerId: string): Promise<StudyReservePlanConfig | null>;
  readAggregate(studentId: string): Promise<ReserveAggregate | null>;
  /** Nouveau cycle (transactionnel, jamais de reset si le cycle est déjà en place). */
  provisionCycle(studentId: string, fresh: ReserveAggregate): Promise<ReserveAggregate>;
  /** Changement d'allocation en cours de cycle : met à jour l'allocation SANS
   * toucher à la consommation (seulement si le cycle correspond). */
  updateAllowance(
    studentId: string,
    cycleId: string,
    allowanceInternal: number,
  ): Promise<ReserveAggregate | null>;
}

/** Lit un document d'entitlement, y compris hérité/malformé. Null si inexploitable. */
export function parseEntitlementDocument(
  data: Record<string, unknown> | undefined,
  establishmentId: string,
  nowMs: number,
): StudentEntitlement | null {
  if (!data) return null;
  const endMs = toMillis(data.endsAt);
  if (endMs === null) return null; // fenêtre inconnue : on n'accorde rien
  const startRaw = toMillis(data.startsAt);
  const startMs = startRaw !== null && startRaw <= endMs ? startRaw : null;
  if (startMs === null) return null; // début absent/incohérent : pas de cycle fiable
  const offerId =
    typeof data.offerId === "string" && data.offerId.trim().length > 0
      ? data.offerId.trim()
      : establishmentId;
  return {
    offerId,
    windowStartMs: startMs,
    windowEndMs: endMs,
    active: data.status === "active" && endMs > nowMs && startMs <= nowMs,
  };
}

/** Valide la configuration de plan. Null si absente ou invalide. */
export function parsePlanConfig(
  data: Record<string, unknown> | undefined,
): StudyReservePlanConfig | null {
  if (!data) return null;
  const allowance = data.allowanceInternal;
  if (typeof allowance !== "number" || !Number.isInteger(allowance) || allowance <= 0) {
    return null;
  }
  const rawDays = data.cycleDays;
  let cycleDays: number | null = null;
  if (rawDays !== undefined && rawDays !== null) {
    if (typeof rawDays !== "number" || !Number.isInteger(rawDays) || rawDays < 1 || rawDays > 366) {
      return null; // cadence invalide : refuser plutôt que deviner
    }
    cycleDays = rawDays;
  }
  return { allowanceInternal: allowance, cycleDays };
}

/** Cycle courant : la fenêtre entière, ou la tranche de `cycleDays` contenant `now`. */
export function computeCurrentCycle(
  entitlement: StudentEntitlement,
  cycleDays: number | null,
  nowMs: number,
): CurrentCycle {
  const { offerId, windowStartMs, windowEndMs } = entitlement;
  if (cycleDays === null) {
    return {
      cycleId: `${offerId}_${windowStartMs}`,
      startMs: windowStartMs,
      endMs: windowEndMs,
    };
  }
  const length = cycleDays * DAY_MS;
  const index = Math.max(0, Math.floor((nowMs - windowStartMs) / length));
  const startMs = windowStartMs + index * length;
  return {
    cycleId: `${offerId}_${windowStartMs}_${index}`,
    startMs,
    endMs: Math.min(startMs + length, windowEndMs),
  };
}

/**
 * Assure que l'agrégat reflète le cycle courant issu de l'entitlement réel.
 * - pas d'entitlement actif → agrégat inchangé (souvent null → unavailable) ;
 * - plan non configuré → agrégat inchangé (jamais d'allocation inventée) ;
 * - même cycle → consommation JAMAIS réinitialisée (allocation ajustée si la
 *   configuration a changé) ;
 * - cycle absent/expiré/offre changée → nouveau cycle transactionnel.
 */
export async function ensureCurrentStudyReserveCycle(
  studentId: string,
  store: StudyReserveProvisioningStore,
  nowMs: number = Date.now(),
): Promise<ReserveAggregate | null> {
  const entitlement = await store.resolveEntitlement(studentId);
  if (!entitlement || !entitlement.active) {
    return store.readAggregate(studentId);
  }
  const config = await store.planConfig(entitlement.offerId);
  if (config === null) {
    return store.readAggregate(studentId);
  }

  const cycle = computeCurrentCycle(entitlement, config.cycleDays, nowMs);
  const existing = await store.readAggregate(studentId);
  if (existing && existing.cycleId === cycle.cycleId && existing.allowanceInternal > 0) {
    if (existing.allowanceInternal !== config.allowanceInternal) {
      return (
        (await store.updateAllowance(studentId, cycle.cycleId, config.allowanceInternal)) ??
        existing
      );
    }
    return existing;
  }

  return store.provisionCycle(studentId, {
    allowanceInternal: config.allowanceInternal,
    consumed: 0,
    cycleId: cycle.cycleId,
    cycleStart: new Date(cycle.startMs).toISOString(),
    cycleEnd: new Date(cycle.endMs).toISOString(),
    latestThresholdEmitted: null,
  });
}

function toMillis(value: unknown): number | null {
  if (value && typeof value === "object" && "toMillis" in value) {
    try {
      const ms = (value as { toMillis: () => number }).toMillis();
      return Number.isFinite(ms) ? ms : null;
    } catch {
      return null;
    }
  }
  if (value instanceof Date) {
    const ms = value.getTime();
    return Number.isFinite(ms) ? ms : null;
  }
  if (typeof value === "number" && Number.isFinite(value)) return value;
  return null;
}

function aggregateFrom(
  data: Record<string, unknown> | undefined,
): ReserveAggregate | null {
  if (!data) return null;
  return {
    allowanceInternal: safeUnits(data.allowanceInternal),
    consumed: safeUnits(data.consumed),
    cycleId: typeof data.cycleId === "string" ? data.cycleId : "",
    cycleStart: typeof data.cycleStart === "string" ? data.cycleStart : null,
    cycleEnd: typeof data.cycleEnd === "string" ? data.cycleEnd : null,
    latestThresholdEmitted: sanitizeThreshold(data.latestThresholdEmitted),
  };
}

export class FirestoreStudyReserveProvisioningStore
  implements StudyReserveProvisioningStore {
  constructor(private readonly now: () => number = () => Date.now()) {}

  async resolveEntitlement(studentId: string): Promise<StudentEntitlement | null> {
    const establishmentId = await this.readEstablishment(studentId);
    if (!establishmentId) return null;

    const links = await db
      .collection("children_links")
      .where("studentId", "==", studentId)
      .where("status", "==", "approved")
      .get();
    const nowMs = this.now();
    let best: StudentEntitlement | null = null;
    for (const link of links.docs) {
      const parentId = link.data()?.parentId;
      if (typeof parentId !== "string" || parentId.length === 0) continue;
      const snap = await db
        .collection("entitlements")
        .doc(`${parentId}_${establishmentId}`)
        .get();
      const parsed = parseEntitlementDocument(snap.data(), establishmentId, nowMs);
      if (!parsed?.active) continue;
      // Plusieurs parents payants : on retient la fenêtre qui court le plus loin.
      if (!best || parsed.windowEndMs > best.windowEndMs) best = parsed;
    }
    return best;
  }

  async planConfig(offerId: string): Promise<StudyReservePlanConfig | null> {
    const snap = await db.collection("study_reserve_plans").doc(offerId).get();
    return parsePlanConfig(snap.data());
  }

  async readAggregate(studentId: string): Promise<ReserveAggregate | null> {
    const snap = await db.collection("study_reserve").doc(studentId).get();
    return aggregateFrom(snap.data());
  }

  async provisionCycle(
    studentId: string,
    fresh: ReserveAggregate,
  ): Promise<ReserveAggregate> {
    const ref = db.collection("study_reserve").doc(studentId);
    return db.runTransaction(async (tx) => {
      const current = aggregateFrom((await tx.get(ref)).data());
      // Course : un autre appel a déjà ouvert ce cycle → ne pas réinitialiser.
      if (current && current.cycleId === fresh.cycleId && current.allowanceInternal > 0) {
        return current;
      }
      // Nouveau cycle : consommation, seuils et holds remis à zéro. Le ledger
      // (sous-collection, clés préfixées par le cycle) est préservé.
      tx.set(
        ref,
        {
          allowanceInternal: fresh.allowanceInternal,
          consumed: 0,
          cycleId: fresh.cycleId,
          cycleStart: fresh.cycleStart,
          cycleEnd: fresh.cycleEnd,
          latestThresholdEmitted: null,
          holds: {},
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      return fresh;
    });
  }

  async updateAllowance(
    studentId: string,
    cycleId: string,
    allowanceInternal: number,
  ): Promise<ReserveAggregate | null> {
    const ref = db.collection("study_reserve").doc(studentId);
    return db.runTransaction(async (tx) => {
      const current = aggregateFrom((await tx.get(ref)).data());
      if (!current || current.cycleId !== cycleId) return current;
      tx.set(
        ref,
        { allowanceInternal, updatedAt: FieldValue.serverTimestamp() },
        { merge: true },
      );
      return { ...current, allowanceInternal };
    });
  }

  private async readEstablishment(studentId: string): Promise<string | null> {
    const [userSnap, profileSnap] = await Promise.all([
      db.collection("users").doc(studentId).get(),
      db.collection("student_profiles").doc(studentId).get(),
    ]);
    const candidates = [
      profileSnap.data()?.establishmentId,
      userSnap.data()?.establishmentId,
    ];
    for (const candidate of candidates) {
      if (typeof candidate === "string" && candidate.trim().length > 0) {
        return candidate.trim();
      }
    }
    return null;
  }
}
