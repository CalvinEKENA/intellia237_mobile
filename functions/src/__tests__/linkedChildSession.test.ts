import { describe, expect, it, vi } from "vitest";
import type { CallableRequest } from "firebase-functions/v2/https";
import { createOpenLinkedChildSessionHandler } from "../services/linkedChildSession";

const now = 1_800_000_000_000;
function fixture() {
  const parent = { role: "parent", accountStatus: "active", establishmentId: "" };
  const child = { role: "student", accountStatus: "active", establishmentId: "school" };
  const store = {
    readAccount: vi.fn(async (uid: string) => uid === "parent" ? parent : child),
    isLinkedParent: vi.fn(async () => true),
  };
  const issuer = { createCustomToken: vi.fn(async () => "test-only-token") };
  const request = {
    auth: { uid: "parent", token: { auth_time: now / 1000 - 10, firebase: { sign_in_provider: "phone" } } },
    data: { studentId: "child" },
  };
  const handler = createOpenLinkedChildSessionHandler(store, issuer, () => now);
  return { store, issuer, request, parent, child, run: () => handler(request as unknown as CallableRequest<unknown>) };
}

describe("family identity to isolated child session", () => {
  it("issues only the existing child UID, without parent claims", async () => {
    const f = fixture(); await f.run();
    expect(f.issuer.createCustomToken).toHaveBeenCalledExactlyOnceWith("child");
    expect(f.store.isLinkedParent).toHaveBeenCalledWith("parent", "child");
  });
  it.each(["phone", "password", "google.com"])("accepts a fresh %s parent proof", async (provider) => {
    const f = fixture(); f.request.auth.token.firebase.sign_in_provider = provider;
    await expect(f.run()).resolves.toEqual({ token: "test-only-token" });
  });
  it.each(["student", "teacher", "admin", "superAdmin"])("rejects %s without parent authorization", async (role) => {
    const f = fixture(); f.parent.role = role;
    await expect(f.run()).rejects.toMatchObject({ code: "permission-denied" });
    expect(f.issuer.createCustomToken).not.toHaveBeenCalled();
  });
  it("rejects an unrelated child", async () => {
    const f = fixture(); f.store.isLinkedParent.mockResolvedValue(false);
    await expect(f.run()).rejects.toMatchObject({ code: "permission-denied" });
    expect(f.issuer.createCustomToken).not.toHaveBeenCalled();
  });
  it.each(["suspended", "deleted", "pending_validation"])("rejects inactive child %s", async (status) => {
    const f = fixture(); f.child.accountStatus = status;
    await expect(f.run()).rejects.toMatchObject({ code: "permission-denied" });
  });
  it("rejects a suspended parent", async () => {
    const f = fixture(); f.parent.accountStatus = "suspended";
    await expect(f.run()).rejects.toMatchObject({ code: "permission-denied" });
  });
  it("rejects a link pointing to a staff account", async () => {
    const f = fixture(); f.child.role = "admin";
    await expect(f.run()).rejects.toMatchObject({ code: "permission-denied" });
  });
  it.each([301, -1, NaN])("rejects invalid proof age %s", async (age) => {
    const f = fixture(); f.request.auth.token.auth_time = now / 1000 - age;
    await expect(f.run()).rejects.toMatchObject({ code: "failed-precondition" });
    expect(f.issuer.createCustomToken).not.toHaveBeenCalled();
  });
  it("cannot reuse a student custom-token session as parent proof", async () => {
    const f = fixture(); f.request.auth.token.firebase.sign_in_provider = "custom";
    await expect(f.run()).rejects.toMatchObject({ code: "failed-precondition" });
  });
  it("rejects caller-supplied parent identity", async () => {
    const f = fixture(); Object.assign(f.request.data, { parentUid: "someone-else" });
    await expect(f.run()).rejects.toMatchObject({ code: "invalid-argument" });
  });
});
