import { createHash } from "node:crypto";

import {
  type DocumentData,
  FieldValue,
  type Firestore,
  type Transaction
} from "firebase-admin/firestore";

import { db } from "../config/firebase";
import { AppError } from "../utils/errors";
import { scoreQuizAttempt } from "./quizScoring";
import {
  quizDocumentSchema,
  type QuizRecord,
  type QuizSubmissionResult,
  type StoredQuizAttempt
} from "./quizTypes";

const STREAK_TIMEZONE = "Africa/Douala";

export interface SubmitQuizAttemptCommand {
  studentId: string;
  quizId: string;
  clientAttemptId: string;
  answersByQuestion: Record<string, string>;
  requestHash: string;
  startedAt?: string;
  durationSeconds?: number;
}

export interface LessonProgressCommand {
  studentId: string;
  classLevel: string;
  subjectId: string;
  chapterId: string;
  lessonId: string;
  progress: number;
  clientEventId: string;
  requestHash: string;
}

export interface LessonProgressResult {
  progressId: string;
  progress: number;
  previousProgress: number;
  isCompleted: boolean;
  updatedAt: string;
  idempotentReplay: boolean;
}

export interface AcademicStateStore {
  submitQuizAttempt(command: SubmitQuizAttemptCommand): Promise<QuizSubmissionResult>;
  recordLessonProgress(command: LessonProgressCommand): Promise<LessonProgressResult>;
}

export class FirestoreAcademicStateStore implements AcademicStateStore {
  constructor(private readonly firestore: Firestore = db) {}

  async submitQuizAttempt(command: SubmitQuizAttemptCommand): Promise<QuizSubmissionResult> {
    const attemptId = attemptDocumentId(command.studentId, command.clientAttemptId);
    const now = new Date();
    const submittedAt = now.toISOString();

    return this.firestore.runTransaction(async (transaction) => {
      const attemptRef = this.firestore.collection("quiz_attempts").doc(attemptId);
      const existingAttempt = await transaction.get(attemptRef);
      if (existingAttempt.exists) {
        const stored = parseStoredQuizAttempt(existingAttempt.data(), command.requestHash);
        return {
          ...stored.result,
          idempotentReplay: true
        };
      }

      const quizRef = this.firestore.collection("quizzes").doc(command.quizId);
      const quizSnapshot = await transaction.get(quizRef);
      if (!quizSnapshot.exists) {
        throw new AppError("not-found", "Quiz not found.");
      }

      const quiz: QuizRecord = {
        id: quizSnapshot.id,
        ...quizDocumentSchema.parse(quizSnapshot.data())
      };
      if (quiz.status !== "published") {
        throw new AppError("failed-precondition", "Only published quizzes can be submitted.");
      }

      let result: QuizSubmissionResult;
      try {
        result = scoreQuizAttempt({
          quiz,
          attemptId,
          answersByQuestion: command.answersByQuestion,
          submittedAt
        });
      } catch (error) {
        throw new AppError(
          "invalid-argument",
          error instanceof Error ? error.message : "Invalid quiz answers."
        );
      }

      transaction.set(attemptRef, {
        attemptId,
        studentId: command.studentId,
        quizId: command.quizId,
        quizTitle: quiz.title,
        subjectId: quiz.subjectId,
        subjectLabel: quiz.subjectLabel,
        clientAttemptId: command.clientAttemptId,
        requestHash: command.requestHash,
        answersByQuestion: command.answersByQuestion,
        score: result.score,
        maxScore: result.maxScore,
        xpAwarded: result.xpAwarded,
        corrections: result.corrections,
        startedAtClient: command.startedAt ?? null,
        durationSeconds: command.durationSeconds ?? null,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp()
      });

      this.writeQuizRewards(transaction, command.studentId, result, now);
      await this.writeStreak(transaction, command.studentId, now);

      return result;
    });
  }

