import { logger } from "firebase-functions";
import type { CallableRequest } from "firebase-functions/v2/https";
import { HttpsError } from "firebase-functions/v2/https";
import {
  FieldValue,
  type DocumentData,
  type Firestore,
  type Query,
} from "firebase-admin/firestore";

import { db } from "../config/firebase";
import { AppError, toHttpsError } from "../utils/errors";
import {
  type AccountEstablishmentChangeInput,
  accountEstablishmentChangeInputSchema,
} from "../utils/validation";

type ChangeableRole = "student" | "parent" | "teacher" | "admin";

const PROFILE_COLLECTION: Record<ChangeableRole, string | null> = {
  student: "student_profiles",
  teacher: "teacher_profiles",
  admin: "admin_profiles",
  // A parent's school lives on the user document alone.
  parent: null,
};

export interface AccountEstablishmentChangeResult {
  accountId: string;
  role: ChangeableRole;
  fromEstablishmentId: string | null;
  establishmentId: string;
  leftClassIds: string[];
  idempotentReplay: boolean;
}

export interface AccountEstablishmentChangeStore {
  changeAccountEstablishment(
    changerId: string,
    input: AccountEstablishmentChangeInput,
  ): Promise<AccountEstablishmentChangeResult>;
}

/** What an account leaves behind in a class of its former school. */
export interface ClassDeparture {
  classId: string;
  removeStudent: boolean;
  removeTeacher: boolean;
  clearMainTeacher: boolean;
  studentCount?: number;
}

export class FirestoreAccountEstablishmentChangeStore
implements AccountEstablishmentChangeStore {
  constructor(private readonly firestore: Firestore = db) {}

  async changeAccountEstablishment(
    changerId: string,
    input: AccountEstablishmentChangeInput,
  ): Promise<AccountEstablishmentChangeResult> {
    return this.firestore.runTransaction(async (transaction) => {
      const users = this.firestore.collection("users");
      const classes = this.firestore.collection("classes");
      const targetRef = users.doc(input.accountId);
      const schoolRef = this.firestore
        .collection("establishments")
        .doc(input.establishmentId);
      const [changerSnapshot, targetSnapshot, schoolSnapshot] = await Promise.all([
        transaction.get(users.doc(changerId)),
        transaction.get(targetRef),
        transaction.get(schoolRef),
      ]);

      if (!changerSnapshot.exists) {
        throw new AppError("permission-denied", "Account is not authorized.");
      }
      if (!targetSnapshot.exists) {
        throw new AppError("not-found", "Account was not found.");
      }
      // Authorization comes first: an unauthorized caller learns nothing
      // about which schools exist.
      const authorization = authorizeAccountEstablishmentChange({
        changerId,
        accountId: input.accountId,
        changerData: changerSnapshot.data(),
        targetData: targetSnapshot.data(),
        establishmentId: input.establishmentId,
        reason: input.reason,
      });
      if (!schoolSnapshot.exists) {
        throw new AppError("not-found", "The destination school does not exist.");
      }

      const profileCollection = PROFILE_COLLECTION[authorization.role];
      const profileRef = profileCollection
        ? this.firestore.collection(profileCollection).doc(input.accountId)
        : null;
      const classQueries: Query[] = authorization.role === "student"
        ? [classes.where("studentIds", "array-contains", input.accountId)]
        : authorization.role === "teacher"
          ? [
            classes.where("teacherIds", "array-contains", input.accountId),
            classes.where("mainTeacherId", "==", input.accountId),
          ]
          : [];

      // Every read happens before the first write of the transaction.
      const profileSnapshot = profileRef ? await transaction.get(profileRef) : null;
      const classDocuments = new Map<string, DocumentData>();
      for (const query of classQueries) {
        const snapshot = await transaction.get(query);
        for (const document of snapshot.docs) {
          classDocuments.set(document.id, document.data());
        }
      }

      if (authorization.idempotentReplay) {
        return {
          accountId: input.accountId,
          role: authorization.role,
          fromEstablishmentId: authorization.fromEstablishmentId,
          establishmentId: input.establishmentId,
          leftClassIds: [],
          idempotentReplay: true,
        };
      }

      const departures = planClassDepartures({
        role: authorization.role,
        accountId: input.accountId,
        destinationEstablishmentId: input.establishmentId,
        classes: [...classDocuments].map(([id, data]) => ({ id, data })),
      });
      const rawName: unknown = schoolSnapshot.data()?.name;
      const patches = buildAccountEstablishmentPatches({
        changerId,
        role: authorization.role,
        establishmentId: input.establishmentId,
        establishmentName: typeof rawName === "string" ? rawName.trim() : "",
      });

      transaction.update(targetRef, patches.userPatch);
      // A legacy account may have no profile: none is invented for it.
      if (profileRef && profileSnapshot?.exists) {
        transaction.set(profileRef, patches.profilePatch, { merge: true });
      }
      for (const departure of departures) {
        transaction.update(
          classes.doc(departure.classId),
          classDeparturePatch(departure, input.accountId),
        );
      }
      const leftClassIds = departures.map((departure) => departure.classId);
      transaction.set(this.firestore.collection("establishment_changes").doc(), {
        accountId: input.accountId,
        role: authorization.role,
        fromEstablishmentId: authorization.fromEstablishmentId,
        toEstablishmentId: input.establishmentId,
        reason: input.reason ?? null,
        leftClassIds,
        changedBy: changerId,
        changedAt: FieldValue.serverTimestamp(),
      });

      return {
        accountId: input.accountId,
        role: authorization.role,
        fromEstablishmentId: authorization.fromEstablishmentId,
        establishmentId: input.establishmentId,
        leftClassIds,
        idempotentReplay: false,
      };
    });
  }
}

