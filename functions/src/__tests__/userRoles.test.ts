import { describe, expect, it } from "vitest";

import {
  hasAnyUserRole,
  hasUserRole,
  isSuperAdminUser,
  planRoleChange,
  resolveUserRoles,
} from "../auth/userRoles";
import { authorizePaymentReviewer } from "../services/mobileMoneyCallables";
import { audienceAllows, staffCanWrite } from "../services/contentAudience";
import { authorizeClassAdmin } from "../services/classManagementCallable";

describe("resolveUserRoles", () => {
  it("reads a legacy single-role account exactly as before", () => {
    expect([...resolveUserRoles({ role: "parent" })]).toEqual(["parent"]);
    expect([...resolveUserRoles({ role: "teacher" })]).toEqual(["teacher"]);
  });

  it("adds the additive spaces of a parent + teacher", () => {
    const user = { role: "teacher", roles: ["teacher", "parent"] };
    expect(resolveUserRoles(user)).toEqual(new Set(["teacher", "parent"]));
    expect(hasUserRole(user, "parent")).toBe(true);
    expect(hasUserRole(user, "teacher")).toBe(true);
    expect(hasUserRole(user, "admin")).toBe(false);
  });

  it("keeps a student exclusive even if roles[] says otherwise", () => {
    const user = { role: "student", roles: ["student", "teacher", "parent"] };
    expect([...resolveUserRoles(user)]).toEqual(["student"]);
    expect(hasAnyUserRole(user, ["teacher", "parent", "admin"])).toBe(false);
  });

  it("never makes anyone a student or a super-admin through roles[]", () => {
    const user = { role: "parent", roles: ["parent", "student", "superAdmin", "super_admin"] };
    expect(resolveUserRoles(user)).toEqual(new Set(["parent"]));
    expect(isSuperAdminUser(user)).toBe(false);
    expect(isSuperAdminUser({ role: "super_admin" })).toBe(true);
    expect(isSuperAdminUser({ role: "superAdmin" })).toBe(true);
  });

  it("ignores malformed data", () => {
    expect(resolveUserRoles(undefined).size).toBe(0);
    expect(resolveUserRoles({ role: 3, roles: "parent" }).size).toBe(0);
    expect(hasUserRole(null, "parent")).toBe(false);
  });
});

describe("planRoleChange (grant / revocation policy)", () => {
  it("grants a second space and writes both fields coherently", () => {
    expect(planRoleChange({ role: "teacher" }, { action: "grant", role: "parent" })).toEqual({
      ok: true,
      role: "teacher",
      roles: ["teacher", "parent"],
    });
  });

  it("revoking a secondary space keeps the primary and drops roles[] when one remains", () => {
    expect(
      planRoleChange({ role: "teacher", roles: ["teacher", "parent"] }, { action: "revoke", role: "parent" }),
    ).toEqual({ ok: true, role: "teacher", roles: null });
  });

  it("revoking the primary space promotes the next one so old apps never open it", () => {
    expect(
      planRoleChange({ role: "teacher", roles: ["teacher", "parent"] }, { action: "revoke", role: "teacher" }),
    ).toEqual({ ok: true, role: "parent", roles: null });
    expect(
      planRoleChange(
        { role: "parent", roles: ["parent", "teacher", "admin"] },
        { action: "revoke", role: "parent" },
      ),
    ).toEqual({ ok: true, role: "admin", roles: ["admin", "teacher"] });
  });

  it("refuses to remove the last space (suspend the account instead)", () => {
    expect(planRoleChange({ role: "parent" }, { action: "revoke", role: "parent" })).toEqual({
      ok: false,
      reason: "last-role",
    });
  });

  it("refuses student and super-admin changes", () => {
    expect(planRoleChange({ role: "student" }, { action: "grant", role: "parent" })).toMatchObject({
      ok: false,
      reason: "student-exclusive",
    });
    expect(planRoleChange({ role: "parent" }, { action: "grant", role: "student" })).toMatchObject({
      ok: false,
      reason: "student-exclusive",
    });
    expect(planRoleChange({ role: "superAdmin" }, { action: "grant", role: "parent" })).toMatchObject({
      ok: false,
      reason: "super-admin",
    });
    expect(planRoleChange({ role: "parent" }, { action: "grant", role: "superAdmin" })).toMatchObject({
      ok: false,
      reason: "unknown-role",
    });
  });

  it("reports no-op changes", () => {
    expect(planRoleChange({ role: "parent" }, { action: "grant", role: "parent" })).toMatchObject({
      ok: false,
      reason: "unchanged",
    });
  });
});

describe("security-critical checks honour roles[]", () => {
  it("a parent + school admin reviews payments of their school", () => {
    expect(
      authorizePaymentReviewer({
        role: "parent",
        roles: ["parent", "admin"],
        establishmentId: "school-a",
        accountStatus: "active",
      }),
    ).toEqual({ unrestricted: false, establishmentId: "school-a" });
    expect(() => authorizePaymentReviewer({ role: "parent", establishmentId: "school-a" })).toThrow();
  });

  it("a teacher whose primary role is parent can author and read staff content", () => {
    const user = { role: "parent", roles: ["parent", "teacher"], establishmentId: "school-a", accountStatus: "active" };
    expect(staffCanWrite(user, { establishmentId: "school-a" })).toBe(true);
    expect(staffCanWrite({ role: "parent", establishmentId: "school-a" }, { establishmentId: "school-a" })).toBe(false);
    expect(audienceAllows({ establishmentId: "school-a" }, user)).toBe(true);
  });

  it("a school admin space granted through roles[] manages only its school's classes", () => {
    const user = { role: "teacher", roles: ["teacher", "admin"], establishmentId: "school-a" };
    expect(() => authorizeClassAdmin(user, "school-a")).not.toThrow();
    expect(() => authorizeClassAdmin(user, "school-b")).toThrow();
    expect(() => authorizeClassAdmin({ role: "teacher", establishmentId: "school-a" }, "school-a")).toThrow();
  });

  it("revocation: once the parent space is removed, parent-only checks refuse", () => {
    const before = { role: "teacher", roles: ["teacher", "parent"] };
    const plan = planRoleChange(before, { action: "revoke", role: "parent" });
    expect(plan.ok).toBe(true);
    const after = plan.ok ? { role: plan.role, ...(plan.roles ? { roles: plan.roles } : {}) } : before;
    expect(hasUserRole(before, "parent")).toBe(true);
    expect(hasUserRole(after, "parent")).toBe(false);
    expect(hasUserRole(after, "teacher")).toBe(true);
  });
});
