import { FieldValue } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";

import { db } from "../config/firebase";
import {
  crossedThreshold,
  remainingPercent,
  type ReserveThreshold,
} from "./studyReserve";

/**
 * Couche de consommation **unique et autoritaire** de la Réserve d'étude.
 *
 * Toute opération facturable (tuteur/IA) passe par ici — aucune logique de
 * comptabilité dupliquée ailleurs. Sémantique réserve / commit / release :
 * on réserve un montant provisoire (sécurité de concurrence), on exécute le
 * fournisseur, puis on comptabilise l'usage **réel** (jamais une estimation
 * permanente si le réel est connu) de façon idempotente, ou on relâche la
 * réservation en cas d'échec. Deux requêtes simultanées ne peuvent pas
 * surconsommer : la réservation est transactionnelle.
 */

/** Durée de vie d'une réservation : une fonction tuée ne bloque pas le cycle. */
export const RESERVE_HOLD_TTL_MS = 5 * 60 * 1000;

/** Estimation provisoire par requête tuteur, remplacée par l'usage réel. */
export const DEFAULT_TUTOR_ESTIMATE_UNITS = 1000;

export interface ProviderUsage {
  inputUnits: number;
  outputUnits: number;
  billableUnits: number;
}

export interface ReserveHold {
  configured: boolean; // false = pas de plan → gouverné par le quota quotidien
  reserved: boolean;
}

export interface CommitResult {
  duplicate: boolean;
  thresholdEvent: ReserveThreshold | null;
  cycleId: string;
}

export interface StudyReserveConsumptionStore {
  reserve(params: {
    studentId: string;
    requestId: string;
    estimateUnits: number;
  }): Promise<ReserveHold>;
  commit(params: {
    studentId: string;
    requestId: string;
    provider: string;
    model: string;
    usage: ProviderUsage;
  }): Promise<CommitResult>;
  release(params: { studentId: string; requestId: string }): Promise<void>;
  listLinkedParents(studentId: string): Promise<string[]>;
}

export interface ThresholdNotifier {
  emit(params: {
    studentId: string;
    parentIds: string[];
    cycleId: string;
    threshold: ReserveThreshold;
  }): Promise<void>;
}

interface HoldEntry {
  units: number;
  tsMs: number;
}

function activeHolds(
  raw: unknown,
  now: number,
): Record<string, HoldEntry> {
  const holds: Record<string, HoldEntry> = {};
  if (raw && typeof raw === "object" && !Array.isArray(raw)) {
    for (const [key, value] of Object.entries(raw as Record<string, unknown>)) {
      if (value && typeof value === "object") {
        const entry = value as { units?: unknown; tsMs?: unknown };
        const tsMs = Number(entry.tsMs ?? 0);
        if (now - tsMs <= RESERVE_HOLD_TTL_MS) {
          holds[key] = { units: Number(entry.units ?? 0), tsMs };
        }
      }
    }
  }
  return holds;
}

function heldUnits(holds: Record<string, HoldEntry>): number {
  return Object.values(holds).reduce((sum, h) => sum + Math.max(0, h.units), 0);
}

export class FirestoreStudyReserveConsumptionStore
  implements StudyReserveConsumptionStore {
  constructor(private readonly now: () => number = () => Date.now()) {}

  private aggregateRef(studentId: string) {
    return db.collection("study_reserve").doc(studentId);
  }

  async reserve(params: {
    studentId: string;
    requestId: string;
    estimateUnits: number;
  }): Promise<ReserveHold> {
    const ref = this.aggregateRef(params.studentId);
    const now = this.now();
    return db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      const data = snap.data();
      const allowance = Number(data?.allowanceInternal ?? 0);
      // Pas de plan → non configuré : on ne bloque pas, on ne débite pas.
      if (!data || allowance <= 0) {
        return { configured: false, reserved: false };
      }
      const consumed = Number(data.consumed ?? 0);
      const holds = activeHolds(data.holds, now);
      const remaining = allowance - consumed - heldUnits(holds);
      if (remaining <= 0) {
        throw new HttpsError(
          "resource-exhausted",
          "Study reserve is empty for this cycle.",
        );
      }
      holds[params.requestId] = { units: params.estimateUnits, tsMs: now };
      tx.set(
        ref,
        { holds, updatedAt: FieldValue.serverTimestamp() },
        { merge: true },
      );
      return { configured: true, reserved: true };
    });
  }

  async commit(params: {
    studentId: string;
    requestId: string;
    provider: string;
    model: string;
    usage: ProviderUsage;
  }): Promise<CommitResult> {
    const ref = this.aggregateRef(params.studentId);
    const now = this.now();
    return db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      const data = snap.data();
      const cycleId = String(data?.cycleId ?? "");
      const ledgerRef = ref.collection("ledger").doc(`${cycleId}__${params.requestId}`);
      const ledgerSnap = await tx.get(ledgerRef);

      const holds = activeHolds(data?.holds, now);
      delete holds[params.requestId]; // la réservation est levée quoi qu'il arrive

      // Idempotence : une requête déjà comptabilisée n'est jamais rejouée.
      if (ledgerSnap.exists) {
        tx.set(ref, { holds }, { merge: true });
        return { duplicate: true, thresholdEvent: null, cycleId };
      }

      const allowance = Number(data?.allowanceInternal ?? 0);
      const consumedBefore = Number(data?.consumed ?? 0);
      const latestEmitted = (data?.latestThresholdEmitted ?? null) as ReserveThreshold | null;
      const previousPercent = remainingPercent(allowance, consumedBefore);
      const consumed = consumedBefore + Math.max(0, params.usage.billableUnits);
      const newPercent = remainingPercent(allowance, consumed);
      const event = crossedThreshold(previousPercent, newPercent, latestEmitted);

      tx.set(ledgerRef, {
        studentId: params.studentId,
        cycleId,
        requestId: params.requestId,
        provider: params.provider,
        model: params.model,
        inputUnits: params.usage.inputUnits,
        outputUnits: params.usage.outputUnits,
        billableUnits: params.usage.billableUnits,
        createdAt: FieldValue.serverTimestamp(),
      });
      tx.set(
        ref,
        {
          consumed,
          holds,
          ...(event !== null ? { latestThresholdEmitted: event } : {}),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      return { duplicate: false, thresholdEvent: event, cycleId };
    });
  }

  async release(params: { studentId: string; requestId: string }): Promise<void> {
    const ref = this.aggregateRef(params.studentId);
    const now = this.now();
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      if (!snap.exists) return;
      const holds = activeHolds(snap.data()?.holds, now);
      delete holds[params.requestId];
      tx.set(ref, { holds }, { merge: true });
    });
  }

  async listLinkedParents(studentId: string): Promise<string[]> {
    const snapshot = await db
      .collection("children_links")
      .where("studentId", "==", studentId)
      .where("status", "==", "approved")
      .get();
    const parents = new Set<string>();
    for (const doc of snapshot.docs) {
      const parentId = doc.data()?.parentId;
      if (typeof parentId === "string" && parentId.length > 0) {
        parents.add(parentId);
      }
    }
    return [...parents];
  }
}

