import { FieldValue } from "firebase-admin/firestore";
import { HttpsError, type CallableRequest } from "firebase-functions/v2/https";

import { db } from "../config/firebase";

/**
 * Réserve d'étude — comptabilité d'usage **autoritaire côté serveur**, par élève
 * et par cycle de facturation.
 *
 * Le backend mesure l'usage réel du modèle en interne (entrée/sortie/facturable),
 * mais le client ne reçoit qu'un agrégat **product-safe** : pourcentage restant,
 * statut, date de renouvellement. Aucun terme technique (token, XP, crédit IA)
 * n'est exposé — le produit parle de « Réserve d'étude » / « Study reserve ».
 *
 * Chaque enfant a une réserve indépendante (aucun quota partagé au foyer).
 */

/** Seuils d'alerte, du plus haut au plus bas (une seule émission par cycle). */
export const RESERVE_THRESHOLDS = [75, 50, 25, 5, 0] as const;
export type ReserveThreshold = (typeof RESERVE_THRESHOLDS)[number];

export type ReserveStatus =
  | "healthy"
  | "warning"
  | "low"
  | "critical"
  | "depleted"
  | "unavailable"; // aucun plan/réserve valide : jamais inventer 100 %

/** Agrégat product-safe renvoyé au client. Jamais de comptes bruts de modèle. */
export interface StudyReserveView {
  studentId: string;
  percentRemaining: number; // 0..100, entier
  status: ReserveStatus;
  cycleStart: string | null; // ISO
  cycleEnd: string | null; // ISO (date de renouvellement)
  latestThresholdEmitted: ReserveThreshold | null;
}

/** Pourcentage restant (entier 0..100) à partir de l'allocation et du consommé. */
export function remainingPercent(allowance: number, consumed: number): number {
  if (allowance <= 0) return 0;
  const remaining = Math.max(0, allowance - consumed);
  return Math.max(0, Math.min(100, Math.round((remaining / allowance) * 100)));
}

/** Statut produit dérivé du pourcentage restant. */
export function statusForPercent(percent: number): ReserveStatus {
  if (percent <= 0) return "depleted";
  if (percent <= 5) return "critical";
  if (percent <= 25) return "low";
  if (percent <= 50) return "warning";
  return "healthy";
}

/**
 * Seuil franchi entre deux pourcentages (baisse), non encore émis ce cycle.
 * Retourne le seuil le plus bas nouvellement atteint, ou null.
 */
export function crossedThreshold(
  previousPercent: number,
  newPercent: number,
  lastEmitted: ReserveThreshold | null,
): ReserveThreshold | null {
  let crossed: ReserveThreshold | null = null;
  for (const threshold of RESERVE_THRESHOLDS) {
    const isNewlyReached =
      newPercent <= threshold &&
      previousPercent > threshold &&
      (lastEmitted === null || threshold < lastEmitted);
    if (isNewlyReached) crossed = threshold; // le plus bas gagne (dernier de la liste)
  }
  return crossed;
}

export interface UsageRecord {
  studentId: string;
  cycleId: string;
  requestId: string; // clé d'idempotence
  provider: string;
  model: string;
  inputUnits: number;
  outputUnits: number;
  billableUnits: number;
}

export interface ReserveAggregate {
  allowanceInternal: number;
  consumed: number;
  cycleId: string;
  cycleStart: string | null;
  cycleEnd: string | null;
  latestThresholdEmitted: ReserveThreshold | null;
}

export interface RecordResult {
  aggregate: ReserveAggregate;
  /** Seuil franchi lors de CET enregistrement (pour émettre une alerte unique). */
  thresholdEvent: ReserveThreshold | null;
  /** Vrai si la requête était un doublon (idempotence) — aucun débit appliqué. */
  duplicate: boolean;
}

export interface StudyReserveStore {
  /** Comptabilise un usage réel, de façon idempotente sur requestId. */
  recordUsage(record: UsageRecord): Promise<RecordResult>;
  /** Agrégat courant (interne). */
  getAggregate(studentId: string): Promise<ReserveAggregate | null>;
  /** Rôle du compte appelant. */
  readRole(uid: string): Promise<string | undefined>;
  /** Vrai si [parentId] est lié à [studentId] par un lien approuvé. */
  isLinkedChild(parentId: string, studentId: string): Promise<boolean>;
}

function toView(studentId: string, aggregate: ReserveAggregate | null): StudyReserveView {
  // Aucun plan/réserve configuré : état sûr « unavailable », jamais 100 % inventé.
  if (!aggregate || aggregate.allowanceInternal <= 0) {
    return {
      studentId,
      percentRemaining: 0,
      status: "unavailable",
      cycleStart: aggregate?.cycleStart ?? null,
      cycleEnd: aggregate?.cycleEnd ?? null,
      latestThresholdEmitted: aggregate?.latestThresholdEmitted ?? null,
    };
  }
  const percent = remainingPercent(aggregate.allowanceInternal, aggregate.consumed);
  return {
    studentId,
    percentRemaining: percent,
    status: statusForPercent(percent),
    cycleStart: aggregate.cycleStart,
    cycleEnd: aggregate.cycleEnd,
    latestThresholdEmitted: aggregate.latestThresholdEmitted,
  };
}

