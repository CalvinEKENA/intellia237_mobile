import type { CallableRequest } from "firebase-functions/v2/https";
import { HttpsError } from "firebase-functions/v2/https";
import type { DocumentData } from "firebase-admin/firestore";

import { db } from "../config/firebase";

const HISTORY_LIMIT = 20;

export interface QuizAttemptHistoryStore {
  listRecent(studentId: string, limit: number): Promise<DocumentData[]>;
}

export class FirestoreQuizAttemptHistoryStore
  implements QuizAttemptHistoryStore
{
  async listRecent(studentId: string, limit: number): Promise<DocumentData[]> {
    const attempts = await db
      .collection("quiz_attempts")
      .where("studentId", "==", studentId)
      .orderBy("createdAt", "desc")
      .limit(limit)
      .get();

    const quizIds = Array.from(
      new Set(
        attempts.docs
          .map((document) => normalizedString(document.data().quizId))
          .filter((quizId): quizId is string => quizId !== null),
      ),
    );
    const quizSnapshots = quizIds.length > 0
      ? await db.getAll(
          ...quizIds.map((quizId) => db.collection("quizzes").doc(quizId)),
        )
      : [];
    const modeByQuizId = new Map(
      quizSnapshots.map((snapshot) => [
        snapshot.id,
        publicMode(snapshot.data()?.mode),
      ]),
    );

    return attempts.docs.map((document) => {
      const data = document.data();
      const quizId = normalizedString(data.quizId);
      return {
        ...data,
        mode: quizId === null ? null : modeByQuizId.get(quizId) ?? null,
      };
    });
  }
}

export interface PublicQuizAttemptSummary {
  quizTitle: string;
  subjectLabel: string;
  score: number;
  maxScore: number;
  pointsAwarded: number;
  submittedAt: string | null;
  mode: "training" | "exam" | null;
}

export function toPublicQuizAttemptSummary(
  data: DocumentData,
): PublicQuizAttemptSummary {
  return {
    quizTitle: safeLabel(data.quizTitle, "Quiz"),
    subjectLabel: safeLabel(data.subjectLabel, "Matière non précisée"),
    score: nonNegativeInteger(data.score),
    maxScore: nonNegativeInteger(data.maxScore),
    pointsAwarded: nonNegativeInteger(data.pointsAwarded ?? data.xpAwarded),
    submittedAt: isoDate(data.createdAt),
    mode: publicMode(data.mode),
  };
}

export function createListQuizAttemptHistoryHandler(
  store: QuizAttemptHistoryStore = new FirestoreQuizAttemptHistoryStore(),
) {
  return async (request: CallableRequest<unknown>) => {
    const studentId = request.auth?.uid;
    if (!studentId) {
      throw new HttpsError("unauthenticated", "Firebase Auth is required.");
    }

    const records = await store.listRecent(studentId, HISTORY_LIMIT);
    return {
      attempts: records
        .slice(0, HISTORY_LIMIT)
        .map(toPublicQuizAttemptSummary),
    };
  };
}

function normalizedString(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const normalized = value.trim();
  return normalized.length > 0 ? normalized : null;
}

function safeLabel(value: unknown, fallback: string): string {
  return normalizedString(value)?.slice(0, 160) ?? fallback;
}

function nonNegativeInteger(value: unknown): number {
  const number = typeof value === "number" ? value : Number(value);
  if (!Number.isFinite(number)) return 0;
  return Math.max(0, Math.trunc(number));
}

function publicMode(value: unknown): "training" | "exam" | null {
  if (value === "training") return "training";
  if (value === "exam") return "exam";
  return null;
}

function isoDate(value: unknown): string | null {
  if (
    typeof value === "object" &&
    value !== null &&
    "toDate" in value &&
    typeof value.toDate === "function"
  ) {
    const date = value.toDate();
    return date instanceof Date && Number.isFinite(date.getTime())
      ? date.toISOString()
      : null;
  }
  if (value instanceof Date && Number.isFinite(value.getTime())) {
    return value.toISOString();
  }
  if (typeof value === "string") {
    const timestamp = Date.parse(value);
    return Number.isFinite(timestamp) ? new Date(timestamp).toISOString() : null;
  }
  return null;
}

export const listQuizAttemptHistoryHandler =
  createListQuizAttemptHistoryHandler();