/** Notifie un franchissement de seuil, une seule fois par cycle et par
 * destinataire, via l'architecture de notifications existante. Le message est
 * porté par un **code de type stable** + le seuil ; le client localise (FR/EN).
 */
export class FirestoreThresholdNotifier implements ThresholdNotifier {
  async emit(params: {
    studentId: string;
    parentIds: string[];
    cycleId: string;
    threshold: ReserveThreshold;
  }): Promise<void> {
    const recipients = [params.studentId, ...params.parentIds];
    const batch = db.batch();
    for (const recipient of recipients) {
      const forChild = recipient !== params.studentId;
      const id = `study_reserve_${params.cycleId}_${params.threshold}_${recipient}`;
      batch.set(
        db.collection("notifications").doc(id),
        {
          userId: recipient,
          type: "study_reserve_threshold",
          // Code + données : le client compose le texte FR/EN. Pas de message
          // figé dans une seule langue côté serveur.
          data: {
            threshold: params.threshold,
            studentId: params.studentId,
            audience: forChild ? "parent" : "student",
          },
          title: "",
          body: "",
          route: "/notifications",
          sourceId: `study_reserve_${params.cycleId}_${params.threshold}`,
          createdAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    }
    await batch.commit();
  }
}

/** Orchestrateur : réserve → exécute → commit(usage réel) / release, et émet
 * la notification de seuil (une fois par cycle). */
export class StudyReserveConsumption {
  constructor(
    private readonly store: StudyReserveConsumptionStore = new FirestoreStudyReserveConsumptionStore(),
    private readonly notifier: ThresholdNotifier = new FirestoreThresholdNotifier(),
  ) {}

  async run<T>(
    params: {
      studentId: string;
      requestId: string;
      provider: string;
      model: string;
      estimateUnits?: number;
    },
    exec: () => Promise<{ result: T; usage: ProviderUsage }>,
  ): Promise<{ result: T; thresholdEvent: ReserveThreshold | null }> {
    const hold = await this.store.reserve({
      studentId: params.studentId,
      requestId: params.requestId,
      estimateUnits: params.estimateUnits ?? DEFAULT_TUTOR_ESTIMATE_UNITS,
    });

    // Non configuré : aucune réserve à débiter (le contenu statique et les
    // autres garde-fous — quota quotidien — restent en vigueur).
    if (!hold.configured) {
      const { result } = await exec();
      return { result, thresholdEvent: null };
    }

    let execution: { result: T; usage: ProviderUsage };
    try {
      execution = await exec();
    } catch (error) {
      await this.store
        .release({ studentId: params.studentId, requestId: params.requestId })
        .catch(() => undefined);
      throw error;
    }

    const commit = await this.store.commit({
      studentId: params.studentId,
      requestId: params.requestId,
      provider: params.provider,
      model: params.model,
      usage: execution.usage,
    });

    if (commit.thresholdEvent !== null && !commit.duplicate) {
      const parents = await this.store
        .listLinkedParents(params.studentId)
        .catch(() => [] as string[]);
      await this.notifier
        .emit({
          studentId: params.studentId,
          parentIds: parents,
          cycleId: commit.cycleId,
          threshold: commit.thresholdEvent,
        })
        .catch(() => undefined);
    }

    return { result: execution.result, thresholdEvent: commit.thresholdEvent };
  }
}

/** Unités facturables réelles à partir de l'usage fournisseur. */
export function billableFromUsage(usage: {
  promptTokenCount?: number;
  candidatesTokenCount?: number;
  totalTokenCount?: number;
}): ProviderUsage {
  const input = Math.max(0, usage.promptTokenCount ?? 0);
  const output = Math.max(0, usage.candidatesTokenCount ?? 0);
  const billable =
    usage.totalTokenCount !== undefined
      ? Math.max(0, usage.totalTokenCount)
      : input + output;
  return { inputUnits: input, outputUnits: output, billableUnits: billable };
}
