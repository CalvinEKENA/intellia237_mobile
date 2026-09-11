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
  type StaffAccountReviewCallableInput,
  staffAccountReviewCallableInputSchema,
} from "../utils/validation";

type ReviewableStaffRole = "teacher" | "admin";
type ReviewerRole = "admin" | "superAdmin" | "super_admin";
type StaffReviewStatus = "approved" | "rejected";

export interface StaffAccountReviewResult {
  reviewId: string;
  role: ReviewableStaffRole;
  establishmentId: string;
  status: StaffReviewStatus;
  idempotentReplay: boolean;
}

interface AuthorizedStaffReview {
  reviewerRole: ReviewerRole;
  targetRole: ReviewableStaffRole;
  establishmentId: string;
  attachesEstablishment: boolean;
}

export interface StaffAccountReviewStore {
  reviewStaffAccount(
    reviewerId: string,
    input: StaffAccountReviewCallableInput,
  ): Promise<StaffAccountReviewResult>;
}

export class FirestoreStaffAccountReviewStore
implements StaffAccountReviewStore {
  constructor(private readonly firestore: Firestore = db) {}

  async reviewStaffAccount(
    reviewerId: string,
    input: StaffAccountReviewCallableInput,
  ): Promise<StaffAccountReviewResult> {
    return this.firestore.runTransaction(async (transaction) => {
      const reviewerRef = this.firestore.collection("users").doc(reviewerId);
      const targetRef = this.firestore.collection("users").doc(input.reviewId);
      const [reviewerSnapshot, targetSnapshot] = await Promise.all([
        transaction.get(reviewerRef),
        transaction.get(targetRef),
      ]);

      if (!reviewerSnapshot.exists) {
        throw new AppError("permission-denied", "Reviewer account is not authorized.");
      }
      if (!targetSnapshot.exists) {
        throw new AppError("not-found", "Staff account was not found.");
      }

      const authorization = authorizeStaffReview({
        reviewerId,
        targetId: input.reviewId,
        reviewerData: reviewerSnapshot.data(),
        targetData: targetSnapshot.data(),
        approved: input.approved,
        requestedEstablishmentId: input.establishmentId,
      });
      const profileCollection = authorization.targetRole === "teacher"
        ? "teacher_profiles"
        : "admin_profiles";
      const profileRef = this.firestore
        .collection(profileCollection)
        .doc(input.reviewId);
      const profileSnapshot = await transaction.get(profileRef);
      if (!profileSnapshot.exists) {
        throw new AppError(
          "failed-precondition",
          "The staff profile must exist before it can be reviewed.",
        );
      }
      if (input.approved && authorization.attachesEstablishment) {
        // Every read happens before the first write of the transaction.
        const school = await transaction.get(
          this.firestore.collection("establishments").doc(authorization.establishmentId),
        );
        if (!school.exists) {
          throw new AppError("not-found", "The school to attach does not exist.");
        }
      }

      const status: StaffReviewStatus = input.approved ? "approved" : "rejected";
      const targetStatus = normalizedString(targetSnapshot.data()?.accountStatus);
      const expectedAccountStatus = input.approved ? "active" : "rejected";
      if (targetStatus === expectedAccountStatus) {
        return {
          reviewId: input.reviewId,
          role: authorization.targetRole,
          establishmentId: authorization.establishmentId,
          status,
          idempotentReplay: true,
        };
      }
      if (targetStatus !== "pending_validation") {
        throw new AppError(
          "failed-precondition",
          "Only a pending staff account can be reviewed.",
        );
      }

      const patches = buildStaffReviewPatches({
        reviewerId,
        approved: input.approved,
        attachEstablishmentId: authorization.attachesEstablishment
          ? authorization.establishmentId
          : undefined,
      });
      transaction.update(targetRef, patches.userPatch);
      transaction.set(profileRef, patches.profilePatch, { merge: true });
      transaction.set(
        this.firestore.collection("staff_account_reviews").doc(input.reviewId),
        {
          targetUid: input.reviewId,
          targetRole: authorization.targetRole,
          establishmentId: authorization.establishmentId,
          status,
          reviewedBy: reviewerId,
          reviewedAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

      return {
        reviewId: input.reviewId,
        role: authorization.targetRole,
        establishmentId: authorization.establishmentId,
        status,
        idempotentReplay: false,
      };
    });
  }
}

export function authorizeStaffReview({
  reviewerId,
  targetId,
  reviewerData,
  targetData,
  approved = true,
  requestedEstablishmentId,
}: {
  reviewerId: string;
  targetId: string;
  reviewerData: DocumentData | undefined;
  targetData: DocumentData | undefined;
  approved?: boolean;
  requestedEstablishmentId?: string;
}): AuthorizedStaffReview {
  const reviewerRole = normalizedString(reviewerData?.role);
  if (
    reviewerRole !== "admin" &&
    reviewerRole !== "superAdmin" &&
    reviewerRole !== "super_admin"
  ) {
    throw new AppError("permission-denied", "Only an administrator can review staff accounts.");
  }
  const reviewerStatus = normalizedString(reviewerData?.accountStatus);
  if (reviewerStatus && reviewerStatus !== "active") {
    throw new AppError("permission-denied", "The reviewer account is not active.");
  }
  if (reviewerId === targetId) {
    throw new AppError("permission-denied", "A staff member cannot review their own account.");
  }

  const targetRole = normalizedString(targetData?.role);
  if (targetRole !== "teacher" && targetRole !== "admin") {
    throw new AppError("failed-precondition", "Only teacher and administrator accounts are reviewable.");
  }
  const currentEstablishmentId = normalizedString(targetData?.establishmentId);
  const requested = normalizedString(requestedEstablishmentId);

  if (reviewerRole !== "admin") {
    // The general administration reviews for every school. It attaches a
    // school to an account that has none, and never moves an assigned one.
    if (currentEstablishmentId && requested && requested !== currentEstablishmentId) {
      throw new AppError(
        "failed-precondition",
        "A staff account already assigned to a school cannot be moved by a review.",
      );
    }
    const establishmentId = currentEstablishmentId || requested;
    if (approved && !establishmentId) {
      throw new AppError(
        "failed-precondition",
        "Choose the school this staff account belongs to before approving it.",
      );
    }
    return {
      reviewerRole,
      targetRole,
      establishmentId,
      attachesEstablishment: !currentEstablishmentId && requested.length > 0,
    };
  }

  // A school administrator reviews only the teachers of their own school and
  // never assigns one: the role alone grants no cross-school capability.
  if (requested) {
    throw new AppError("permission-denied", "Only the general administration assigns a school.");
  }
  if (targetRole !== "teacher") {
    throw new AppError("permission-denied", "A school administrator only reviews teachers.");
  }
  if (!currentEstablishmentId) {
    throw new AppError(
      "failed-precondition",
      "The staff account must be assigned to an establishment before review.",
    );
  }
  const reviewerEstablishmentId = normalizedString(reviewerData?.establishmentId);
  if (!reviewerEstablishmentId || reviewerEstablishmentId !== currentEstablishmentId) {
    throw new AppError("permission-denied", "Cross-establishment staff review is forbidden.");
  }
  return {
    reviewerRole,
    targetRole,
    establishmentId: currentEstablishmentId,
    attachesEstablishment: false,
  };
}

export function buildStaffReviewPatches({
  reviewerId,
  approved,
  attachEstablishmentId,
}: {
  reviewerId: string;
  approved: boolean;
  attachEstablishmentId?: string;
}): {
  userPatch: Record<string, unknown>;
  profilePatch: Record<string, unknown>;
} {
  const status: StaffReviewStatus = approved ? "approved" : "rejected";
  // Role, permissions and claims never travel with a review: approving a
  // request must not become a privilege-escalation API. A school travels only
  // when the general administration attaches one to an unassigned account.
  const school = approved && attachEstablishmentId
    ? { establishmentId: attachEstablishmentId }
    : {};
  return {
    userPatch: {
      accountStatus: approved ? "active" : "rejected",
      requiresValidation: false,
      reviewedBy: reviewerId,
      reviewedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
      ...school,
    },
    profilePatch: {
      validation: {
        status,
        required: false,
        reviewedBy: reviewerId,
        reviewedAt: FieldValue.serverTimestamp(),
      },
      updatedAt: FieldValue.serverTimestamp(),
      ...school,
    },
  };
}

export function createReviewStaffAccountHandler(
  store: StaffAccountReviewStore = new FirestoreStaffAccountReviewStore(),
) {
  return async (
    request: CallableRequest<unknown>,
  ): Promise<StaffAccountReviewResult> => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Firebase Auth is required.");
    }

    try {
      const input = staffAccountReviewCallableInputSchema.parse(request.data);
      return await store.reviewStaffAccount(request.auth.uid, input);
    } catch (error) {
      logger.error("reviewStaffAccount failed.", {
        reviewerId: request.auth.uid,
        error: error instanceof Error ? error.message : String(error),
      });
      throw toHttpsError(error);
    }
  };
}

function normalizedString(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

export const reviewStaffAccountHandler = createReviewStaffAccountHandler();
