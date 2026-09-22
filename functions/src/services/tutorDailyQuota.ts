import { FieldValue, type DocumentData, type Firestore } from "firebase-admin/firestore";

import { db } from "../config/firebase";
import { AppError } from "../utils/errors";

export const TUTOR_QUOTA_TIME_ZONE = "Africa/Douala";
const RESERVATION_TTL_MS = 5 * 60 * 1_000;

export interface TutorQuotaSnapshot {
  limit: number;
  remaining: number;
  resetsAt: string;
}

/**
 * Réservation d'une question : l'instantané affiché et la journée (Africa/Douala)
 * dans laquelle la place a été prise. La question appartient à cette journée,
 * même si la réponse arrive après minuit.
 */
export type TutorQuotaReservation = TutorQuotaSnapshot & { dayKey?: string };

export interface TutorQuotaStore {
  reserve(params: {
    userId: string;
    traceId: string;
    limit: number;
  }): Promise<TutorQuotaReservation>;
  /**
   * Transforme LA réservation d'origine en question comptée. `dayKey` est
   * celui renvoyé par `reserve` ; absent, la journée courante est utilisée.
   */
  consume(params: {
    userId: string;
    traceId: string;
    limit: number;
    dayKey?: string;
  }): Promise<TutorQuotaSnapshot>;
  release(params: { userId: string; traceId: string; dayKey?: string }): Promise<void>;
}

/**
 * Server-authoritative daily quota. A slot is reserved atomically before the
 * LLM call, consumed only after a successful response, and released on error.
 * Stale reservations expire so a killed function cannot block a student for
 * the rest of the day.
 *
 * The reservation carries its day: consume and release act on the bucket in
 * which the slot was taken, never on a bucket recomputed from the current
 * time (a question reserved at 23:59:59 and answered at 00:00:01 belongs to
 * the first day).
 */
export class FirestoreTutorQuotaStore implements TutorQuotaStore {
  constructor(
    private readonly firestore: Firestore = db,
    private readonly now: () => Date = () => new Date(),
  ) {}

  async reserve(params: {
    userId: string;
    traceId: string;
    limit: number;
  }): Promise<TutorQuotaReservation> {
    const now = this.now();
    const dayKey = tutorQuotaDayKey(now);
    const document = this.quotaDocument(params.userId, dayKey);

    return this.firestore.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(document);
      const data = snapshot.data();
      const usedCount = safeCount(data?.usedCount);
      const reservations = activeReservations(data?.reservations, now);
      const occupied = usedCount + Object.keys(reservations).length;
      const quota = quotaSnapshot(dayKey, params.limit, occupied);

      if (quota.remaining <= 0) {
        throw quotaExceededError(quota);
      }

      reservations[params.traceId] = now.getTime();
      transaction.set(document, {
        userId: params.userId,
        dayKey,
        timeZone: TUTOR_QUOTA_TIME_ZONE,
        limit: params.limit,
        usedCount,
        reservations,
        updatedAt: FieldValue.serverTimestamp(),
        ...(snapshot.exists ? {} : { createdAt: FieldValue.serverTimestamp() }),
      }, { merge: true });

      return { ...quotaSnapshot(dayKey, params.limit, occupied + 1), dayKey };
    });
  }

  async consume(params: {
    userId: string;
    traceId: string;
    limit: number;
    dayKey?: string;
  }): Promise<TutorQuotaSnapshot> {
    const now = this.now();
    const today = tutorQuotaDayKey(now);
    const dayKey = params.dayKey ?? today;
    const document = this.quotaDocument(params.userId, dayKey);
    const todayDocument = this.quotaDocument(params.userId, today);

    return this.firestore.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(document);
      // Lectures avant écritures : la journée affichée est lue ici quand la
      // question appartient à la veille.
      const todaySnapshot = dayKey === today ? snapshot : await transaction.get(todayDocument);
      const data = snapshot.data();
      let usedCount = safeCount(data?.usedCount);
      const reservations = activeReservations(data?.reservations, now);
      if (Object.hasOwn(reservations, params.traceId)) {
        delete reservations[params.traceId];
        usedCount += 1;
      }

      transaction.set(document, {
        userId: params.userId,
        dayKey,
        timeZone: TUTOR_QUOTA_TIME_ZONE,
        limit: params.limit,
        usedCount,
        reservations,
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });

      if (dayKey !== today) {
        // La question compte pour sa journée ; l'élève voit sa journée en cours.
        const todayData = todaySnapshot.data();
        return quotaSnapshot(
          today,
          params.limit,
          safeCount(todayData?.usedCount) +
            Object.keys(activeReservations(todayData?.reservations, now)).length,
        );
      }
      return quotaSnapshot(
        dayKey,
        params.limit,
        usedCount + Object.keys(reservations).length,
      );
    });
  }

  async release(params: { userId: string; traceId: string; dayKey?: string }): Promise<void> {
    const now = this.now();
    const dayKey = params.dayKey ?? tutorQuotaDayKey(now);
    const document = this.quotaDocument(params.userId, dayKey);

    await this.firestore.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(document);
      if (!snapshot.exists) return;
      const reservations = activeReservations(snapshot.data()?.reservations, now);
      if (!Object.hasOwn(reservations, params.traceId)) return;
      delete reservations[params.traceId];
      transaction.update(document, {
        reservations,
        updatedAt: FieldValue.serverTimestamp(),
      });
    });
  }

  private quotaDocument(userId: string, dayKey: string) {
    return this.firestore
      .collection("ai_tutor_daily_usage")
      .doc(`${userId}_${dayKey}`);
  }
}

export function tutorQuotaDayKey(date: Date): string {
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone: TUTOR_QUOTA_TIME_ZONE,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).formatToParts(date);
  const value = (type: Intl.DateTimeFormatPartTypes) =>
    parts.find((part) => part.type === type)?.value ?? "";
  return `${value("year")}-${value("month")}-${value("day")}`;
}

export function nextTutorQuotaReset(dayKey: string): string {
  const [year, month, day] = dayKey.split("-").map(Number);
  // Africa/Douala is UTC+01:00 year-round; local midnight is 23:00 UTC.
  return new Date(Date.UTC(year, month - 1, day + 1, -1)).toISOString();
}

export function activeReservations(value: unknown, now: Date): Record<string, number> {
  if (!value || typeof value !== "object" || Array.isArray(value)) return {};
  const minimum = now.getTime() - RESERVATION_TTL_MS;
  const maximum = now.getTime() + RESERVATION_TTL_MS;
  return Object.fromEntries(
    Object.entries(value as DocumentData)
      .filter(([traceId, timestamp]) =>
        traceId.length > 0 &&
        typeof timestamp === "number" &&
        Number.isFinite(timestamp) &&
        timestamp >= minimum &&
        timestamp <= maximum
      ),
  );
}

function quotaSnapshot(dayKey: string, limit: number, occupied: number): TutorQuotaSnapshot {
  return {
    limit,
    remaining: Math.max(0, limit - occupied),
    resetsAt: nextTutorQuotaReset(dayKey),
  };
}

function quotaExceededError(quota: TutorQuotaSnapshot): AppError {
  return new AppError(
    "resource-exhausted",
    "Tu as atteint la limite de questions du jour. De nouvelles questions seront disponibles à 00 h, heure du Cameroun.",
    quota,
  );
}

function safeCount(value: unknown): number {
  return typeof value === "number" && Number.isInteger(value) && value >= 0
    ? value
    : 0;
}