/**
 * A school is the general administration's call alone. It attaches an account
 * that has none, and moves an account whose school was wrong — a mistake at
 * registration, by the paying parent or by the administration itself — with a
 * reason kept for audit.
 */
export function authorizeAccountEstablishmentChange({
  changerId,
  accountId,
  changerData,
  targetData,
  establishmentId,
  reason,
}: {
  changerId: string;
  accountId: string;
  changerData: DocumentData | undefined;
  targetData: DocumentData | undefined;
  establishmentId: string;
  reason?: string;
}): {
  role: ChangeableRole;
  fromEstablishmentId: string | null;
  idempotentReplay: boolean;
} {
  const changerRole = normalizedString(changerData?.role);
  if (changerRole !== "superAdmin" && changerRole !== "super_admin") {
    throw new AppError(
      "permission-denied",
      "Only the general administration changes an account's school.",
    );
  }
  const changerStatus = normalizedString(changerData?.accountStatus);
  if (changerStatus && changerStatus !== "active") {
    throw new AppError("permission-denied", "The account making the change is not active.");
  }
  if (changerId === accountId) {
    throw new AppError("permission-denied", "An account cannot change its own school.");
  }

  const role = normalizedString(targetData?.role);
  if (role !== "student" && role !== "parent" && role !== "teacher" && role !== "admin") {
    throw new AppError(
      "failed-precondition",
      "Only student, parent, teacher and school administrator accounts belong to a school.",
    );
  }
  const status = normalizedString(targetData?.accountStatus);
  if ((role === "teacher" || role === "admin") && status === "pending_validation") {
    throw new AppError(
      "failed-precondition",
      "Approve this pending account instead: approval attaches its school.",
    );
  }
  if ((role === "teacher" || role === "admin") && status && status !== "active") {
    throw new AppError(
      "failed-precondition",
      "Only an active staff account can change school.",
    );
  }

  const current = normalizedString(targetData?.establishmentId);
  if (current === establishmentId) {
    return { role, fromEstablishmentId: current, idempotentReplay: true };
  }
  if (current && normalizedString(reason).length < 5) {
    throw new AppError(
      "failed-precondition",
      "Say why this account changes school: the reason is kept for audit.",
    );
  }
  return { role, fromEstablishmentId: current || null, idempotentReplay: false };
}

