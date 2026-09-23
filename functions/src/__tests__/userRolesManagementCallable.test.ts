import { HttpsError } from "firebase-functions/v2/https";
import { describe, expect, it } from "vitest";

import { decideRoleChange, manageUserRolesInput } from "../services/userRolesManagementCallable";

const root = { role: "superAdmin", accountStatus: "active" };

function decide(
  target: Record<string, unknown> | undefined,
  input: { action: "grant" | "revoke"; role: "parent" | "teacher" | "admin" },
  actor: Record<string, unknown> | undefined = root,
  actorId = "root",
) {
  return decideRoleChange({
    actorId,
    actor,
    target,
    input: { accountId: "target", reason: "Owner request", ...input },
  });
}

function refusal(action: () => unknown): HttpsError {
  try {
    action();
  } catch (error) {
    expect(error).toBeInstanceOf(HttpsError);
    return error as HttpsError;
  }
  throw new Error("expected a refusal");
}

describe("manageUserRoles decisions", () => {
  it("lets only an active general administration change spaces", () => {
    expect(refusal(() => decide({ role: "teacher" }, { action: "grant", role: "parent" }, { role: "admin" })).code)
      .toBe("permission-denied");
    expect(refusal(() => decide({ role: "teacher" }, { action: "grant", role: "parent" }, { role: "teacher", roles: ["teacher", "admin"] })).code)
      .toBe("permission-denied");
    expect(refusal(() => decide({ role: "teacher" }, { action: "grant", role: "parent" }, { role: "superAdmin", accountStatus: "suspended" })).code)
      .toBe("permission-denied");
  });

  it("never lets an account change its own spaces", () => {
    expect(refusal(() => decide({ role: "superAdmin" }, { action: "grant", role: "parent" }, root, "target")).code)
      .toBe("permission-denied");
  });

  it("grants parent to a teacher and writes both fields", () => {
    expect(decide({ role: "teacher" }, { action: "grant", role: "parent" })).toEqual({
      role: "teacher",
      roles: ["teacher", "parent"],
      unchanged: false,
    });
  });

  it("revokes the last additive space and clears roles[]", () => {
    expect(decide({ role: "teacher", roles: ["teacher", "parent"] }, { action: "revoke", role: "parent" }))
      .toEqual({ role: "teacher", roles: null, unchanged: false });
  });

  it("refuses to remove the last space and to touch a student", () => {
    expect(refusal(() => decide({ role: "parent" }, { action: "revoke", role: "parent" })).code)
      .toBe("failed-precondition");
    expect(refusal(() => decide({ role: "student" }, { action: "grant", role: "parent" })).code)
      .toBe("failed-precondition");
  });

  it("requires a school for a school administrator", () => {
    expect(refusal(() => decide({ role: "teacher" }, { action: "grant", role: "admin" })).code)
      .toBe("failed-precondition");
    expect(decide({ role: "teacher", establishmentId: "school-a" }, { action: "grant", role: "admin" }))
      .toMatchObject({ role: "teacher", roles: ["teacher", "admin"] });
  });

  it("is idempotent on replay", () => {
    expect(decide({ role: "teacher", roles: ["teacher", "parent"] }, { action: "grant", role: "parent" }))
      .toEqual({ role: "teacher", roles: ["teacher", "parent"], unchanged: true });
  });

  it("rejects student and super-admin in the payload itself", () => {
    const base = { accountId: "target", action: "grant", reason: "Owner request" };
    expect(manageUserRolesInput.safeParse({ ...base, role: "student" }).success).toBe(false);
    expect(manageUserRolesInput.safeParse({ ...base, role: "superAdmin" }).success).toBe(false);
  });
});