  async recordLessonProgress(command: LessonProgressCommand): Promise<LessonProgressResult> {
    const progressId = lessonProgressId(command.subjectId, command.chapterId, command.lessonId);
    const eventId = attemptDocumentId(command.studentId, command.clientEventId);
    const now = new Date();
    const updatedAt = now.toISOString();

    return this.firestore.runTransaction(async (transaction) => {
      const eventRef = this.firestore
        .collection("student_profiles")
        .doc(command.studentId)
        .collection("lessonProgressEvents")
        .doc(eventId);
      const eventSnapshot = await transaction.get(eventRef);
      if (eventSnapshot.exists) {
        const data = eventSnapshot.data();
        if (data?.requestHash !== command.requestHash) {
          throw new AppError("already-exists", "Client event id was already used with a different payload.");
        }

        return {
          progressId,
          progress: Number(data.result?.progress ?? command.progress),
          previousProgress: Number(data.result?.previousProgress ?? 0),
          isCompleted: Boolean(data.result?.isCompleted ?? command.progress >= 1),
          updatedAt: String(data.result?.updatedAt ?? updatedAt),
          idempotentReplay: true
        };
      }

      const progressRef = this.firestore
        .collection("student_profiles")
        .doc(command.studentId)
        .collection("lessonProgress")
        .doc(progressId);
      const progressSnapshot = await transaction.get(progressRef);
      const previousProgress = clampProgress(Number(progressSnapshot.data()?.progress ?? 0));
      const nextProgress = Math.max(previousProgress, clampProgress(command.progress));
      const result: LessonProgressResult = {
        progressId,
        progress: nextProgress,
        previousProgress,
        isCompleted: nextProgress >= 1,
        updatedAt,
        idempotentReplay: false
      };

      transaction.set(progressRef, {
        classLevel: command.classLevel,
        subjectId: command.subjectId,
        chapterId: command.chapterId,
        lessonId: command.lessonId,
        progress: nextProgress,
        isCompleted: result.isCompleted,
        completedAt: result.isCompleted ? FieldValue.serverTimestamp() : null,
        updatedAt: FieldValue.serverTimestamp()
      }, { merge: true });

      const summaryRef = this.firestore.collection("progress").doc(`${command.studentId}_${progressId}`);
      transaction.set(summaryRef, {
        studentId: command.studentId,
        type: "lesson",
        classLevel: command.classLevel,
        subjectId: command.subjectId,
        chapterId: command.chapterId,
        lessonId: command.lessonId,
        progress: nextProgress,
        updatedAt: FieldValue.serverTimestamp()
      }, { merge: true });

      transaction.set(eventRef, {
        studentId: command.studentId,
        clientEventId: command.clientEventId,
        requestHash: command.requestHash,
        result,
        createdAt: FieldValue.serverTimestamp()
      });

      if (nextProgress > previousProgress) {
        await this.writeStreak(transaction, command.studentId, now);
      }

      return result;
    });
  }

  private writeQuizRewards(
    transaction: Transaction,
    studentId: string,
    result: QuizSubmissionResult,
    now: Date
  ): void {
    const userRef = this.firestore.collection("users").doc(studentId);
    transaction.set(userRef, {
      xp: FieldValue.increment(result.xpAwarded),
      updatedAt: FieldValue.serverTimestamp()
    }, { merge: true });

    const profileRef = this.firestore.collection("student_profiles").doc(studentId);
    transaction.set(profileRef, {
      xp: FieldValue.increment(result.xpAwarded),
      totalScore: FieldValue.increment(result.score),
      totalQuizAttempts: FieldValue.increment(1),
      lastAcademicActivityAt: FieldValue.serverTimestamp(),
      lastAcademicActivityDate: localDateKey(now, STREAK_TIMEZONE),
      updatedAt: FieldValue.serverTimestamp()
    }, { merge: true });

    const progressRef = this.firestore.collection("progress").doc(`${studentId}_${result.quizId}`);
    transaction.set(progressRef, {
      studentId,
      type: "quiz",
      quizId: result.quizId,
      subjectId: result.subjectId,
      score: result.score,
      maxScore: result.maxScore,
      xpAwarded: result.xpAwarded,
      updatedAt: FieldValue.serverTimestamp()
    }, { merge: true });
  }