/**
 * Classes of the former school let the account go: a pupil leaves the roster,
 * a teacher leaves the teaching team and, when needed, the main teacher seat.
 * A class of the destination school keeps its member.
 */
export function planClassDepartures({
  role,
  accountId,
  destinationEstablishmentId,
  classes,
}: {
  role: ChangeableRole;
  accountId: string;
  destinationEstablishmentId: string;
  classes: Array<{ id: string; data: DocumentData | undefined }>;
}): ClassDeparture[] {
  const departures: ClassDeparture[] = [];
  for (const { id, data } of classes) {
    if (normalizedString(data?.establishmentId) === destinationEstablishmentId) {
      continue;
    }
    const removeStudent = role === "student" && stringList(data?.studentIds).includes(accountId);
    const removeTeacher = role === "teacher" && stringList(data?.teacherIds).includes(accountId);
    const clearMainTeacher = role === "teacher" &&
      normalizedString(data?.mainTeacherId) === accountId;
    if (!removeStudent && !removeTeacher && !clearMainTeacher) {
      continue;
    }
    const count: unknown = data?.studentCount;
    departures.push({
      classId: id,
      removeStudent,
      removeTeacher,
      clearMainTeacher,
      ...(removeStudent && typeof count === "number"
        ? { studentCount: Math.max(0, count - 1) }
        : {}),
    });
  }
  return departures;
}

export function buildAccountEstablishmentPatches({
  changerId,
  role,
  establishmentId,
  establishmentName,
}: {
  changerId: string;
  role: ChangeableRole;
  establishmentId: string;
  establishmentName: string;
}): {
  userPatch: Record<string, unknown>;
  profilePatch: Record<string, unknown>;
} {
  // The school travels alone: status, role, permissions and claims are never
  // part of a change of school.
  return {
    userPatch: {
      establishmentId,
      establishmentAssignedBy: changerId,
      establishmentAssignedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    },
    profilePatch: {
      establishmentId,
      ...(role === "student" && establishmentName ? { establishmentName } : {}),
      updatedAt: FieldValue.serverTimestamp(),
    },
  };
}

function classDeparturePatch(
  departure: ClassDeparture,
  accountId: string,
): Record<string, unknown> {
  return {
    ...(departure.removeStudent ? { studentIds: FieldValue.arrayRemove(accountId) } : {}),
    ...(departure.studentCount !== undefined ? { studentCount: departure.studentCount } : {}),
    ...(departure.removeTeacher ? { teacherIds: FieldValue.arrayRemove(accountId) } : {}),
    ...(departure.clearMainTeacher ? { mainTeacherId: FieldValue.delete() } : {}),
    updatedAt: FieldValue.serverTimestamp(),
  };
}

export function createChangeAccountEstablishmentHandler(
  store: AccountEstablishmentChangeStore = new FirestoreAccountEstablishmentChangeStore(),
) {
  return async (
    request: CallableRequest<unknown>,
  ): Promise<AccountEstablishmentChangeResult> => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Firebase Auth is required.");
    }

    try {
      const input = accountEstablishmentChangeInputSchema.parse(request.data);
      return await store.changeAccountEstablishment(request.auth.uid, input);
    } catch (error) {
      logger.error("changeAccountEstablishment failed.", {
        changerId: request.auth.uid,
        error: error instanceof Error ? error.message : String(error),
      });
      throw toHttpsError(error);
    }
  };
}

function normalizedString(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

function stringList(value: unknown): string[] {
  return Array.isArray(value)
    ? value.filter((item): item is string => typeof item === "string")
    : [];
}

export const changeAccountEstablishmentHandler = createChangeAccountEstablishmentHandler();
