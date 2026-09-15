import { describe, expect, it } from "vitest";

import {
  createIssueStudentAccessCodeHandler,
  createSignInWithStudentAccessCodeHandler,
  formatStudentAccessCode,
  generateStudentAccessCode,
  isWellFormedStudentAccessCode,
  normalizeStudentAccessCode,
  studentAccessCodeAlphabet,
  studentAccessCodeLength,
  studentAccessLookupKey,
  studentAccessRateLimit,
  type AccountSnapshot,
  type StudentAccessCredentialStatus,
  type StudentAccessStore,
} from "../services/studentAccessCode";

const pepper = "test-pepper";

class MemoryStudentAccessStore implements StudentAccessStore {
  accounts = new Map<string, AccountSnapshot>();
  links = new Set<string>();
  /** lookupKey -> { studentId, version } */
  lookups = new Map<string, { studentId: string; version: number }>();
  credentials = new Map<string, { lookupKey: string; version: number; issuedAtMs: number }>();
  failures = new Map<string, number>();
  audit: { type: string; studentId: string; actorUid: string; actorRole: string }[] = [];

  async readAccount(uid: string) {
    return this.accounts.get(uid) ?? null;
  }
  async isLinkedParent(parentId: string, studentId: string) {
    return this.links.has(`${parentId}_${studentId}`);
  }
  async replaceCredential(params: {
    studentId: string;
    lookupKey: string;
    actorUid: string;
    actorRole: string;
  }) {
    if (this.lookups.has(params.lookupKey)) return null;
    const previous = this.credentials.get(params.studentId);
    if (previous) this.lookups.delete(previous.lookupKey);
    const version = (previous?.version ?? 0) + 1;
    this.lookups.set(params.lookupKey, { studentId: params.studentId, version });
    this.credentials.set(params.studentId, {
      lookupKey: params.lookupKey,
      version,
      issuedAtMs: Date.now(),
    });
    this.audit.push({
      type: previous ? "rotated" : "issued",
      studentId: params.studentId,
      actorUid: params.actorUid,
      actorRole: params.actorRole,
    });
    return { version };
  }
  async readCredentialStatus(studentId: string): Promise<StudentAccessCredentialStatus> {
    const credential = this.credentials.get(studentId);
    return credential
      ? { hasAccessCode: true, issuedAt: new Date(credential.issuedAtMs).toISOString() }
      : { hasAccessCode: false, issuedAt: null };
  }
  async resolveActiveCredential(lookupKey: string) {
    const lookup = this.lookups.get(lookupKey);
    if (!lookup) return null;
    const credential = this.credentials.get(lookup.studentId);
    return credential?.lookupKey === lookupKey ? lookup.studentId : null;
  }
  async isClientBlocked(clientKey: string) {
    return (this.failures.get(clientKey) ?? 0) >= studentAccessRateLimit.maxFailures;
  }
  async recordClientFailure(clientKey: string) {
    this.failures.set(clientKey, (this.failures.get(clientKey) ?? 0) + 1);
  }
  async resetClientFailures(clientKey: string) {
    this.failures.delete(clientKey);
  }
}

function seededStore() {
  const store = new MemoryStudentAccessStore();
  const account = (role: string, establishmentId = "school-a", accountStatus = "active") => ({
    role,
    establishmentId,
    accountStatus,
  });
  store.accounts.set("student-a", account("student"));
  store.accounts.set("student-b", account("student", "school-b"));
  store.accounts.set("parent-a", account("parent", ""));
  store.accounts.set("parent-b", account("parent", ""));
  store.accounts.set("head-a", account("admin", "school-a"));
  store.accounts.set("head-b", account("admin", "school-b"));
  store.accounts.set("suspended-head-a", account("admin", "school-a", "suspended"));
  store.accounts.set("teacher-a", account("teacher", "school-a"));
  store.accounts.set("root", account("superAdmin", ""));
  store.links.add("parent-a_student-a");
  store.links.add("parent-b_student-b");
  return store;
}

class TokenRecorder {
  issued: { uid: string; claims?: Record<string, unknown> }[] = [];
  async createCustomToken(uid: string, claims?: Record<string, unknown>) {
    this.issued.push({ uid, claims });
    return `token-for-${uid}`;
  }
}

function signInRequest(code: unknown, ip = "203.0.113.7") {
  return {
    data: { code },
    rawRequest: { ip, headers: {} },
    app: { appId: "android-app" },
  } as never;
}