  private async writeStreak(transaction: Transaction, studentId: string, now: Date): Promise<void> {
    const streakRef = this.firestore.collection("streaks").doc(studentId);
    const streakSnapshot = await transaction.get(streakRef);
    const data = streakSnapshot.data() ?? {};
    const today = localDateKey(now, STREAK_TIMEZONE);
    const yesterday = localDateKey(addDays(now, -1), STREAK_TIMEZONE);
    const lastActivityDate = typeof data.lastActivityDate === "string" ? data.lastActivityDate : null;

    if (lastActivityDate === today) {
      transaction.set(streakRef, {
        updatedAt: FieldValue.serverTimestamp()
      }, { merge: true });
      return;
    }

    const current = Number.isInteger(data.currentStreak) ? Number(data.currentStreak) : 0;
    const longest = Number.isInteger(data.longestStreak) ? Number(data.longestStreak) : 0;
    const nextCurrent = lastActivityDate === yesterday ? current + 1 : 1;
    const nextLongest = Math.max(longest, nextCurrent);

    transaction.set(streakRef, {
      uid: studentId,
      currentStreak: nextCurrent,
      longestStreak: nextLongest,
      lastActivityDate: today,
      timezone: STREAK_TIMEZONE,
      updatedAt: FieldValue.serverTimestamp()
    }, { merge: true });

    transaction.set(this.firestore.collection("student_profiles").doc(studentId), {
      streak: {
        current: nextCurrent,
        best: nextLongest,
        lastStudyDate: today,
        timezone: STREAK_TIMEZONE
      },
      updatedAt: FieldValue.serverTimestamp()
    }, { merge: true });
  }
}

export function buildRequestHash(value: unknown): string {
  return createHash("sha256")
    .update(stableStringify(value))
    .digest("hex");
}

function parseStoredQuizAttempt(
  data: DocumentData | undefined,
  requestHash: string
): StoredQuizAttempt {
  if (data?.requestHash !== requestHash) {
    throw new AppError("already-exists", "Client attempt id was already used with a different payload.");
  }

  return {
    requestHash,
    result: {
      attemptId: String(data.attemptId ?? ""),
      quizId: String(data.quizId ?? ""),
      quizTitle: String(data.quizTitle ?? ""),
      subjectId: String(data.subjectId ?? ""),
      subjectLabel: String(data.subjectLabel ?? ""),
      score: Number(data.score ?? 0),
      maxScore: Number(data.maxScore ?? 0),
      xpAwarded: Number(data.xpAwarded ?? 0),
      corrections: Array.isArray(data.corrections) ? data.corrections : [],
      submittedAt: firestoreTimestampToIso(data.createdAt),
      idempotentReplay: true
    }
  };
}

function attemptDocumentId(studentId: string, clientAttemptId: string): string {
  return `${sanitizeDocumentId(studentId)}_${sanitizeDocumentId(clientAttemptId)}`;
}

function lessonProgressId(subjectId: string, chapterId: string, lessonId: string): string {
  return `${sanitizeDocumentId(subjectId)}_${sanitizeDocumentId(chapterId)}_${sanitizeDocumentId(lessonId)}`;
}

function sanitizeDocumentId(value: string): string {
  return value.replace(/[^A-Za-z0-9_-]/g, "_").slice(0, 160);
}

function stableStringify(value: unknown): string {
  if (Array.isArray(value)) {
    return `[${value.map(stableStringify).join(",")}]`;
  }

  if (value && typeof value === "object") {
    return `{${Object.entries(value as Record<string, unknown>)
      .sort(([left], [right]) => left.localeCompare(right))
      .map(([key, item]) => `${JSON.stringify(key)}:${stableStringify(item)}`)
      .join(",")}}`;
  }

  return JSON.stringify(value);
}

function firestoreTimestampToIso(value: unknown): string {
  if (value && typeof value === "object" && "toDate" in value) {
    const timestamp = value as { toDate?: () => Date };
    if (typeof timestamp.toDate === "function") {
      return timestamp.toDate().toISOString();
    }
  }

  if (value instanceof Date) {
    return value.toISOString();
  }

  return new Date().toISOString();
}

function localDateKey(date: Date, timeZone: string): string {
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit"
  }).formatToParts(date);

  const year = parts.find((part) => part.type === "year")?.value ?? "1970";
  const month = parts.find((part) => part.type === "month")?.value ?? "01";
  const day = parts.find((part) => part.type === "day")?.value ?? "01";
  return `${year}-${month}-${day}`;
}

function addDays(date: Date, days: number): Date {
  const copy = new Date(date);
  copy.setUTCDate(copy.getUTCDate() + days);
  return copy;
}

function clampProgress(value: number): number {
  if (!Number.isFinite(value)) {
    return 0;
  }

  return Math.min(Math.max(value, 0), 1);
}
