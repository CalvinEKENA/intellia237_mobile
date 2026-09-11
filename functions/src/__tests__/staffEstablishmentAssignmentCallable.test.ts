import { describe, expect, it } from "vitest";

import {
  authorizeStaffEstablishmentAssignment,
  buildStaffEstablishmentPatches,
  createAssignStaffEstablishmentHandler,
  type StaffEstablishmentAssignmentResult,
  type StaffEstablishmentAssignmentStore,
} from "../services/staffEstablishmentAssignmentCallable";
import type { StaffEstablishmentAssignmentInput } from "../utils/validation";

const root = { role: "superAdmin", accountStatus: "active" };
const approvedTeacher = { role: "teacher", accountStatus: "active" };

function authorize(overrides: {
  assignerId?: string;
  staffId?: string;
  assignerData?: Record<string, unknown>;
  targetData?: Record<string, unknown>;
  establishmentId?: string;
}) {
  return authorizeStaffEstablishmentAssignment({
    assignerId: "root-a",
    staffId: "teacher-a",
    assignerData: root,
    targetData: approvedTeacher,
    establishmentId: "school-a",
    ...overrides,
  });
}

describe("assignStaffEstablishment", () => {
  it("rejects unauthenticated callers", async () => {
    const handler = createAssignStaffEstablishmentHandler(new MemoryAssignmentStore());

    await expect(handler({
      data: { staffId: "teacher-a", establishmentId: "school-a" },
    } as never)).rejects.toMatchObject({ code: "unauthenticated" });
  });

  it("rejects payload fields that could request an elevation", async () => {
    const handler = createAssignStaffEstablishmentHandler(new MemoryAssignmentStore());

    await expect(handler({
      auth: { uid: "root-a", token: {} },
      data: { staffId: "teacher-a", establishmentId: "school-a", role: "admin" },
    } as never)).rejects.toMatchObject({ code: "invalid-argument" });
  });

  it("lets the general administration attach an approved account without a school", () => {
    expect(authorize({})).toEqual({ role: "teacher", idempotentReplay: false });
    // Staff accounts created before statuses existed carry none.
    expect(authorize({
      staffId: "admin-a",
      assignerData: { role: "super_admin" },
      targetData: { role: "admin" },
    })).toEqual({ role: "admin", idempotentReplay: false });
  });

  it("replays an assignment to the same school without rewriting it", () => {
    expect(authorize({
      targetData: { ...approvedTeacher, establishmentId: "school-a" },
    })).toEqual({ role: "teacher", idempotentReplay: true });
  });

  it("never moves an account to another school", () => {
    expect(() => authorize({
      targetData: { ...approvedTeacher, establishmentId: "school-b" },
    })).toThrowError(expect.objectContaining({ code: "failed-precondition" }));
  });

  it("reserves the assignment to the active general administration", () => {
    for (const assignerData of [
      { role: "admin", accountStatus: "active", establishmentId: "school-a" },
      { role: "teacher", accountStatus: "active", establishmentId: "school-a" },
      { role: "superAdmin", accountStatus: "disabled" },
    ]) {
      expect(() => authorize({ assignerData }))
        .toThrowError(expect.objectContaining({ code: "permission-denied" }));
    }
    expect(() => authorize({ staffId: "root-a" }))
      .toThrowError(expect.objectContaining({ code: "permission-denied" }));
  });

  it("leaves pending, rejected and non-staff accounts to their own flows", () => {
    for (const targetData of [
      { role: "teacher", accountStatus: "pending_validation" },
      { role: "teacher", accountStatus: "rejected" },
      { role: "student", accountStatus: "active" },
      { role: "superAdmin", accountStatus: "active" },
    ]) {
      expect(() => authorize({ targetData }))
        .toThrowError(expect.objectContaining({ code: "failed-precondition" }));
    }
  });

  it("writes the school alone, never a role, status, permission or claim", () => {
    const patches = buildStaffEstablishmentPatches({
      assignerId: "root-a",
      establishmentId: "school-a",
    });

    expect(patches.userPatch).toMatchObject({
      establishmentId: "school-a",
      establishmentAssignedBy: "root-a",
    });
    expect(patches.profilePatch).toMatchObject({ establishmentId: "school-a" });
    for (const forbidden of ["role", "accountStatus", "permissions", "claims"]) {
      expect(patches.userPatch).not.toHaveProperty(forbidden);
      expect(patches.profilePatch).not.toHaveProperty(forbidden);
    }
  });
});

class MemoryAssignmentStore implements StaffEstablishmentAssignmentStore {
  async assignStaffEstablishment(
    _assignerId: string,
    input: StaffEstablishmentAssignmentInput,
  ): Promise<StaffEstablishmentAssignmentResult> {
    return {
      staffId: input.staffId,
      role: "teacher",
      establishmentId: input.establishmentId,
      idempotentReplay: false,
    };
  }
}
