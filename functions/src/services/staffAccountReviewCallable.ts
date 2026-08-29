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
type ReviewerRole = "admin" | "superAdmin";
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
}: {
  reviewerId: string;
  targetId: string;
  reviewerData: DocumentData | undefined;
  targetData: DocumentData | undefined;
}): AuthorizedStaffReview {
  const reviewerRole = normalizedString(reviewerData?.role);
  if (reviewerRole !== "admin" && reviewerRole !== "superAdmin") {
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
  const establishmentId = normalizedString(targetData?.establishmentId);
  if (!establishmentId) {
    throw new AppError(
      "failed-precondition",
      "The staff account must be assigned to an establishment before review.",
    );
  }

  const reviewerEstablishmentId = normalizedString(reviewerData?.establishmentId);
  // Both administrator roles are confined to the establishment explicitly
  // assigned to their trusted user document. The role alone never grants a
  // cross-school review capability.
  if (!reviewerEstablishmentId || reviewerEstablishmentId !== establishmentId) {
    throw new AppError("permission-denied", "Cross-establishment staff review is forbidden.");
  }

  return {
    reviewerRole,
    targetRole,
    establishmentId,
  };
}

export function buildStaffReviewPatches({
  reviewerId,
  approved,
}: {
  reviewerId: string;
  approved: boolean;
}): {
  userPatch: Record<string, unknown>;
  profilePatch: Record<string, unknown>;
} {
  const status: StaffReviewStatus = approved ? "approved" : "rejected";
  return {
    // Deliberately excludes role, establishmentId, permissions and claims:
    // approving an existing request must never become a privilege-escalation API.
    userPatch: {
      accountStatus: approved ? "active" : "rejected",
      requiresValidation: false,
      reviewedBy: reviewerId,
      reviewedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    },
    profilePatch: {
      validation: {
        status,
        required: false,
        reviewedBy: reviewerId,
        reviewedAt: FieldValue.serverTimestamp(),
      },
      updatedAt: FieldValue.serverTimestamp(),
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
