import { initializeApp, deleteApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import type { Auth } from "firebase-admin/auth";
import { afterAll, beforeEach, describe, expect, it } from "vitest";
import { AdminAccountManagementStore } from "../../services/adminAccountManagementCallable";

if (!process.env.FIRESTORE_EMULATOR_HOST) throw new Error("This test requires the Firestore emulator.");
const app = initializeApp({projectId: "demo-intellia237"}, "admin-management-tests");
const firestore = getFirestore(app);
const users = new Map<string, Record<string, unknown>>();
const revoked = new Set<string>();
const auth = {
  async createUser(data: Record<string, unknown>) {
    const uid = data.uid as string;
    if (users.has(uid)) throw {code: "auth/uid-already-exists"};
    users.set(uid, {...data});
    return data;
  },
  async getUser(uid: string) { return users.get(uid); },
  async updateUser(uid: string, data: Record<string, unknown>) {
    if (!users.has(uid)) throw {code: "auth/user-not-found"};
    users.set(uid, {...users.get(uid), ...data});
  },
  async revokeRefreshTokens(uid: string) { revoked.add(uid); },
} as unknown as Auth;
const store = new AdminAccountManagementStore(firestore, auth);

beforeEach(async () => {
  users.clear(); revoked.clear();
  await Promise.all(["users", "establishments", "account_management_audit"].map(
    collection => firestore.recursiveDelete(firestore.collection(collection))));
  await firestore.doc("users/root").set({role: "superAdmin", accountStatus: "active"});
  await firestore.doc("users/head").set({role: "admin", establishmentId: "school", accountStatus: "active"});
  await firestore.doc("establishments/school").set({name: "School"});
});
afterAll(async () => { await firestore.terminate(); await deleteApp(app); });

const creation = {
  action: "createStudent" as const, requestId: "0a2b3000-0000-4000-8000-000000000001",
  firstName: "Student", lastName: "Test", phoneNumber: "+237699123456", establishmentId: "school",
};

describe("admin account management with transactional Firestore", () => {
  it("creates exactly one student on replay, ready to complete their own profile", async () => {
    const first = await store.execute("root", creation);
    const second = await store.execute("root", creation);
    expect(second).toEqual(first);
    expect(users.size).toBe(1);
    expect(users.get(first.accountId)?.disabled).toBe(false);
    expect((await firestore.doc(`users/${first.accountId}`).get()).data())
      .toMatchObject({role: "student", establishmentId: "school", profileCompleted: false});
    expect((await firestore.collection("account_management_audit").get()).size).toBe(1);
  });
  it("rejects a school head before any account is provisioned", async () => {
    await expect(store.execute("head", creation)).rejects.toMatchObject({code: "permission-denied"});
    expect(users.size).toBe(0);
  });
  it("suspends, deletes and restores with matching Auth and audited Firestore status", async () => {
    users.set("head", {uid: "head", disabled: false});
    for (const [action, status] of [["suspend", "suspended"], ["delete", "deleted"],
      ["restore", "suspended"], ["reactivate", "active"]] as const) {
      const result = await store.execute("root", {action, accountId: "head", reason: "Test decision"});
      expect(result.status).toBe(status);
      expect((await firestore.doc("users/head").get()).data()?.accountStatus).toBe(status);
      expect(users.get("head")?.disabled).toBe(status !== "active");
    }
    expect(revoked.has("head")).toBe(true);
    expect((await firestore.collection("account_management_audit").get()).size).toBe(4);
  });
});
