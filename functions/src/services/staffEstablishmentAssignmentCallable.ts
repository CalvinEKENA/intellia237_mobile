import { logger } from "firebase-functions";
import type { CallableRequest } from "firebase-functions/v2/https";
import { HttpsError } from "firebase-functions/v2/https";
import {
  FieldValue,
  type DocumentData,
  type Firestore,
} from "firebase-admin/firestore";

import { db } from "../config/firebase";
import { AppError, toHttpsError } from "../utils/errors";
import {
  type StaffEstablishmentAssignmentInput,
  staffEstablishmentAssignmentInputSchema,
} from "../utils/validation";

type AssignableStaffRole = "teacher" | "admin";

export interface StaffEstablishmentAssignmentResult {
  staffId: string;
  role: AssignableStaffRole;
  establishmentId: string;
  idempotentReplay: boolean;
}

export interface StaffEstablishmentAssignmentStore {
  assignStaffEstablishment(
    assignerId: string,
    input: StaffEstablishmentAssignmentInput,
  ): Promise<StaffEstablishmentAssignmentResult>;
}

export class FirestoreStaffEstablishmentAssignmentStore
implements StaffEstablishmentAssignmentStore {
  constructor(private readonly firestore: Firestore = db) {}

  async assignStaffEstablishment(
    assignerId: string,
    input: StaffEstablishmentAssignmentInput,
  ): Promise<StaffEstablishmentAssignmentResult> {
    return this.firestore.runTransaction(async (transaction) => {
      const users = this.firestore.collection("users");
      const targetRef = users.doc(input.staffId);
      const schoolRef = this.firestore
        .collection("establishments")
        .doc(input.establishmentId);
      const [assignerSnapshot, targetSnapshot, schoolSnapshot] = await Promise.all([
        transaction.get(users.doc(assignerId)),
        transaction.get(targetRef),
        transaction.get(schoolRef),
      ]);

      if (!assignerSnapshot.exists) {
        throw new AppError("permission-denied", "Assigner account is not authorized.");
      }
      if (!targetSnapshot.exists) {
        throw new AppError("not-found", "Staff account was not found.");
      }
      // Authorization comes first: an unauthorized caller learns nothing
      // about which schools exist.
      const authorization = authorizeStaffEstablishmentAssignment({
        assignerId,
        staffId: input.staffId,
        assignerData: assignerSnapshot.data(),
        targetData: targetSnapshot.data(),
        establishmentId: input.establishmentId,
      });
      if (!schoolSnapshot.exists) {
        throw new AppError("not-found", "The school to attach does not exist.");
      }

      const profileRef = this.firestore
        .collection(authorization.role === "teacher" ? "teacher_profiles" : "admin_profiles")
        .doc(input.staffId);
      // Every read happens before the first write of the transaction.
      const profileSnapshot = await transaction.get(profileRef);

      const result: StaffEstablishmentAssignmentResult = {
        staffId: input.staffId,
        role: authorization.role,
        establishmentId: input.establishmentId,
        idempotentReplay: authorization.idempotentReplay,
      };
      if (authorization.idempotentReplay) {
        return result;
      }

      const patches = buildStaffEstablishmentPatches({
        assignerId,
        establishmentId: input.establishmentId,
      });
      transaction.update(targetRef, patches.userPatch);
      // A legacy account may have no profile: none is invented for it.
      if (profileSnapshot.exists) {
        transaction.set(profileRef, patches.profilePatch, { merge: true });
      }
      transaction.set(
        this.firestore.collection("staff_establishment_assignments").doc(input.staffId),
        {
          staffId: input.staffId,
          role: authorization.role,
          establishmentId: input.establishmentId,
          assignedBy: assignerId,
          assignedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      return result;
    });
  }
}

/**
 * Attaching a school to an approved account is the general administration's
 * call alone. Approval already attaches pending accounts; this covers the
 * accounts approved before their school existed in INTELLIA. It never moves an
 * account from one school to another.
 */
export function authorizeStaffEstablishmentAssignment({
  assignerId,
  staffId,
  assignerData,
  targetData,
  establishmentId,
}: {
  assignerId: string;
  staffId: string;
  assignerData: DocumentData | undefined;
  targetData: DocumentData | undefined;
  establishmentId: string;
}): { role: AssignableStaffRole; idempotentReplay: boolean } {
  const assignerRole = normalizedString(assignerData?.role);
  if (assignerRole !== "superAdmin" && assignerRole !== "super_admin") {
    throw new AppError("permission-denied", "Only the general administration assigns a school.");
  }
  const assignerStatus = normalizedString(assignerData?.accountStatus);
  if (assignerStatus && assignerStatus !== "active") {
    throw new AppError("permission-denied", "The assigner account is not active.");
  }
  if (assignerId === staffId) {
    throw new AppError("permission-denied", "An account cannot assign its own school.");
  }

  const role = normalizedString(targetData?.role);
  if (role !== "teacher" && role !== "admin") {
    throw new AppError(
      "failed-precondition",
      "Only teacher and administrator accounts belong to a school.",
    );
  }
  const status = normalizedString(targetData?.accountStatus);
  if (status === "pending_validation") {
    throw new AppError(
      "failed-precondition",
      "Approve this pending account instead: approval attaches its school.",
    );
  }
  if (status && status !== "active") {
    throw new AppError(
      "failed-precondition",
      "Only an active staff account can be assigned to a school.",
    );
  }

  const current = normalizedString(targetData?.establishmentId);
  if (current && current !== establishmentId) {
    throw new AppError(
      "failed-precondition",
      "A staff account already assigned to a school cannot be moved.",
    );
  }
  return { role, idempotentReplay: current === establishmentId };
}

export function buildStaffEstablishmentPatches({
  assignerId,
  establishmentId,
}: {
  assignerId: string;
  establishmentId: string;
}): {
  userPatch: Record<string, unknown>;
  profilePatch: Record<string, unknown>;
} {
  // The school travels alone: status, role, permissions and claims are never
  // part of an assignment.
  return {
    userPatch: {
      establishmentId,
      establishmentAssignedBy: assignerId,
      establishmentAssignedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    },
    profilePatch: {
      establishmentId,
      updatedAt: FieldValue.serverTimestamp(),
    },
  };
}

export function createAssignStaffEstablishmentHandler(
  store: StaffEstablishmentAssignmentStore = new FirestoreStaffEstablishmentAssignmentStore(),
) {
  return async (
    request: CallableRequest<unknown>,
  ): Promise<StaffEstablishmentAssignmentResult> => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Firebase Auth is required.");
    }

    try {
      const input = staffEstablishmentAssignmentInputSchema.parse(request.data);
      return await store.assignStaffEstablishment(request.auth.uid, input);
    } catch (error) {
      logger.error("assignStaffEstablishment failed.", {
        assignerId: request.auth.uid,
        error: error instanceof Error ? error.message : String(error),
      });
      throw toHttpsError(error);
    }
  };
}

function normalizedString(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

export const assignStaffEstablishmentHandler = createAssignStaffEstablishmentHandler();
