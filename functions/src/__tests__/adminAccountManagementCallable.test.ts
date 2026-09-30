import { describe, expect, it } from "vitest";
import { accountManagementInput, requireGeneralAdministrator, nextAccountStatus,
  createManageAccountHandler, AdminAccountManagementStore,
} from "../services/adminAccountManagementCallable";
import { assertAccountAccess } from "../services/callableAccountAccess";

describe("general administration account lifecycle", () => {
  it("accepts both owner role forms without requiring a school", () => {
    for (const role of ["superAdmin", "super_admin"]) {
      expect(() => requireGeneralAdministrator({role, accountStatus: "active"})).not.toThrow();
    }
  });
  it("denies school heads, teachers, disabled owners, and email impersonation", () => {
    for (const data of [undefined, {role: "admin"}, {role: "teacher"},
      {email: "calvinekena1@gmail.com", role: "student"},
      {role: "superAdmin", accountStatus: "suspended"}]) {
      expect(() => requireGeneralAdministrator(data)).toThrow();
    }
  });
  it("never promotes an account through a management payload", () => {
    expect(() => accountManagementInput.parse({action: "reactivate", accountId: "head",
      reason: "Reviewed", role: "superAdmin"})).toThrow();
  });
  it("suspends and deletes every ordinary profile role", () => {
    for (const role of ["student", "parent", "teacher", "admin"]) {
      expect(nextAccountStatus({action: "suspend", accountId: "other", reason: "Reviewed"},
        "root", {role, accountStatus: "active"})).toBe("suspended");
      expect(nextAccountStatus({action: "delete", accountId: "other", reason: "Reviewed"},
        "root", {role, accountStatus: "active"})).toBe("deleted");
    }
  });
  it("restoration preserves previous restrictions instead of approving pending staff", () => {
    expect(nextAccountStatus({action: "restore", accountId: "head", reason: "Mistake"},
      "root", {role: "admin", accountStatus: "deleted", statusBeforeDeletion: "pending_validation"}))
      .toBe("pending_validation");
    expect(() => nextAccountStatus({action: "reactivate", accountId: "head", reason: "Mistake"},
      "root", {role: "admin", accountStatus: "pending_validation"})).toThrow();
  });
  it("does not let lifecycle commands erase the owner's own access", () => {
    expect(() => nextAccountStatus({action: "delete", accountId: "root", reason: "Delete"},
      "root", {role: "superAdmin"})).toThrow();
  });
  it("retries a restore when Auth synchronization failed after the profile commit", () => {
    expect(nextAccountStatus({action: "restore", accountId: "head", reason: "Mistake"},
      "root", {role: "admin", accountStatus: "active", lastAccountAction: "restore"}))
      .toBe("active");
  });
  it("rejects unauthenticated callable requests before any storage call", async () => {
    let touched = false;
    const store = {execute: async () => { touched = true; }} as unknown as AdminAccountManagementStore;
    const handler = createManageAccountHandler(store);
    await expect(handler({data: {}} as never)).rejects.toMatchObject({code: "unauthenticated"});
    expect(touched).toBe(false);
  });
  it("validates provisioned phone numbers and requires an existing school identifier", () => {
    expect(() => accountManagementInput.parse({action: "createStudent",
      requestId: "0a2b3000-0000-4000-8000-000000000001", firstName: "A", lastName: "B",
      phoneNumber: "+237699123456", establishmentId: "school-a"})).not.toThrow();
    expect(() => accountManagementInput.parse({action: "createStudent",
      requestId: "0a2b3000-0000-4000-8000-000000000001", firstName: "A", lastName: "B",
      phoneNumber: "invalid", establishmentId: "school-a"})).toThrow();
    // Un élève sans téléphone est un cas nominal : il entrera par code d'accès.
    expect(() => accountManagementInput.parse({action: "createStudent",
      requestId: "0a2b3000-0000-4000-8000-000000000001", firstName: "A", lastName: "B",
      establishmentId: "school-a"})).not.toThrow();
  });
  it("rejects still-valid tokens for disabled accounts but allows registration without a profile", () => {
    for (const status of ["suspended", "deleted"]) {
      expect(() => assertAccountAccess(status)).toThrow();
    }
    for (const status of [undefined, "active", "pending_validation"]) {
      expect(() => assertAccountAccess(status)).not.toThrow();
    }
  });
});
