import { publishedLessonAllows } from "./educationalMedia";
import { audienceAllows, canonicalClass } from "./contentAudience";
import { createHash } from "node:crypto";

import {
  type DocumentData,
  FieldValue,
  type Firestore,
  type Transaction
} from "firebase-admin/firestore";

import { db } from "../config/firebase";
import { AppError } from "../utils/errors";
import { buildScoringQuizRecord } from "./quizAnswerKeys";
import { scoreQuizAttempt } from "./quizScoring";
import { accumulatedPoints } from "./pointsPolicy";
import { quizAudienceAllows } from "./quizContentStore";
import {
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

export interface LessonProgressAggregateRecord {
  subjectId: string;
  progress: number;
  isCompleted?: boolean;
}

export interface LessonProgressEventAggregateRecord {
  progress: number;
  previousProgress: number;
  updatedAt: Date;
}

export interface StudentProgressAggregate {
  globalProgress: number;
  trackedLessons: number;
  completedLessons: number;
  subjectProgress: Record<string, number>;
  strongSubjects: string[];
  weakSubjects: string[];
  weeklyProgress: number[];
  weeklyProgressByDate: Record<string, number>;
  lastProgressActivityAt: Date | null;
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
      const answerKeyRef = this.firestore.collection("quiz_answer_keys").doc(command.quizId);
      const quizSnapshot = await transaction.get(quizRef);
      if (!quizSnapshot.exists) {
        throw new AppError("not-found", "Quiz not found.");
      }
      const answerKeySnapshot = await transaction.get(answerKeyRef);

      const quiz = buildScoringQuizRecord({
        id: quizSnapshot.id,
        quizData: quizSnapshot.data(),
        answerKeyData: answerKeySnapshot.exists ? answerKeySnapshot.data() : undefined
      });
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

      // Lire les deux agrégats avant toute écriture transactionnelle. `points`
      // est désormais canonique ; `xp` reste un fallback pour conserver le
      // cumul des profils existants lors de leur première nouvelle récompense.
      const userRef = this.firestore.collection("users").doc(command.studentId);
      const profileRef = this.firestore.collection("student_profiles").doc(command.studentId);
      const streakRef = this.firestore.collection("streaks").doc(command.studentId);
      const userSnapshot = await transaction.get(userRef);
      const profileSnapshot = await transaction.get(profileRef);
      const streakSnapshot = await transaction.get(streakRef);

      if (!quizAudienceAllows(quizSnapshot.data()!, userSnapshot.data() || {}, profileSnapshot.data() || {})) {
        throw new AppError("permission-denied", "Quiz unavailable for this student.");
      }

      const sourceLessonPath = quizSnapshot.data()?.sourceLessonPath;
      if (sourceLessonPath && !await publishedLessonAllows(this.firestore, sourceLessonPath, userSnapshot.data() || {}, profileSnapshot.data() || {}, ref => transaction.get(ref))) {
        throw new AppError("permission-denied", "Source lesson unavailable for this student.");
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
        pointsAwarded: result.pointsAwarded,
        corrections: result.corrections,
        startedAtClient: command.startedAt ?? null,
        durationSeconds: command.durationSeconds ?? null,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp()
      });

      this.writeQuizRewards(
        transaction,
        command.studentId,
        result,
        now,
        userSnapshot.data(),
        profileSnapshot.data()
      );
      this.writeStreak(transaction, command.studentId, now, streakSnapshot.data());

      return result;
    });
  }

  async recordLessonProgress(command: LessonProgressCommand): Promise<LessonProgressResult> {
    const progressId = lessonProgressId(command.subjectId, command.chapterId, command.lessonId);
    const eventId = attemptDocumentId(command.studentId, command.clientEventId);
    const now = new Date();
    const updatedAt = now.toISOString();

    const result = await this.firestore.runTransaction(async (transaction) => {
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
      const userRef = this.firestore.collection("users").doc(command.studentId);
      const sourceClass = command.subjectId.includes("~") ? command.subjectId.split("~")[0] : command.classLevel;
      const sourceSubject = command.subjectId.includes("~") ? command.subjectId.substring(command.subjectId.indexOf("~") + 1) : command.subjectId;
      const lessonRef = this.firestore
        .collection("classes")
        .doc(sourceClass)
        .collection("subjects")
        .doc(sourceSubject)
        .collection("chapters")
        .doc(command.chapterId)
        .collection("lessons")
        .doc(command.lessonId);
      const streakRef = this.firestore.collection("streaks").doc(command.studentId);
      const [progressSnapshot, userSnapshot, lessonSnapshot, streakSnapshot, profileSnapshot, chapterSnapshot, subjectSnapshot] =
        await Promise.all([
          transaction.get(progressRef),
          transaction.get(userRef),
          transaction.get(lessonRef),
          transaction.get(streakRef),
          transaction.get(this.firestore.doc(`student_profiles/${command.studentId}`)),
          transaction.get(lessonRef.parent.parent!),
          transaction.get(lessonRef.parent.parent!.parent.parent!)
        ]);
      assertLessonProgressAuthorized({
        command,
        userData: userSnapshot.exists ? userSnapshot.data() : undefined,
        lessonData: lessonSnapshot.exists ? lessonSnapshot.data() : undefined,
        profileData: profileSnapshot.data(),
      });
      if (!chapterSnapshot.exists || !subjectSnapshot.exists || subjectSnapshot.data()!.status !== "published" ||
        ![chapterSnapshot, subjectSnapshot].every(d => !d.data()!.deleting && audienceAllows(
          d === chapterSnapshot && d.data()!.audience === undefined && subjectSnapshot.data()?.audience
            ? { ...d.data(), audience: subjectSnapshot.data()!.audience } : d.data()!,
          userSnapshot.data()!, profileSnapshot.data(), sourceClass))) {
        throw new AppError("permission-denied", "Lesson parent audience does not match the student.");
      }
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

      if (nextProgress > previousProgress) {
        const wasCompleted = Boolean(progressSnapshot.data()?.isCompleted) || previousProgress >= 1;
        const progressDocument: Record<string, unknown> = {
          classLevel: command.classLevel,
          subjectId: command.subjectId,
          chapterId: command.chapterId,
          lessonId: command.lessonId,
          authorizationVersion: 1,
          contentScope: normalizedString(lessonSnapshot.data()?.establishmentId)
            ? "establishment"
            : "global",
          establishmentId: normalizedString(lessonSnapshot.data()?.establishmentId) || null,
          progress: nextProgress,
          isCompleted: result.isCompleted,
          updatedAt: FieldValue.serverTimestamp()
        };
        if (result.isCompleted && !wasCompleted) {
          progressDocument.completedAt = FieldValue.serverTimestamp();
        } else if (!progressSnapshot.exists) {
          progressDocument.completedAt = null;
        }
        transaction.set(progressRef, progressDocument, { merge: true });

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
      }

      transaction.set(eventRef, {
        studentId: command.studentId,
        clientEventId: command.clientEventId,
        requestHash: command.requestHash,
        result,
        createdAt: FieldValue.serverTimestamp()
      });

      if (nextProgress > previousProgress) {
        this.writeStreak(transaction, command.studentId, now, streakSnapshot.data());
      }

      return result;
    });
    // Rebuild on a replay too: if the first invocation committed the event but
    // failed during the derived-state write, retrying repairs the aggregate.
    // The rebuild uses the original event timestamps, so this remains
    // idempotent and never fabricates a new learning activity.
    if (result.progress > result.previousProgress) {
      await this.rebuildStudentProgressAggregates(command.studentId);
    }
    return result;
  }

  private async rebuildStudentProgressAggregates(studentId: string): Promise<void> {
    const now = new Date();
    const profileRef = this.firestore.collection("student_profiles").doc(studentId);
    const userRef = this.firestore.collection("users").doc(studentId);
    const weekStart = addDays(now, -7);
    const [progressSnapshot, eventSnapshot, profileSnapshot, userSnapshot] = await Promise.all([
      profileRef.collection("lessonProgress").get(),
      profileRef
        .collection("lessonProgressEvents")
        .where("createdAt", ">=", weekStart)
        .get(),
      profileRef.get(),
      userRef.get()
    ]);
    if (progressSnapshot.empty) {
      return;
    }

    const aggregate = buildStudentProgressAggregate({
      lessons: progressSnapshot.docs.map((document) => {
        const data = document.data();
        return {
          subjectId: normalizedString(data.subjectId),
          progress: Number(data.progress ?? 0),
          isCompleted: Boolean(data.isCompleted)
        };
      }),
      events: eventSnapshot.docs.flatMap((document) => {
        const result = document.data().result;
        if (!result || typeof result !== "object") {
          return [];
        }
        const resultData = result as Record<string, unknown>;
        const eventDate = timestampDate(resultData.updatedAt) ?? timestampDate(document.data().createdAt);
        if (!eventDate) {
          return [];
        }
        return [{
          progress: Number(resultData.progress ?? 0),
          previousProgress: Number(resultData.previousProgress ?? 0),
          updatedAt: eventDate
        }];
      }),
      now
    });
    const existingProfileActivity = timestampDate(profileSnapshot.data()?.lastAcademicActivityAt);
    const existingUserActivity = timestampDate(userSnapshot.data()?.lastActivityAt);
    const lastAcademicActivityAt = latestDate(
      existingProfileActivity,
      aggregate.lastProgressActivityAt
    );
    const lastUserActivityAt = latestDate(existingUserActivity, lastAcademicActivityAt);

    const profileUpdate: Record<string, unknown> = {
        progress: {
          globalProgress: aggregate.globalProgress,
          trackedLessons: aggregate.trackedLessons,
          completedLessons: aggregate.completedLessons
        },
        subjectProgress: aggregate.subjectProgress,
        strongSubjects: aggregate.strongSubjects,
        weakSubjects: aggregate.weakSubjects,
        weeklyProgress: aggregate.weeklyProgress,
        weeklyProgressByDate: aggregate.weeklyProgressByDate,
        updatedAt: FieldValue.serverTimestamp()
    };
    if (lastAcademicActivityAt) {
      profileUpdate.lastAcademicActivityAt = lastAcademicActivityAt;
      profileUpdate.lastAcademicActivityDate = localDateKey(
        lastAcademicActivityAt,
        STREAK_TIMEZONE
      );
    }
    const userUpdate: Record<string, unknown> = {
        updatedAt: FieldValue.serverTimestamp()
    };
    if (lastUserActivityAt) {
      userUpdate.lastActivityAt = lastUserActivityAt;
    }

    await Promise.all([
      profileRef.set(profileUpdate, { merge: true }),
      userRef.set(userUpdate, { merge: true })
    ]);
  }

  private writeQuizRewards(
    transaction: Transaction,
    studentId: string,
    result: QuizSubmissionResult,
    now: Date,
    userData: DocumentData | undefined,
    profileData: DocumentData | undefined
  ): void {
    const userRef = this.firestore.collection("users").doc(studentId);
    transaction.set(userRef, {
      points: accumulatedPoints(userData) + result.pointsAwarded,
      lastActivityAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp()
    }, { merge: true });

    const profileRef = this.firestore.collection("student_profiles").doc(studentId);
    transaction.set(profileRef, {
      points: accumulatedPoints(profileData) + result.pointsAwarded,
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
      pointsAwarded: result.pointsAwarded,
      updatedAt: FieldValue.serverTimestamp()
    }, { merge: true });
  }

  private writeStreak(
    transaction: Transaction,
    studentId: string,
    now: Date,
    streakData: DocumentData | undefined
  ): void {
    const streakRef = this.firestore.collection("streaks").doc(studentId);
    const data = streakData ?? {};
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

export function assertLessonProgressAuthorized({
  command,
  userData,
  lessonData,
  profileData = {}
}: {
  command: Pick<
    LessonProgressCommand,
    "classLevel" | "subjectId" | "chapterId" | "lessonId"
  >;
  userData: DocumentData | undefined;
  lessonData: DocumentData | undefined;
  profileData?: DocumentData;
}): void {
  if (!userData || normalizedString(userData.role) !== "student") {
    throw new AppError("permission-denied", "A student account is required.");
  }
  const accountStatus = normalizedString(userData.accountStatus);
  if (accountStatus && accountStatus !== "active") {
    throw new AppError("permission-denied", "The student account is not active.");
  }
  if (!lessonData || normalizedString(lessonData.status) !== "published") {
    throw new AppError("not-found", "Published lesson was not found.");
  }
  if (!audienceAllows(lessonData, userData, profileData, command.classLevel)) {
    throw new AppError("permission-denied", "Lesson audience does not match the student profile.");
  }
  const sourceClass = command.subjectId.includes("~") ? command.subjectId.split("~")[0] : command.classLevel;
  if (lessonData.classLevel && canonicalClass(lessonData.classLevel) !== canonicalClass(sourceClass)) {
    throw new AppError("permission-denied", "Lesson path and class metadata are inconsistent.");
  }
  for (const [field, expected] of [
    ["subjectId", command.subjectId.includes("~") ? command.subjectId.substring(command.subjectId.indexOf("~") + 1) : command.subjectId],
    ["chapterId", command.chapterId],
    ["lessonId", command.lessonId]
  ] as const) {
    const stored = normalizedString(lessonData[field]);
    if (stored && stored !== expected) {
      throw new AppError("failed-precondition", "Lesson catalog metadata is inconsistent.");
    }
  }

  const lessonEstablishment = normalizedString(lessonData.scope?.type === "establishment"
    ? lessonData.scope.establishmentId : lessonData.establishmentId);
  const studentEstablishment = normalizedString(userData.establishmentId);
  if (
    (lessonEstablishment && lessonEstablishment !== studentEstablishment) ||
    (!lessonEstablishment && normalizedString(lessonData.visibilityScope) === "establishment")
  ) {
    throw new AppError("permission-denied", "Lesson belongs to another establishment.");
  }
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
      pointsAwarded: Number(data.pointsAwarded ?? data.xpAwarded ?? 0),
      corrections: normalizeStoredCorrections(data.corrections),
      submittedAt: firestoreTimestampToIso(data.createdAt),
      idempotentReplay: true
    }
  };
}

