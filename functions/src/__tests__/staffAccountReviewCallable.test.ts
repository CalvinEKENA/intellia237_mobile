import { describe, expect, it } from "vitest";

import {
  authorizeStaffReview,
  buildStaffReviewPatches,
  createReviewStaffAccountHandler,
  type StaffAccountReviewResult,
  type StaffAccountReviewStore,
} from "../services/staffAccountReviewCallable";
import type { StaffAccountReviewCallableInput } from "../utils/validation";

describe("reviewStaffAccount", () => {
  it("rejects unauthenticated callers", async () => {
    const handler = createReviewStaffAccountHandler(new MemoryReviewStore());

    await expect(handler({
      data: { reviewId: "teacher-a", approved: true },
    } as never)).rejects.toMatchObject({ code: "unauthenticated" });
  });

  it("rejects payload fields that could request an implicit elevation", async () => {
    const handler = createReviewStaffAccountHandler(new MemoryReviewStore());

    await expect(handler({
      auth: { uid: "admin-a", token: {} },
      data: {
        reviewId: "teacher-a",
        approved: true,
        role: "superAdmin",
        establishmentId: "school-b",
      },
    } as never)).rejects.toMatchObject({ code: "invalid-argument" });
  });

  it("authorizes an active school admin only inside the same establishment", () => {
    expect(authorizeStaffReview({
      reviewerId: "admin-a",
      targetId: "teacher-a",
      reviewerData: {
        role: "admin",
        accountStatus: "active",
        establishmentId: "school-a",
      },
      targetData: {
        role: "teacher",
        accountStatus: "pending_validation",
        establishmentId: "school-a",
      },
    })).toMatchObject({
      reviewerRole: "admin",
      targetRole: "teacher",
      establishmentId: "school-a",
    });

    expect(() => authorizeStaffReview({
      reviewerId: "admin-a",
      targetId: "teacher-b",
      reviewerData: {
        role: "admin",
        accountStatus: "active",
        establishmentId: "school-a",
      },
      targetData: {
        role: "teacher",
        accountStatus: "pending_validation",
        establishmentId: "school-b",
      },
    })).toThrowError(expect.objectContaining({ code: "permission-denied" }));
  });

  it("rejects inactive reviewers, self-review and non-staff targets", () => {
    const target = {
      role: "teacher",
      accountStatus: "pending_validation",
      establishmentId: "school-a",
    };
    expect(() => authorizeStaffReview({
      reviewerId: "admin-a",
      targetId: "teacher-a",
      reviewerData: {
        role: "admin",
        accountStatus: "pending_validation",
        establishmentId: "school-a",
      },
      targetData: target,
    })).toThrowError(expect.objectContaining({ code: "permission-denied" }));

    expect(() => authorizeStaffReview({
      reviewerId: "admin-a",
      targetId: "admin-a",
      reviewerData: {
        role: "admin",
        accountStatus: "active",
        establishmentId: "school-a",
      },
      targetData: { ...target, role: "admin" },
    })).toThrowError(expect.objectContaining({ code: "permission-denied" }));

    expect(() => authorizeStaffReview({
      reviewerId: "admin-a",
      targetId: "student-a",
      reviewerData: {
        role: "admin",
        accountStatus: "active",
        establishmentId: "school-a",
      },
      targetData: { ...target, role: "student" },
    })).toThrowError(expect.objectContaining({ code: "failed-precondition" }));
  });

  it("lets the general administration review and attach a school across establishments", () => {
    const pendingAdmin = { role: "admin", accountStatus: "pending_validation" };

    expect(authorizeStaffReview({
      reviewerId: "root-a",
      targetId: "admin-b",
      reviewerData: { role: "super_admin", accountStatus: "active" },
      targetData: pendingAdmin,
      approved: true,
      requestedEstablishmentId: "school-b",
    })).toMatchObject({ establishmentId: "school-b", attachesEstablishment: true });

    expect(authorizeStaffReview({
      reviewerId: "root-a",
      targetId: "teacher-b",
      reviewerData: { role: "superAdmin", accountStatus: "active", establishmentId: "school-a" },
      targetData: { role: "teacher", accountStatus: "pending_validation", establishmentId: "school-b" },
      approved: true,
    })).toMatchObject({ establishmentId: "school-b", attachesEstablishment: false });

    expect(() => authorizeStaffReview({
      reviewerId: "root-a",
      targetId: "admin-b",
      reviewerData: { role: "superAdmin", accountStatus: "active" },
      targetData: pendingAdmin,
      approved: true,
    })).toThrowError(expect.objectContaining({ code: "failed-precondition" }));

    expect(authorizeStaffReview({
      reviewerId: "root-a",
      targetId: "admin-b",
      reviewerData: { role: "superAdmin", accountStatus: "active" },
      targetData: pendingAdmin,
      approved: false,
    })).toMatchObject({ attachesEstablishment: false });
  });

  it("never lets a review move an account to another school", () => {
    expect(() => authorizeStaffReview({
      reviewerId: "root-a",
      targetId: "teacher-b",
      reviewerData: { role: "superAdmin", accountStatus: "active" },
      targetData: { role: "teacher", accountStatus: "pending_validation", establishmentId: "school-b" },
      approved: true,
      requestedEstablishmentId: "school-a",
    })).toThrowError(expect.objectContaining({ code: "failed-precondition" }));
  });

  it("confines a school administrator to the teachers of their own school", () => {
    const schoolAdmin = { role: "admin", accountStatus: "active", establishmentId: "school-a" };

    expect(() => authorizeStaffReview({
      reviewerId: "admin-a",
      targetId: "admin-a2",
      reviewerData: schoolAdmin,
      targetData: { role: "admin", accountStatus: "pending_validation", establishmentId: "school-a" },
    })).toThrowError(expect.objectContaining({ code: "permission-denied" }));

    expect(() => authorizeStaffReview({
      reviewerId: "admin-a",
      targetId: "teacher-a",
      reviewerData: schoolAdmin,
      targetData: { role: "teacher", accountStatus: "pending_validation" },
      requestedEstablishmentId: "school-a",
    })).toThrowError(expect.objectContaining({ code: "permission-denied" }));
  });

  it("updates review state without mutating role, permissions or claims", () => {
    const patches = buildStaffReviewPatches({ reviewerId: "admin-a", approved: true });
    expect(patches.userPatch).toMatchObject({
      accountStatus: "active",
      requiresValidation: false,
      reviewedBy: "admin-a",
    });
    expect(patches.profilePatch).toMatchObject({
      validation: { status: "approved", required: false, reviewedBy: "admin-a" },
    });
    for (const forbidden of ["role", "establishmentId", "permissions", "claims"]) {
      expect(patches.userPatch).not.toHaveProperty(forbidden);
      expect(patches.profilePatch).not.toHaveProperty(forbidden);
    }
  });

  it("carries a school only when the general administration attaches one", () => {
    const attached = buildStaffReviewPatches({
      reviewerId: "root-a",
      approved: true,
      attachEstablishmentId: "school-b",
    });
    expect(attached.userPatch).toMatchObject({ establishmentId: "school-b" });
    expect(attached.profilePatch).toMatchObject({ establishmentId: "school-b" });
    for (const forbidden of ["role", "permissions", "claims"]) {
      expect(attached.userPatch).not.toHaveProperty(forbidden);
    }

    const rejected = buildStaffReviewPatches({
      reviewerId: "root-a",
      approved: false,
      attachEstablishmentId: "school-b",
    });
    expect(rejected.userPatch).not.toHaveProperty("establishmentId");
  });
});

class MemoryReviewStore implements StaffAccountReviewStore {
  async reviewStaffAccount(
    _reviewerId: string,
    input: StaffAccountReviewCallableInput,
  ): Promise<StaffAccountReviewResult> {
    return {
      reviewId: input.reviewId,
      role: "teacher",
      establishmentId: "school-a",
      status: input.approved ? "approved" : "rejected",
      idempotentReplay: false,
    };
  }
}
