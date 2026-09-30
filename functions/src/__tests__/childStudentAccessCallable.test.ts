import { describe, expect, it } from "vitest";

import {
  childAccessCreationLimit,
  createCreateChildStudentAccessHandler,
  type ChildAccessCreationStore,
  type ChildIdentityPort,
} from "../services/childStudentAccessCallable";
import type { AccountSnapshot, StudentAccessStore } from "../services/studentAccessCode";

class Memory implements ChildAccessCreationStore, ChildIdentityPort {
  parents = new Map([
    ["parent-1", { role: "parent", accountStatus: "active" }],
    ["suspended-parent", { role: "parent", accountStatus: "suspended" }],
    ["student-1", { role: "student", accountStatus: "active" }],
  ]);
  requests = new Map<string, { studentId: string; completed: boolean }>();
  quota = new Map<string, number>();
  identities: string[] = [];
  links: string[] = [];
  pending = new Map<string, string>();
  credentials = new Map<string, string>();
  failIdentity = false;

  async readParent(uid: string) {
    return this.parents.get(uid) ?? null;
  }
  async reserve(params: { parentId: string; requestId: string; candidateStudentId: string }) {
    const key = `${params.parentId}_${params.requestId}`;
    const existing = this.requests.get(key);
    if (existing) return { studentId: existing.studentId, replay: true, completed: existing.completed };
    const count = this.quota.get(params.parentId) ?? 0;
    if (count >= childAccessCreationLimit.perWindow) return null;
    this.quota.set(params.parentId, count + 1);
    this.requests.set(key, { studentId: params.candidateStudentId, completed: false });
    return { studentId: params.candidateStudentId, replay: false, completed: false };
  }
  async linkPendingChild(params: { parentId: string; studentId: string; firstName: string }) {
    this.links.push(`${params.parentId}_${params.studentId}`);
    this.pending.set(params.studentId, params.firstName);
  }
  async complete(params: { parentId: string; requestId: string }) {
    this.requests.get(`${params.parentId}_${params.requestId}`)!.completed = true;
  }
  async createStudentIdentity(uid: string) {
    if (this.failIdentity) throw new Error("auth down");
    if (!this.identities.includes(uid)) this.identities.push(uid);
  }

  readonly access: StudentAccessStore = {
    readAccount: async (uid): Promise<AccountSnapshot | null> =>
      this.pending.has(uid) ? { role: "student", accountStatus: "active", establishmentId: "" } : null,
    isLinkedParent: async (parentId, studentId) => this.links.includes(`${parentId}_${studentId}`),
    replaceCredential: async ({ studentId, lookupKey }) => {
      this.credentials.set(studentId, lookupKey);
      return { version: 1 };
    },
    readCredentialStatus: async () => ({ hasAccessCode: false, issuedAt: null }),
    resolveActiveCredential: async () => null,
    isClientBlocked: async () => false,
    recordClientFailure: async () => undefined,
    resetClientFailures: async () => undefined,
  };
}

function handlerFor(memory: Memory) {
  let sequence = 0;
  return createCreateChildStudentAccessHandler({
    pepper: () => "pepper",
    store: memory,
    access: memory.access,
    identities: memory,
    newUid: () => `child-${++sequence}`,
  });
}

const request = (uid: string | undefined, data: unknown) =>
  ({ auth: uid ? { uid } : undefined, data }) as never;

const requestId = "3f2a1b4c-5d6e-4f70-8a9b-0c1d2e3f4a5b";

describe("createChildStudentAccess — a new family whose child has no phone", () => {
  it("creates a phoneless student identity, links it to the parent and returns the access code once", async () => {
    const memory = new Memory();
    const result = await handlerFor(memory)(request("parent-1", { firstName: " Awa ", requestId }));
    expect(result).toMatchObject({ studentId: "child-1", firstName: "Awa" });
    expect(result.code).toMatch(/^[A-Z2-9]{4}-[A-Z2-9]{4}-[A-Z2-9]{4}$/);
    expect(memory.identities).toEqual(["child-1"]);
    expect(memory.links).toEqual(["parent-1_child-1"]);
    expect(memory.pending.get("child-1")).toBe("Awa");
    expect(memory.credentials.has("child-1")).toBe(true);
  });

  it("a replayed request never creates a second child and never re-reveals the code", async () => {
    const memory = new Memory();
    const handler = handlerFor(memory);
    await handler(request("parent-1", { firstName: "Awa", requestId }));
    const replay = await handler(request("parent-1", { firstName: "Awa", requestId }));
    expect(replay).toEqual({ studentId: "child-1", firstName: "Awa", code: null });
    expect(memory.identities).toHaveLength(1);
  });

  it("an interrupted creation resumes the same child on retry", async () => {
    const memory = new Memory();
    const handler = handlerFor(memory);
    memory.failIdentity = true;
    await expect(handler(request("parent-1", { firstName: "Awa", requestId }))).rejects.toThrow();
    memory.failIdentity = false;
    const retry = await handler(request("parent-1", { firstName: "Awa", requestId }));
    expect(retry.studentId).toBe("child-1");
    expect(retry.code).not.toBeNull();
    expect(memory.identities).toEqual(["child-1"]);
  });

  it.each([
    ["an unauthenticated caller", undefined, "unauthenticated"],
    ["a student", "student-1", "permission-denied"],
    ["a suspended parent", "suspended-parent", "permission-denied"],
  ])("refuses %s", async (_label, uid, code) => {
    const memory = new Memory();
    await expect(handlerFor(memory)(request(uid, { firstName: "Awa", requestId })))
      .rejects.toMatchObject({ code });
    expect(memory.identities).toHaveLength(0);
  });

  it("validates the payload strictly and caps creations per parent", async () => {
    const memory = new Memory();
    const handler = handlerFor(memory);
    for (const data of [{}, { firstName: "", requestId }, { firstName: "Awa", requestId: "x" }, { firstName: "Awa", requestId, phone: "1" }]) {
      await expect(handler(request("parent-1", data))).rejects.toMatchObject({ code: "invalid-argument" });
    }
    for (let index = 0; index < childAccessCreationLimit.perWindow; index++) {
      await handler(request("parent-1", {
        firstName: `Enfant ${index}`,
        requestId: `3f2a1b4c-5d6e-4f70-8a9b-0c1d2e3f4a${String(index).padStart(2, "0")}`,
      }));
    }
    await expect(handler(request("parent-1", {
      firstName: "Encore",
      requestId: "3f2a1b4c-5d6e-4f70-8a9b-0c1d2e3f4aff",
    }))).rejects.toMatchObject({ code: "resource-exhausted" });
  });
});