export class FirestoreStudyReserveStore implements StudyReserveStore {
  async readRole(uid: string): Promise<string | undefined> {
    const snapshot = await db.collection("users").doc(uid).get();
    const role = snapshot.data()?.role;
    return typeof role === "string" ? role : undefined;
  }

  async isLinkedChild(parentId: string, studentId: string): Promise<boolean> {
    const snapshot = await db
      .collection("children_links")
      .doc(`${parentId}_${studentId}`)
      .get();
    return snapshot.exists && snapshot.data()?.status === "approved";
  }

  async getAggregate(studentId: string): Promise<ReserveAggregate | null> {
    const snapshot = await db.collection("study_reserve").doc(studentId).get();
    const data = snapshot.data();
    if (!data) return null;
    return {
      allowanceInternal: Number(data.allowanceInternal ?? 0),
      consumed: Number(data.consumed ?? 0),
      cycleId: String(data.cycleId ?? ""),
      cycleStart: (data.cycleStart as string | undefined) ?? null,
      cycleEnd: (data.cycleEnd as string | undefined) ?? null,
      latestThresholdEmitted: (data.latestThresholdEmitted ?? null) as ReserveThreshold | null,
    };
  }

  async recordUsage(record: UsageRecord): Promise<RecordResult> {
    const aggregateRef = db.collection("study_reserve").doc(record.studentId);
    const ledgerRef = aggregateRef
      .collection("ledger")
      .doc(`${record.cycleId}__${record.requestId}`);

    return db.runTransaction(async (tx) => {
      const [aggregateSnap, ledgerSnap] = await Promise.all([
        tx.get(aggregateRef),
        tx.get(ledgerRef),
      ]);
      const data = aggregateSnap.data();
      const aggregate: ReserveAggregate = {
        allowanceInternal: Number(data?.allowanceInternal ?? 0),
        consumed: Number(data?.consumed ?? 0),
        cycleId: String(data?.cycleId ?? record.cycleId),
        cycleStart: (data?.cycleStart as string | undefined) ?? null,
        cycleEnd: (data?.cycleEnd as string | undefined) ?? null,
        latestThresholdEmitted:
          (data?.latestThresholdEmitted ?? null) as ReserveThreshold | null,
      };

      // Idempotence : une requestId déjà comptabilisée n'est jamais rejouée.
      if (ledgerSnap.exists) {
        return { aggregate, thresholdEvent: null, duplicate: true };
      }

      const previousPercent = remainingPercent(
        aggregate.allowanceInternal,
        aggregate.consumed,
      );
      const consumed = aggregate.consumed + Math.max(0, record.billableUnits);
      const newPercent = remainingPercent(aggregate.allowanceInternal, consumed);
      const event = crossedThreshold(
        previousPercent,
        newPercent,
        aggregate.latestThresholdEmitted,
      );

      tx.set(ledgerRef, {
        studentId: record.studentId,
        cycleId: record.cycleId,
        requestId: record.requestId,
        provider: record.provider,
        model: record.model,
        inputUnits: record.inputUnits,
        outputUnits: record.outputUnits,
        billableUnits: record.billableUnits,
        createdAt: FieldValue.serverTimestamp(),
      });
      tx.set(
        aggregateRef,
        {
          consumed,
          cycleId: record.cycleId,
          ...(event !== null ? { latestThresholdEmitted: event } : {}),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

      return {
        aggregate: {
          ...aggregate,
          consumed,
          latestThresholdEmitted: event ?? aggregate.latestThresholdEmitted,
        },
        thresholdEvent: event,
        duplicate: false,
      };
    });
  }
}

/** Callable : lit la réserve product-safe d'un élève (soi-même) ou d'un enfant
 * lié (parent). Jamais d'accès à un élève non lié. */
export function createGetStudyReserveHandler(
  store: StudyReserveStore = new FirestoreStudyReserveStore(),
) {
  return async (
    request: CallableRequest<{ studentId?: unknown }>,
  ): Promise<StudyReserveView> => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Firebase Auth is required.");
    }
    const requested =
      typeof request.data?.studentId === "string" && request.data.studentId
        ? request.data.studentId
        : uid;

    if (requested !== uid) {
      // Un tiers ne lit une réserve que s'il est un PARENT lié à cet enfant.
      const role = await store.readRole(uid);
      const allowed =
        role === "parent" && (await store.isLinkedChild(uid, requested));
      if (!allowed) {
        throw new HttpsError(
          "permission-denied",
          "You can only view your own study reserve or a linked child's.",
        );
      }
    }
    return toView(requested, await store.getAggregate(requested));
  };
}

export const getStudyReserveHandler = createGetStudyReserveHandler();
