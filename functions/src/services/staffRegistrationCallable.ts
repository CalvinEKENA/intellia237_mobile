import { logger } from "firebase-functions";
import type { CallableRequest } from "firebase-functions/v2/https";
import { HttpsError } from "firebase-functions/v2/https";

import { db } from "../config/firebase";
import { AppError, toHttpsError } from "../utils/errors";
import {
  type StaffRegistrationCallableInput,
  staffRegistrationCallableInputSchema,
} from "../utils/validation";

export interface StaffRegistrationResult {
  uid: string;
  email: string;
  firstName: string;
  lastName: string;
  role: "teacher" | "admin";
  accountStatus: "pending_validation";
}

interface StaffRegistrationDocuments {
  userDocument: Record<string, unknown>;
  profileCollection: "teacher_profiles" | "admin_profiles";
  profileDocument: Record<string, unknown>;
}

export interface StaffRegistrationStore {
  saveStaffRegistration(
    uid: string,
    input: StaffRegistrationCallableInput,
  ): Promise<StaffRegistrationResult>;
}

export class FirestoreStaffRegistrationStore implements StaffRegistrationStore {
  async saveStaffRegistration(
    uid: string,
    input: StaffRegistrationCallableInput,
  ): Promise<StaffRegistrationResult> {
    const now = new Date();
    const documents = buildStaffRegistrationDocuments({ uid, input, now });
    const userRef = db.collection("users").doc(uid);
    const profileRef = db.collection(documents.profileCollection).doc(uid);

    await db.runTransaction(async (transaction) => {
      const existing = await transaction.get(userRef);
      if (existing.exists) {
        const data = existing.data() ?? {};
        if (
          data.role !== input.role ||
          data.email !== normalizeEmail(input.email)
        ) {
          throw new AppError(
            "already-exists",
            "A different profile already exists for this account.",
          );
        }
        return;
      }

      transaction.set(userRef, documents.userDocument, { merge: false });
      transaction.set(profileRef, documents.profileDocument, { merge: false });
    });

    return {
      uid,
      email: normalizeEmail(input.email),
      firstName: input.firstName,
      lastName: input.lastName,
      role: input.role,
      accountStatus: "pending_validation",
    };
  }
}

export function buildStaffRegistrationDocuments({
  uid,
  input,
  now,
}: {
  uid: string;
  input: StaffRegistrationCallableInput;
  now: Date;
}): StaffRegistrationDocuments {
  const acceptedAt = now;
  const email = normalizeEmail(input.email);
  const baseUser = {
    uid,
    firstName: input.firstName,
    lastName: input.lastName,
    email,
    role: input.role,
    establishmentId: input.establishment.id,
    profileCompleted: true,
    accountStatus: "pending_validation",
    requiresValidation: true,
    tourGuideSeen: false,
    createdAt: now,
    updatedAt: now,
  };

  if (input.role === "teacher") {
    return {
      userDocument: {
        ...baseUser,
        avatarId: "mentor",
      },
      profileCollection: "teacher_profiles",
      profileDocument: {
        uid,
        firstName: input.firstName,
        lastName: input.lastName,
        email,
        establishmentId: input.establishment.id,
        establishmentName: input.establishment.name,
        subjects: input.subjects,
        levels: input.levels,
        workload: {
          activeClasses: 0,
          activeStudents: 0,
        },
        settings: {
          notificationsEnabled: true,
          resourceRecommendationsEnabled: true,
        },
        validation: {
          status: "pending",
          required: true,
          requestedAt: now,
          reviewedAt: null,
        },
        profileCompleted: true,
        createdAt: now,
        updatedAt: now,
        consents: {
          termsAccepted: input.acceptedTerms,
          privacyAccepted: input.acceptedPrivacy,
          acceptedAt,
        },
      },
    };
  }

  return {
    userDocument: {
      ...baseUser,
      jobTitle: input.jobTitle,
      avatarId: "administrator",
    },
    profileCollection: "admin_profiles",
    profileDocument: {
      uid,
      firstName: input.firstName,
      lastName: input.lastName,
      email,
      jobTitle: input.jobTitle,
      establishmentId: input.establishment.id,
      establishmentName: input.establishment.name,
      validation: {
        status: "pending",
        required: true,
        requestedAt: now,
        reviewedAt: null,
      },
      permissions: {
        canManageTeachers: false,
        canManageStudents: false,
        canViewFinance: false,
      },
      profileCompleted: true,
      createdAt: now,
      updatedAt: now,
      consents: {
        termsAccepted: input.acceptedTerms,
        privacyAccepted: input.acceptedPrivacy,
        acceptedAt,
      },
    },
  };
}

export function createSubmitStaffRegistrationHandler(
  store: StaffRegistrationStore = new FirestoreStaffRegistrationStore(),
) {
  return async (
    request: CallableRequest<unknown>,
  ): Promise<StaffRegistrationResult> => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Firebase Auth is required.");
    }

    try {
      const input = staffRegistrationCallableInputSchema.parse(request.data);
      const tokenEmail =
        typeof request.auth.token.email === "string"
          ? normalizeEmail(request.auth.token.email)
          : null;
      if (tokenEmail && tokenEmail !== normalizeEmail(input.email)) {
        throw new AppError(
          "permission-denied",
          "Authenticated email does not match registration email.",
        );
      }

      return await store.saveStaffRegistration(request.auth.uid, input);
    } catch (error) {
      logger.error("submitStaffRegistration failed.", {
        uid: request.auth.uid,
        error: error instanceof Error ? error.message : String(error),
      });
      throw toHttpsError(error);
    }
  };
}

function normalizeEmail(email: string): string {
  return email.trim().toLowerCase();
}

export const submitStaffRegistrationHandler =
  createSubmitStaffRegistrationHandler();
