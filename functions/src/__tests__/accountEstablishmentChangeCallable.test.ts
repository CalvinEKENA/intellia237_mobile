import { describe, expect, it } from "vitest";

import {
  authorizeAccountEstablishmentChange,
  buildAccountEstablishmentPatches,
  createChangeAccountEstablishmentHandler,
  planClassDepartures,
  type AccountEstablishmentChangeResult,
  type AccountEstablishmentChangeStore,
} from "../services/accountEstablishmentChangeCallable";
import type { AccountEstablishmentChangeInput } from "../utils/validation";

const root = { role: "superAdmin", accountStatus: "active" };

function authorize(overrides: {
  changerId?: string;
  accountId?: string;
  changerData?: Record<string, unknown>;
  targetData?: Record<string, unknown>;
  establishmentId?: string;
  reason?: string;
}) {
  return authorizeAccountEstablishmentChange({
    changerId: "root-a",
    accountId: "student-a",
    changerData: root,
    targetData: { role: "student" },
    establishmentId: "school-a",
    ...overrides,
  });
}

describe("changeAccountEstablishment", () => {
  it("rejects unauthenticated callers", async () => {
    const handler = createChangeAccountEstablishmentHandler(new MemoryChangeStore());

    await expect(handler({
      data: { accountId: "student-a", establishmentId: "school-a" },
    } as never)).rejects.toMatchObject({ code: "unauthenticated" });
  });

  it("rejects payload fields that could request an elevation", async () => {
    const handler = createChangeAccountEstablishmentHandler(new MemoryChangeStore());

    await expect(handler({
      auth: { uid: "root-a", token: {} },
      data: { accountId: "student-a", establishmentId: "school-a", role: "admin" },
    } as never)).rejects.toMatchObject({ code: "invalid-argument" });
  });

  it("attaches a pupil, a parent or staff without a school, no reason needed", () => {
    expect(authorize({})).toEqual({
      role: "student",
      fromEstablishmentId: null,
      idempotentReplay: false,
    });
    expect(authorize({ accountId: "parent-a", targetData: { role: "parent" } }))
      .toMatchObject({ role: "parent", idempotentReplay: false });
    // Staff accounts created before statuses existed carry none.
    expect(authorize({ accountId: "teacher-a", targetData: { role: "teacher" } }))
      .toMatchObject({ role: "teacher", idempotentReplay: false });
  });

  it("moves an account whose school was wrong, with a reason kept for audit", () => {
    expect(() => authorize({ targetData: { role: "student", establishmentId: "school-b" } }))
      .toThrowError(expect.objectContaining({ code: "failed-precondition" }));

    expect(authorize({
      targetData: { role: "student", establishmentId: "school-b" },
      reason: "Erreur du parent à l'inscription",
    })).toEqual({
      role: "student",
      fromEstablishmentId: "school-b",
      idempotentReplay: false,
    });
  });

  it("replays a change to the same school without rewriting it", () => {
    expect(authorize({ targetData: { role: "admin", establishmentId: "school-a" } }))
      .toMatchObject({ idempotentReplay: true });
  });

  it("reserves the change to the active general administration", () => {
    for (const changerData of [
      { role: "admin", accountStatus: "active", establishmentId: "school-a" },
      { role: "teacher", accountStatus: "active", establishmentId: "school-a" },
      { role: "parent" },
      { role: "superAdmin", accountStatus: "disabled" },
    ]) {
      expect(() => authorize({ changerData }))
        .toThrowError(expect.objectContaining({ code: "permission-denied" }));
    }
    expect(() => authorize({ accountId: "root-a", targetData: { role: "student" } }))
      .toThrowError(expect.objectContaining({ code: "permission-denied" }));
  });

  it("leaves pending staff to approval and refuses accounts without a school role", () => {
    for (const targetData of [
      { role: "teacher", accountStatus: "pending_validation" },
      { role: "admin", accountStatus: "rejected" },
      { role: "superAdmin" },
      { role: "" },
    ]) {
      expect(() => authorize({ targetData }))
        .toThrowError(expect.objectContaining({ code: "failed-precondition" }));
    }
  });

  it("takes a moving pupil off the rosters of its former school only", () => {
    expect(planClassDepartures({
      role: "student",
      accountId: "student-a",
      destinationEstablishmentId: "school-a",
      classes: [
        { id: "old", data: { establishmentId: "school-b", studentIds: ["student-a", "x"], studentCount: 2 } },
        { id: "new", data: { establishmentId: "school-a", studentIds: ["student-a"] } },
      ],
    })).toEqual([
      {
        classId: "old",
        removeStudent: true,
        removeTeacher: false,
        clearMainTeacher: false,
        studentCount: 1,
      },
    ]);
  });

  it("frees a moving teacher's seats in the former school", () => {
    expect(planClassDepartures({
      role: "teacher",
      accountId: "teacher-a",
      destinationEstablishmentId: "school-a",
      classes: [
        { id: "taught", data: { establishmentId: "school-b", teacherIds: ["teacher-a"] } },
        { id: "led", data: { establishmentId: "school-b", mainTeacherId: "teacher-a", teacherIds: [] } },
      ],
    })).toEqual([
      { classId: "taught", removeStudent: false, removeTeacher: true, clearMainTeacher: false },
      { classId: "led", removeStudent: false, removeTeacher: false, clearMainTeacher: true },
    ]);
  });

  it("writes the school alone, never a role, status, permission or claim", () => {
    const pupil = buildAccountEstablishmentPatches({
      changerId: "root-a",
      role: "student",
      establishmentId: "school-a",
      establishmentName: "Lycée A",
    });
    expect(pupil.userPatch).toMatchObject({
      establishmentId: "school-a",
      establishmentAssignedBy: "root-a",
    });
    expect(pupil.profilePatch).toMatchObject({
      establishmentId: "school-a",
      establishmentName: "Lycée A",
    });

    const teacher = buildAccountEstablishmentPatches({
      changerId: "root-a",
      role: "teacher",
      establishmentId: "school-a",
      establishmentName: "Lycée A",
    });
    expect(teacher.profilePatch).not.toHaveProperty("establishmentName");

    for (const patch of [pupil.userPatch, pupil.profilePatch, teacher.userPatch]) {
      for (const forbidden of ["role", "accountStatus", "permissions", "claims"]) {
        expect(patch).not.toHaveProperty(forbidden);
      }
    }
  });
});

class MemoryChangeStore implements AccountEstablishmentChangeStore {
  async changeAccountEstablishment(
    _changerId: string,
    input: AccountEstablishmentChangeInput,
  ): Promise<AccountEstablishmentChangeResult> {
    return {
      accountId: input.accountId,
      role: "student",
      fromEstablishmentId: null,
      establishmentId: input.establishmentId,
      leftClassIds: [],
      idempotentReplay: false,
    };
  }
}