describe("student access code format", () => {
  it("draws 12 symbols from the unambiguous alphabet", () => {
    const code = generateStudentAccessCode();
    expect(code).toHaveLength(studentAccessCodeLength);
    for (const symbol of code) expect(studentAccessCodeAlphabet).toContain(symbol);
    expect(studentAccessCodeAlphabet).not.toMatch(/[01IOL]/);
  });

  it("keeps the per-client lock tolerant of shared IPs (school Wi-Fi, carrier NAT)", () => {
    // 20 essais par quart d'heure et par IP : probabilité de deviner un code
    // parmi 31^12 inférieure à 10^-16 par fenêtre.
    expect(studentAccessRateLimit.maxFailures).toBe(20);
    expect(studentAccessRateLimit.maxFailures / 31 ** 12).toBeLessThan(1e-16);
  });

  it("offers far more than a PIN: 31^12 ≈ 2^59", () => {
    const bits = studentAccessCodeLength * Math.log2(studentAccessCodeAlphabet.length);
    expect(bits).toBeGreaterThan(59);
  });

  it("accepts the grouped form a family reads aloud", () => {
    const normalized = normalizeStudentAccessCode(" abcd-efgh jkmn ");
    expect(normalized).toBe("ABCDEFGHJKMN");
    expect(isWellFormedStudentAccessCode(normalized)).toBe(true);
    expect(formatStudentAccessCode(normalized)).toBe("ABCD-EFGH-JKMN");
    expect(isWellFormedStudentAccessCode("ABCDEFGHJKM0")).toBe(false);
    expect(isWellFormedStudentAccessCode("ABCD")).toBe(false);
  });

  it("indexes a keyed digest, never the code itself", () => {
    const key = studentAccessLookupKey("ABCDEFGHJKMN", pepper);
    expect(key).toMatch(/^[0-9a-f]{64}$/);
    expect(key).not.toContain("ABCDEFGHJKMN");
    expect(studentAccessLookupKey("ABCDEFGHJKMN", "other-pepper")).not.toBe(key);
  });
});

describe("issueStudentAccessCode", () => {
  it("lets a linked parent issue a code, returned once and stored as a digest", async () => {
    const store = seededStore();
    const handler = createIssueStudentAccessCodeHandler(() => pepper, store);
    const result = await handler({ auth: { uid: "parent-a" }, data: { studentId: "student-a" } } as never);
    expect(result.code).toMatch(/^[A-Z2-9]{4}-[A-Z2-9]{4}-[A-Z2-9]{4}$/);
    const stored = JSON.stringify([...store.lookups.entries(), ...store.credentials.entries()]);
    expect(stored).not.toContain(normalizeStudentAccessCode(result.code));
    expect(store.audit).toEqual([
      { type: "issued", studentId: "student-a", actorUid: "parent-a", actorRole: "parent" },
    ]);
  });

  it("rotation invalidates the previous code at once", async () => {
    const store = seededStore();
    const issue = createIssueStudentAccessCodeHandler(() => pepper, store);
    const signIn = createSignInWithStudentAccessCodeHandler(() => pepper, store, new TokenRecorder());
    const first = await issue({ auth: { uid: "parent-a" }, data: { studentId: "student-a" } } as never);
    const second = await issue({ auth: { uid: "parent-a" }, data: { studentId: "student-a" } } as never);
    expect(second.code).not.toBe(first.code);
    await expect(signIn(signInRequest(first.code))).rejects.toMatchObject({ code: "permission-denied" });
    await expect(signIn(signInRequest(second.code))).resolves.toEqual({ token: "token-for-student-a" });
    expect(store.audit.map((entry) => entry.type)).toEqual(["issued", "rotated"]);
  });

  it("lets the school head of the student's school and the super admin recover access", async () => {
    const store = seededStore();
    const handler = createIssueStudentAccessCodeHandler(() => pepper, store);
    await expect(handler({ auth: { uid: "head-a" }, data: { studentId: "student-a" } } as never))
      .resolves.toMatchObject({ code: expect.any(String) });
    await expect(handler({ auth: { uid: "root" }, data: { studentId: "student-b" } } as never))
      .resolves.toMatchObject({ code: expect.any(String) });
    expect(store.audit.map((entry) => entry.actorRole)).toEqual(["admin", "superAdmin"]);
  });

  it.each([
    ["a parent linked only to another child", "parent-b", "student-a"],
    ["the head of another school", "head-b", "student-a"],
    ["a suspended head of the same school", "suspended-head-a", "student-a"],
    ["a teacher", "teacher-a", "student-a"],
    ["the student themself", "student-a", "student-a"],
  ])("refuses %s", async (_label, uid, studentId) => {
    const store = seededStore();
    const handler = createIssueStudentAccessCodeHandler(() => pepper, store);
    await expect(handler({ auth: { uid }, data: { studentId } } as never))
      .rejects.toMatchObject({ code: "permission-denied" });
    expect(store.credentials.size).toBe(0);
  });

  it("does not reveal whether an unknown id is a student", async () => {
    const store = seededStore();
    const handler = createIssueStudentAccessCodeHandler(() => pepper, store);
    await expect(handler({ auth: { uid: "parent-a" }, data: { studentId: "nobody" } } as never))
      .rejects.toMatchObject({ code: "permission-denied" });
    await expect(handler({ auth: { uid: "parent-a" }, data: { studentId: "parent-b" } } as never))
      .rejects.toMatchObject({ code: "permission-denied" });
  });

  it("requires authentication and a strict payload", async () => {
    const handler = createIssueStudentAccessCodeHandler(() => pepper, seededStore());
    await expect(handler({ data: { studentId: "student-a" } } as never))
      .rejects.toMatchObject({ code: "unauthenticated" });
    await expect(handler({ auth: { uid: "parent-a" }, data: { studentId: "a/b" } } as never))
      .rejects.toMatchObject({ code: "invalid-argument" });
    await expect(handler({ auth: { uid: "parent-a" }, data: { studentId: "student-a", code: "X" } } as never))
      .rejects.toMatchObject({ code: "invalid-argument" });
  });
});

