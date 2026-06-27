import { describe, expect, it } from "vitest";

import {
  buildStaffRegistrationDocuments,
  createSubmitStaffRegistrationHandler,
  type StaffRegistrationResult,
  type StaffRegistrationStore,
} from "../services/staffRegistrationCallable";
import type { StaffRegistrationCallableInput } from "../utils/validation";

describe("submitStaffRegistration", () => {
  it("rejects unauthenticated callers", async () => {
    const handler = createSubmitStaffRegistrationHandler(
      new MemoryStaffStore(),
    );

    await expect(
      handler({
        data: validTeacherPayload(),
      } as never),
    ).rejects.toMatchObject({
      code: "unauthenticated",
    });
  });

  it("rejects malformed payloads", async () => {
    const handler = createSubmitStaffRegistrationHandler(
      new MemoryStaffStore(),
    );

    await expect(
      handler({
        auth: { uid: "teacher-a", token: { email: "teacher@example.com" } },
        data: {
          ...validTeacherPayload(),
          acceptedTerms: false,
        },
      } as never),
    ).rejects.toMatchObject({
      code: "invalid-argument",
    });
  });

  it("rejects an authenticated email mismatch", async () => {
    const handler = createSubmitStaffRegistrationHandler(
      new MemoryStaffStore(),
    );

    await expect(
      handler({
        auth: { uid: "teacher-a", token: { email: "other@example.com" } },
        data: validTeacherPayload(),
      } as never),
    ).rejects.toMatchObject({
      code: "permission-denied",
    });
  });

  it("creates a pending teacher profile document", () => {
    const now = new Date("2026-06-26T10:00:00.000Z");
    const documents = buildStaffRegistrationDocuments({
      uid: "teacher-a",
      input: validTeacherPayload(),
      now,
    });

    expect(documents.profileCollection).toBe("teacher_profiles");
    expect(documents.userDocument).toMatchObject({
      role: "teacher",
      accountStatus: "pending_validation",
      requiresValidation: true,
    });
    expect(documents.userDocument).not.toHaveProperty("establishmentId");
    expect(documents.profileDocument).toMatchObject({
      subjects: ["Mathematiques"],
      levels: ["Terminale"],
      validation: {
        status: "pending",
        required: true,
      },
    });
    expect(documents.profileDocument).not.toHaveProperty("establishmentId");
    expect(documents.profileDocument).not.toHaveProperty("establishmentName");
  });

  it("creates a pending admin profile document without elevated permissions", () => {
    const now = new Date("2026-06-26T10:00:00.000Z");
    const documents = buildStaffRegistrationDocuments({
      uid: "admin-a",
      input: validAdminPayload(),
      now,
    });

    expect(documents.profileCollection).toBe("admin_profiles");
    expect(documents.userDocument).toMatchObject({
      role: "admin",
      accountStatus: "pending_validation",
      requiresValidation: true,
      jobTitle: "Proviseur",
    });
    expect(documents.profileDocument).toMatchObject({
      permissions: {
        canManageTeachers: false,
        canManageStudents: false,
        canViewFinance: false,
      },
    });
    expect(documents.userDocument).not.toHaveProperty("establishmentId");
    expect(documents.profileDocument).not.toHaveProperty("establishmentId");
    expect(documents.profileDocument).not.toHaveProperty("establishmentName");
  });
});

function validTeacherPayload(): StaffRegistrationCallableInput {
  return {
    role: "teacher",
    firstName: "Serge",
    lastName: "Mbarga",
    email: "teacher@example.com",
    subjects: ["Mathematiques"],
    levels: ["Terminale"],
    acceptedTerms: true,
    acceptedPrivacy: true,
  };
}

function validAdminPayload(): StaffRegistrationCallableInput {
  return {
    role: "admin",
    firstName: "Nadine",
    lastName: "Meka",
    email: "admin@example.com",
    jobTitle: "Proviseur",
    acceptedTerms: true,
    acceptedPrivacy: true,
  };
}

class MemoryStaffStore implements StaffRegistrationStore {
  async saveStaffRegistration(
    uid: string,
    input: StaffRegistrationCallableInput,
  ): Promise<StaffRegistrationResult> {
    return {
      uid,
      email: input.email,
      firstName: input.firstName,
      lastName: input.lastName,
      role: input.role,
      accountStatus: "pending_validation",
    };
  }
}