export function buildStudentProgressAggregate({
  lessons,
  events,
  now,
  timeZone = STREAK_TIMEZONE
}: {
  lessons: LessonProgressAggregateRecord[];
  events: LessonProgressEventAggregateRecord[];
  now: Date;
  timeZone?: string;
}): StudentProgressAggregate {
  const subjects = new Map<string, { total: number; count: number }>();
  let totalProgress = 0;
  let completedLessons = 0;

  for (const lesson of lessons) {
    const progress = clampProgress(lesson.progress);
    totalProgress += progress;
    if (lesson.isCompleted || progress >= 1) {
      completedLessons += 1;
    }
    const subjectId = lesson.subjectId.trim();
    if (!subjectId) {
      continue;
    }
    const current = subjects.get(subjectId) ?? { total: 0, count: 0 };
    subjects.set(subjectId, {
      total: current.total + progress,
      count: current.count + 1
    });
  }

  const trackedLessons = lessons.length;
  const subjectProgress: Record<string, number> = Object.fromEntries(
    [...subjects.entries()].map(([subjectId, value]) => [
      subjectId,
      value.count === 0 ? 0 : value.total / value.count
    ])
  );
  const rankedSubjects = Object.entries(subjectProgress)
    .sort((left, right) => right[1] - left[1]);
  const dailyProgressDeltas = Array<number>(7).fill(0);
  const weeklyProgressByDate: Record<string, number> = {};
  const today = localDateKey(now, timeZone);
  let lastProgressActivityAt: Date | null = null;

  for (const event of events) {
    const delta = Math.max(
      0,
      clampProgress(event.progress) - clampProgress(event.previousProgress)
    );
    if (delta <= 0 || !Number.isFinite(event.updatedAt.getTime())) {
      continue;
    }
    lastProgressActivityAt = latestDate(lastProgressActivityAt, event.updatedAt);
    const activityDay = localDateKey(event.updatedAt, timeZone);
    const daysAgo = dateKeyDifference(activityDay, today);
    if (daysAgo >= 0 && daysAgo < 7) {
      dailyProgressDeltas[6 - daysAgo] += delta;
    }
  }

  const weeklyProgress = dailyProgressDeltas.map((delta, index) => {
    const value = trackedLessons === 0 ? 0 : clampProgress(delta / trackedLessons);
    if (value > 0) {
      weeklyProgressByDate[localDateKey(addDays(now, index - 6), timeZone)] = value;
    }
    return value;
  });

  return {
    globalProgress: trackedLessons === 0 ? 0 : totalProgress / trackedLessons,
    trackedLessons,
    completedLessons,
    subjectProgress,
    strongSubjects: rankedSubjects
      .filter(([, value]) => value >= 0.7)
      .slice(0, 3)
      .map(([subjectId]) => subjectId),
    weakSubjects: rankedSubjects
      .filter(([, value]) => value < 0.7)
      .reverse()
      .slice(0, 3)
      .map(([subjectId]) => subjectId),
    // Each value is the honest contribution made that day to the current
    // global lesson progression, not a snapshot repeatedly counted as work.
    weeklyProgress,
    weeklyProgressByDate,
    lastProgressActivityAt
  };
}

