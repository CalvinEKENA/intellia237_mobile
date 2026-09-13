import { createHash, randomUUID } from "node:crypto";

import { logger } from "firebase-functions";
import { FieldValue, type Firestore } from "firebase-admin/firestore";
import { HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import { z } from "zod";

import { db } from "../config/firebase";
import { AppError, toHttpsError } from "../utils/errors";
import { accumulatedPoints } from "./pointsPolicy";
import { scopeId } from "./lessonPublicationCallable";
import {
  FLOW_CATALOG,
  isAcceptedFlowAnswer,
  normalizedFlowAnswer,
  type FlowActivityKind,
  type FlowAnswer
} from "./flowCatalog";

export const FLOW_DAILY_POINTS_CAP = 400;
const FLOW_TIMEZONE = "Africa/Douala";

const flowActivityInputSchema = z.object({
  clientEventId: z.string().trim().min(8).max(128).regex(/^[A-Za-z0-9_-]+$/),
  cardId: z.string().trim().min(1).max(160).regex(/^[A-Za-z0-9_-]+$/),
  kind: z.enum(["content", "choice", "boolean", "text", "ordering"]),
  answer: z.union([
    z.string().max(400),
    z.number().int().min(0).max(20),
    z.boolean(),
    z.array(z.string().trim().min(1).max(160)).min(2).max(12),
    z.null()
  ])
}).strict();

export interface FlowActivityCommand {
  studentId: string;
  clientEventId: string;
  cardId: string;
  kind: FlowActivityKind;
  answer: FlowAnswer;
}

export interface FlowActivityResult {
  clientEventId: string;
  cardId: string;
  correct: boolean;
  pointsAwarded: number;
  totalPoints: number;
  alreadyCompleted: boolean;
  dailyCapReached: boolean;
  idempotentReplay: boolean;
}

export interface FlowPointsStore {
  submit(command: FlowActivityCommand): Promise<FlowActivityResult>;
}

export class FirestoreFlowPointsStore implements FlowPointsStore {
  constructor(private readonly firestore: Firestore = db) {}

  async submit(command: FlowActivityCommand): Promise<FlowActivityResult> {
    const eventId = flowDocumentId(command.studentId, command.clientEventId);
    const completionId = flowDocumentId(command.studentId, command.cardId);
    const requestHash = flowRequestHash(command);
    const today = doualaDateKey(new Date());

    return this.firestore.runTransaction(async (transaction) => {
      const eventRef = this.firestore.collection("flow_events").doc(eventId);
      const completionRef = this.firestore.collection("flow_completions").doc(completionId);
      const dailyRef = this.firestore.collection("flow_daily_points")
        .doc(flowDocumentId(command.studentId, today));
      const userRef = this.firestore.collection("users").doc(command.studentId);
      const profileRef = this.firestore.collection("student_profiles").doc(command.studentId);

      const eventSnapshot = await transaction.get(eventRef);
      if (eventSnapshot.exists) {
        const replay = idempotentFlowReplay(eventSnapshot.data(), requestHash);
        const [userSnapshot, profileSnapshot] = await Promise.all([
          transaction.get(userRef),
          transaction.get(profileRef)
        ]);
        if (userSnapshot.data()?.role !== "student") {
          throw new AppError("permission-denied", "FLOW points are reserved for student accounts.");
        }
        return {
          ...replay,
          totalPoints: Math.max(
            replay.totalPoints,
            accumulatedPoints(userSnapshot.data()),
            accumulatedPoints(profileSnapshot.data())
          )
        };
      }

      // Toutes les lectures précèdent les écritures pour préserver les
      // garanties transactionnelles Firestore, y compris lors des conflits.
      const [completionSnapshot, dailySnapshot, userSnapshot, profileSnapshot] =
        await Promise.all([
          transaction.get(completionRef),
          transaction.get(dailyRef),
          transaction.get(userRef),
          transaction.get(profileRef)
        ]);

      if (userSnapshot.data()?.role !== "student") {
        throw new AppError("permission-denied", "FLOW points are reserved for student accounts.");
      }
      if (!profileSnapshot.exists) {
        throw new AppError("failed-precondition", "Student profile is incomplete.");
      }

      const evaluation = FLOW_CATALOG[command.cardId]
        ? evaluateFlowActivity(command)
        : evaluatePublishedFlowActivity(command,
            (await transaction.get(this.firestore.doc(`flow_items/${command.cardId}`))).data(),
            userSnapshot.data()!, profileSnapshot.data()!);

      const currentTotal = Math.max(
        accumulatedPoints(userSnapshot.data()),
        accumulatedPoints(profileSnapshot.data())
      );
      const alreadyCompleted = completionSnapshot.exists;
      const dailyPoints = safeNonNegativeInteger(dailySnapshot.data()?.pointsAwarded);
      const availableToday = Math.max(0, FLOW_DAILY_POINTS_CAP - dailyPoints);
      const requestedReward = !alreadyCompleted && evaluation.correct
        ? evaluation.pointsReward
        : 0;
      const pointsAwarded = Math.min(requestedReward, availableToday);
      const totalPoints = currentTotal + pointsAwarded;
      const dailyCapReached = requestedReward > pointsAwarded;

      const result: FlowActivityResult = {
        clientEventId: command.clientEventId,
        cardId: command.cardId,
        correct: evaluation.correct,
        pointsAwarded,
        totalPoints,
        alreadyCompleted,
        dailyCapReached,
        idempotentReplay: false
      };

      transaction.set(eventRef, {
        studentId: command.studentId,
        clientEventId: command.clientEventId,
        cardId: command.cardId,
        kind: command.kind,
        requestHash,
        result,
        createdAt: FieldValue.serverTimestamp()
      });

      if (!alreadyCompleted) {
        transaction.set(completionRef, {
          studentId: command.studentId,
          cardId: command.cardId,
          correct: evaluation.correct,
          pointsAwarded,
          completedAt: FieldValue.serverTimestamp()
        });
      }

      if (pointsAwarded > 0) {
        transaction.set(dailyRef, {
          studentId: command.studentId,
          date: today,
          timezone: FLOW_TIMEZONE,
          pointsAwarded: dailyPoints + pointsAwarded,
          updatedAt: FieldValue.serverTimestamp()
        }, { merge: true });
      }

      // Le total est réconcilié à partir de la valeur canonique la plus haute,
      // puis écrit par Admin SDK. Le client ne peut modifier aucun de ces champs.
      transaction.set(userRef, {
        points: totalPoints,
        lastActivityAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp()
      }, { merge: true });
      transaction.set(profileRef, {
        points: totalPoints,
        lastAcademicActivityAt: FieldValue.serverTimestamp(),
        lastAcademicActivityDate: today,
        updatedAt: FieldValue.serverTimestamp()
      }, { merge: true });

      return result;
    });
  }
}

export function evaluatePublishedFlowActivity(
  command: Pick<FlowActivityCommand, "kind" | "answer">,
  item: FirebaseFirestore.DocumentData | undefined,
  user: FirebaseFirestore.DocumentData,
  profile: FirebaseFirestore.DocumentData,
): { correct: boolean; pointsReward: number } {
  const date = (value: unknown) => typeof value === "string" ? Date.parse(value)
    : (value as { toMillis?: () => number } | undefined)?.toMillis?.() || 0;
  if (!item || item.status !== "published" || date(item.scheduledAt) > Date.now() ||
      date(item.publishedAt) > Date.now() ||
      !item.classLevels?.includes(profile.classLevel || user.classLevel) ||
      (scopeId(item) !== "global" && scopeId(item) !== user.establishmentId)) {
    throw new AppError("not-found", "FLOW activity unavailable.");
  }
  if (item.type === "quiz") {
    const payload = item.payload || {};
    if (command.kind !== "choice" || !Number.isInteger(payload.correctIndex) ||
        payload.correctIndex < 0 || payload.correctIndex >= (payload.options?.length || 0)) {
      throw new AppError("invalid-argument", "Invalid FLOW quiz.");
    }
    return { correct: command.answer === payload.correctIndex, pointsReward: 25 };
  }
  // Reveal/read cards award reading points, never a guessed free-text grade.
  if (!["notion", "question", "image", "infographic", "audio", "shortVideo", "interactiveNative"].includes(item.type) || command.kind !== "content") {
    throw new AppError("invalid-argument", "Invalid FLOW activity kind.");
  }
  return { correct: command.answer === null, pointsReward: 10 };
}

export function evaluateFlowActivity(command: Omit<FlowActivityCommand, "studentId" | "clientEventId">): {
  correct: boolean;
  pointsReward: number;
} {
  const entry = FLOW_CATALOG[command.cardId];
  if (!entry) {
    throw new AppError("not-found", "Unknown FLOW card.");
  }
  if (entry.kind !== command.kind) {
    throw new AppError("invalid-argument", "FLOW activity kind does not match the server catalog.");
  }
  return {
    correct: isAcceptedFlowAnswer(entry, command.answer),
    pointsReward: Math.min(25, Math.max(0, Math.trunc(entry.pointsReward)))
  };
}

export function flowRequestHash(command: Pick<FlowActivityCommand, "cardId" | "kind" | "answer">): string {
  return createHash("sha256")
    .update(JSON.stringify({
      cardId: command.cardId,
      kind: command.kind,
      answer: normalizedFlowAnswer(command.answer)
    }))
    .digest("hex");
}

export function flowDocumentId(...parts: string[]): string {
  // Longueur fixe et encodage non ambigu : deux UID/événements construits
  // différemment ne peuvent pas viser le document d'un autre élève.
  return createHash("sha256").update(JSON.stringify(parts)).digest("hex");
}

export function idempotentFlowReplay(
  data: FirebaseFirestore.DocumentData | undefined,
  requestHash: string
): FlowActivityResult {
  if (data?.requestHash !== requestHash) {
    throw new AppError(
      "already-exists",
      "Client event id was already used with a different FLOW activity."
    );
  }
  const stored = data?.result as Partial<FlowActivityResult> | undefined;
  if (!stored || typeof stored.clientEventId !== "string" || typeof stored.cardId !== "string") {
    throw new AppError("internal", "Stored FLOW event is incomplete.");
  }
  return {
    clientEventId: stored.clientEventId,
    cardId: stored.cardId,
    correct: Boolean(stored.correct),
    pointsAwarded: safeNonNegativeInteger(stored.pointsAwarded),
    totalPoints: safeNonNegativeInteger(stored.totalPoints),
    alreadyCompleted: Boolean(stored.alreadyCompleted),
    dailyCapReached: Boolean(stored.dailyCapReached),
    idempotentReplay: true
  };
}

export function createSubmitFlowActivityHandler(
  store: FlowPointsStore = new FirestoreFlowPointsStore()
) {
  return async (request: CallableRequest): Promise<FlowActivityResult & { traceId: string }> => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Firebase Auth is required.");
    }
    const traceId = randomUUID();
    try {
      const input = flowActivityInputSchema.parse(request.data);
      const result = await store.submit({
        studentId: request.auth.uid,
        clientEventId: input.clientEventId,
        cardId: input.cardId,
        kind: input.kind,
        answer: input.answer
      });
      logger.info("submitFlowActivity completed.", {
        traceId,
        cardId: input.cardId,
        pointsAwarded: result.pointsAwarded,
        idempotentReplay: result.idempotentReplay,
        dailyCapReached: result.dailyCapReached
      });
      return { traceId, ...result };
    } catch (error) {
      logger.error("submitFlowActivity failed.", {
        traceId,
        errorCategory: error instanceof HttpsError
          ? error.code
          : error instanceof Error
            ? error.name
            : "unknown"
      });
      throw toHttpsError(error);
    }
  };
}

function doualaDateKey(date: Date): string {
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone: FLOW_TIMEZONE,
    year: "numeric",
    month: "2-digit",
    day: "2-digit"
  }).formatToParts(date);
  const get = (type: Intl.DateTimeFormatPartTypes): string =>
    parts.find((part) => part.type === type)?.value ?? "00";
  return `${get("year")}-${get("month")}-${get("day")}`;
}

function safeNonNegativeInteger(value: unknown): number {
  const number = Number(value ?? 0);
  return Number.isFinite(number) ? Math.max(0, Math.trunc(number)) : 0;
}

export const submitFlowActivityHandler = createSubmitFlowActivityHandler();