describe("signInWithStudentAccessCode", () => {
  it("exchanges a valid code for a custom token of the SAME student UID, without SMS", async () => {
    const store = seededStore();
    const tokens = new TokenRecorder();
    const { code } = await createIssueStudentAccessCodeHandler(() => pepper, store)(
      { auth: { uid: "parent-a" }, data: { studentId: "student-a" } } as never,
    );
    const signIn = createSignInWithStudentAccessCodeHandler(() => pepper, store, tokens);
    await expect(signIn(signInRequest(code.toLowerCase().replaceAll("-", " "))))
      .resolves.toEqual({ token: "token-for-student-a" });
    expect(tokens.issued).toEqual([
      { uid: "student-a", claims: { accessMethod: "student_access_code" } },
    ]);
  });

  it("answers every failure the same way and blocks the client after the failure threshold", async () => {
    const store = seededStore();
    const { code } = await createIssueStudentAccessCodeHandler(() => pepper, store)(
      { auth: { uid: "parent-a" }, data: { studentId: "student-a" } } as never,
    );
    const signIn = createSignInWithStudentAccessCodeHandler(() => pepper, store, new TokenRecorder());
    const kinds = ["", "short", "ZZZZZZZZZZZZ", 42, "ABCDEFGHJKMN"];
    for (let attempt = 0; attempt < studentAccessRateLimit.maxFailures; attempt++) {
      const miss = kinds[attempt % kinds.length];
      await expect(signIn(signInRequest(miss))).rejects.toMatchObject({ code: "permission-denied" });
    }
    // Même le bon code est refusé tant que le client est bloqué.
    await expect(signIn(signInRequest(code))).rejects.toMatchObject({ code: "resource-exhausted" });
    // Un autre client n'est pas pénalisé.
    await expect(signIn(signInRequest(code, "198.51.100.4"))).resolves.toEqual({ token: "token-for-student-a" });
  });

  it("refuses a suspended student even with a valid code", async () => {
    const store = seededStore();
    const { code } = await createIssueStudentAccessCodeHandler(() => pepper, store)(
      { auth: { uid: "parent-a" }, data: { studentId: "student-a" } } as never,
    );
    store.accounts.set("student-a", { role: "student", establishmentId: "school-a", accountStatus: "suspended" });
    const signIn = createSignInWithStudentAccessCodeHandler(() => pepper, store, new TokenRecorder());
    await expect(signIn(signInRequest(code))).rejects.toMatchObject({ code: "permission-denied" });
  });

  it("keys the rate limit on the address appended by Google's front end, not a spoofed one", async () => {
    const store = seededStore();
    const signIn = createSignInWithStudentAccessCodeHandler(() => pepper, store, new TokenRecorder());
    for (let attempt = 0; attempt < studentAccessRateLimit.maxFailures; attempt++) {
      await expect(signIn({
        data: { code: "ZZZZZZZZZZZZ" },
        rawRequest: { ip: "10.0.0.1", headers: { "x-forwarded-for": `1.1.1.${attempt}, 203.0.113.9` } },
        app: { appId: "android-app" },
      } as never)).rejects.toMatchObject({ code: "permission-denied" });
    }
    await expect(signIn({
      data: { code: "ZZZZZZZZZZZZ" },
      rawRequest: { ip: "10.0.0.1", headers: { "x-forwarded-for": "9.9.9.9, 203.0.113.9" } },
      app: { appId: "android-app" },
    } as never)).rejects.toMatchObject({ code: "resource-exhausted" });
  });
});