function normalizeStoredCorrections(value: unknown): QuizSubmissionResult["corrections"] {
  if (!Array.isArray(value)) {
    return [];
  }

  return value
    .filter((item): item is Record<string, unknown> => Boolean(item) && typeof item === "object")
    .map((item) => ({
      questionId: String(item.questionId ?? ""),
      prompt: String(item.prompt ?? ""),
      userAnswer: String(item.userAnswer ?? ""),
      correctAnswer: String(item.correctAnswer ?? ""),
      explanation: String(item.explanation ?? ""),
      isCorrect: Boolean(item.isCorrect),
      pointsReward: Number(item.pointsReward ?? item.xpReward ?? 0)
    }));
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

function timestampDate(value: unknown): Date | null {
  if (value && typeof value === "object" && "toDate" in value) {
    const timestamp = value as { toDate?: () => Date };
    if (typeof timestamp.toDate === "function") {
      return timestamp.toDate();
    }
  }
  if (value instanceof Date) {
    return value;
  }
  if (typeof value === "string") {
    const parsed = new Date(value);
    return Number.isFinite(parsed.getTime()) ? parsed : null;
  }
  return null;
}

function latestDate(left: Date | null, right: Date | null): Date | null {
  if (!left) return right;
  if (!right) return left;
  return left.getTime() >= right.getTime() ? left : right;
}

function normalizedString(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

function sameAcademicValue(left: string, right: string): boolean {
  return left.trim().toLocaleLowerCase("fr") === right.trim().toLocaleLowerCase("fr");
}

function dateKeyDifference(earlier: string, later: string): number {
  const earlierDate = new Date(`${earlier}T00:00:00.000Z`);
  const laterDate = new Date(`${later}T00:00:00.000Z`);
  return Math.floor(
    (laterDate.getTime() - earlierDate.getTime()) / (24 * 60 * 60 * 1000)
  );
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
