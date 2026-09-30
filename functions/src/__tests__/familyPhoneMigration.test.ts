import { describe, expect, it } from "vitest";

import {
  createMigrateStudentPhoneToParentHandler,
  familyPhoneKey,
  migrationLeaseMs,
  phoneVerificationMaxAgeMs,
  type FamilyPhoneMigrationStore,
  type MigrationAccount,
  type MigrationAuthPort,
  type MigrationJournal,
} from "../services/familyPhoneMigration";
import {
  createSignInWithStudentAccessCodeHandler,
  studentAccessRateLimit,
  type AccountSnapshot,
  type StudentAccessStore,
} from "../services/studentAccessCode";

const pepper = "test-pepper";
const phone = "+237699000111";
const T0 = 1_800_000_000_000;

class Family {
  // Firebase Auth : uid -> numéro. L'unicité du numéro est vérifiée comme Firebase.
  authPhones = new Map<string, string | null>();
  accounts = new Map<string, MigrationAccount & { establishmentId: string }>();
  profiles = new Set<string>();
  studentDocs = new Map<string, Record<string, unknown>>();
  links = new Map<string, { parentId: string; studentId: string; status: string }>();
  journals = new Map<string, MigrationJournal>();
  credentials = new Map<string, string>(); // studentId -> lookupKey
  lookups = new Map<string, string>(); // lookupKey -> studentId
  faults: { createPhoneUser?: number; attachPhone?: number; detachPhone?: number; finalize?: number } = {};
  now = T0;
  tokens: string[] = [];

  trip(step: keyof Family["faults"]) {
    const remaining = this.faults[step] ?? 0;
    if (remaining > 0) {
      this.faults[step] = remaining - 1;
      throw Object.assign(new Error(`${step} failed`), { code: `test/${step}` });
    }
  }

  ownerOf(phoneE164: string) {
    return [...this.authPhones.entries()].find(([, value]) => value === phoneE164)?.[0];
  }

  readonly store: FamilyPhoneMigrationStore = {
    readAccount: async (uid) => this.accounts.get(uid) ?? null,
    hasAnyProfile: async (uid) => this.accounts.has(uid) || this.profiles.has(uid),
    readJournal: async (key) => (this.journals.has(key) ? { ...this.journals.get(key)! } : null),
    claimJournal: async (params) => {
      const current = this.journals.get(params.phoneKey);
      if (current && current.leaseUntilMs > params.nowMs) return null;
      const restarted = current?.status === "compensated";
      const journal: MigrationJournal = current
        ? {
            ...current,
            studentUid: restarted ? params.studentUid : current.studentUid,
            status: restarted ? "started" : current.status,
            leaseUntilMs: params.nowMs + migrationLeaseMs,
            requestId: params.requestId,
          }
        : {
            phoneKey: params.phoneKey,
            phoneE164: params.phoneE164,
            studentUid: params.studentUid,
            parentUid: params.candidateParentUid,
            status: "started",
            leaseUntilMs: params.nowMs + migrationLeaseMs,
            requestId: params.requestId,
          };
      this.journals.set(params.phoneKey, journal);
      return { ...journal };
    },
    updateJournal: async (key, patch) => {
      const current = this.journals.get(key)!;
      const { lastError: _ignored, ...fields } = patch;
      this.journals.set(key, { ...current, ...fields });
    },
    finalizeFamily: async ({ phoneKey, parentUid, studentUid }) => {
      this.trip("finalize");
      this.links.set(`${parentUid}_${studentUid}`, { parentId: parentUid, studentId: studentUid, status: "approved" });
      const doc = { ...this.studentDocs.get(studentUid) };
      delete doc.phoneNumber;
      this.studentDocs.set(studentUid, { ...doc, authPhoneMovedToParentId: parentUid });
      this.journals.set(phoneKey, { ...this.journals.get(phoneKey)!, status: "completed", parentUid, leaseUntilMs: 0 });
    },
  };

  readonly auth: MigrationAuthPort = {
    getPhoneNumber: async (uid) => this.authPhones.get(uid),
    detachPhone: async (uid) => {
      this.trip("detachPhone");
      this.authPhones.set(uid, null);
    },
    attachPhone: async (uid, phoneE164) => {
      this.trip("attachPhone");
      const owner = this.ownerOf(phoneE164);
      if (owner && owner !== uid) throw { code: "auth/phone-number-already-exists" };
      this.authPhones.set(uid, phoneE164);
    },
    createPhoneUser: async (uid, phoneE164) => {
      this.trip("createPhoneUser");
      const owner = this.ownerOf(phoneE164);
      if (owner && owner !== uid) throw { code: "auth/phone-number-already-exists" };
      this.authPhones.set(uid, phoneE164);
    },
    createCustomToken: async (uid) => {
      this.tokens.push(uid);
      return `token-for-${uid}`;
    },
  };

  readonly access: StudentAccessStore = {
    readAccount: async (uid): Promise<AccountSnapshot | null> => this.accounts.get(uid) ?? null,
    isLinkedParent: async (parentId, studentId) => this.links.has(`${parentId}_${studentId}`),
    replaceCredential: async ({ studentId, lookupKey }) => {
      const previous = this.credentials.get(studentId);
      if (previous) this.lookups.delete(previous);
      this.credentials.set(studentId, lookupKey);
      this.lookups.set(lookupKey, studentId);
      return { version: 1 };
    },
    readCredentialStatus: async (studentId) => ({
      hasAccessCode: this.credentials.has(studentId),
      issuedAt: null,
    }),
    resolveActiveCredential: async (lookupKey) => {
      const studentId = this.lookups.get(lookupKey);
      return studentId && this.credentials.get(studentId) === lookupKey ? studentId : null;
    },
    isClientBlocked: async () => false,
    recordClientFailure: async () => undefined,
    resetClientFailures: async () => undefined,
  };

  handler() {
    let sequence = 0;
    return createMigrateStudentPhoneToParentHandler({
      pepper: () => pepper,
      store: this.store,
      access: this.access,
      auth: this.auth,
      now: () => this.now,
      newUid: () => `parent-new-${++sequence}`,
    });
  }

  signIn(code: string) {
    return createSignInWithStudentAccessCodeHandler(() => pepper, this.access, {
      createCustomToken: async (uid) => `token-for-${uid}`,
    })({ data: { code }, rawRequest: { ip: "203.0.113.1", headers: {} } } as never);
  }
}

/** Le propriétaire : son numéro ouvre aujourd'hui l'accès de son enfant. */
function ownerFamily() {
  const family = new Family();
  family.authPhones.set("student-old", phone);
  family.accounts.set("student-old", {
    role: "student",
    accountStatus: "active",
    firstName: "Awa",
    establishmentId: "school-a",
  });
  family.studentDocs.set("student-old", {
    firstName: "Awa",
    classLevel: "Terminale",
    phoneNumber: phone,
    studyReserveCycle: "offer-a_1",
    progress: { lessons: 42 },
  });
  return family;
}

function phoneCaller(uid: string, options: { authTimeMs?: number; provider?: string; phoneNumber?: string } = {}) {
  return {
    uid,
    token: {
      phone_number: options.phoneNumber ?? phone,
      auth_time: Math.floor((options.authTimeMs ?? T0 - 30_000) / 1000),
      firebase: { sign_in_provider: options.provider ?? "phone" },
    },
  };
}

const confirmed = (requestId = "5f0e3a52-6d2c-4c1e-9d59-8d8f0c2f1a11") => ({ requestId, confirmed: true });

describe("migrateStudentPhoneToParent — the owner's journey", () => {
  it("moves the phone to a new parent, links the child, keeps the student UID and data, and the access code works", async () => {
    const family = ownerFamily();
    const result = await family.handler()({ auth: phoneCaller("student-old"), data: confirmed() } as never);

    expect(result).toMatchObject({
      status: "completed",
      studentId: "student-old",
      studentFirstName: "Awa",
      parentUid: "parent-new-1",
      parentToken: "token-for-parent-new-1",
    });
    // Le numéro ouvre désormais le parent, plus l'élève.
    expect(family.authPhones.get("parent-new-1")).toBe(phone);
    expect(family.authPhones.get("student-old")).toBeNull();
    // L'élève reste le même UID, avec toutes ses données.
    expect(family.studentDocs.get("student-old")).toEqual({
      firstName: "Awa",
      classLevel: "Terminale",
      studyReserveCycle: "offer-a_1",
      progress: { lessons: 42 },
      authPhoneMovedToParentId: "parent-new-1",
    });
    expect(family.links.get("parent-new-1_student-old")?.status).toBe("approved");
    // Le code d'accès, montré une fois, ouvre le même élève.
    expect(result.studentAccessCode).toMatch(/^[A-Z2-9]{4}-[A-Z2-9]{4}-[A-Z2-9]{4}$/);
    await expect(family.signIn(result.studentAccessCode!)).resolves.toEqual({ token: "token-for-student-old" });
  });

  it("replays a lost response without a second parent or a second code", async () => {
    const family = ownerFamily();
    const handler = family.handler();
    await handler({ auth: phoneCaller("student-old"), data: confirmed() } as never);
    const replay = await handler({ auth: phoneCaller("student-old"), data: confirmed() } as never);
    expect(replay).toMatchObject({ parentUid: "parent-new-1", parentToken: "token-for-parent-new-1", studentAccessCode: null });
    const fromParent = await handler({ auth: phoneCaller("parent-new-1"), data: confirmed() } as never);
    expect(fromParent).toMatchObject({ parentUid: "parent-new-1", parentToken: null, studentAccessCode: null });
    expect([...family.authPhones.keys()]).toEqual(["student-old", "parent-new-1"]);
  });
});

describe("migrateStudentPhoneToParent — proof and consent", () => {
  it.each([
    ["an old SMS verification", phoneCaller("student-old", { authTimeMs: T0 - phoneVerificationMaxAgeMs - 1 })],
    ["a custom-token session", phoneCaller("student-old", { provider: "custom" })],
    ["a session without a phone", { uid: "student-old", token: { firebase: { sign_in_provider: "phone" } } }],
  ])("refuses %s", async (_label, auth) => {
    const family = ownerFamily();
    await expect(family.handler()({ auth, data: confirmed() } as never))
      .rejects.toMatchObject({ code: "failed-precondition" });
    expect(family.authPhones.get("student-old")).toBe(phone);
  });

  it("never migrates silently: an explicit confirmation is required", async () => {
    const family = ownerFamily();
    for (const data of [{}, { requestId: confirmed().requestId }, { requestId: "x", confirmed: true }, { ...confirmed(), confirmed: false }]) {
      await expect(family.handler()({ auth: phoneCaller("student-old"), data } as never))
        .rejects.toMatchObject({ code: "invalid-argument" });
    }
    expect(family.journals.size).toBe(0);
  });

  it("refuses a parent, and a student whose Auth record no longer holds this number", async () => {
    const family = ownerFamily();
    family.accounts.set("parent-x", { role: "parent", accountStatus: "active", firstName: "", establishmentId: "" });
    family.authPhones.set("parent-x", "+237699000999");
    await expect(family.handler()({ auth: phoneCaller("parent-x"), data: confirmed() } as never))
      .rejects.toMatchObject({ code: "failed-precondition" });
    family.authPhones.set("student-old", "+237677000000");
    await expect(family.handler()({ auth: phoneCaller("student-old"), data: confirmed() } as never))
      .rejects.toMatchObject({ code: "failed-precondition" });
  });

  it("refuses a concurrent run holding the lease", async () => {
    const family = ownerFamily();
    family.faults.createPhoneUser = 1;
    family.faults.attachPhone = 1;
    await expect(family.handler()({ auth: phoneCaller("student-old"), data: confirmed() } as never)).rejects.toBeDefined();
    const key = familyPhoneKey(phone, pepper);
    family.journals.set(key, { ...family.journals.get(key)!, leaseUntilMs: T0 + 10_000 });
    await expect(family.handler()({ auth: phoneCaller("student-old"), data: confirmed() } as never))
      .rejects.toMatchObject({ code: "aborted" });
  });
});

describe("migrateStudentPhoneToParent — failure halfway never strands the family", () => {
  it("parent creation fails: the phone goes back to the student, nothing changed, a retry completes", async () => {
    const family = ownerFamily();
    family.faults.createPhoneUser = 1;
    const handler = family.handler();
    await expect(handler({ auth: phoneCaller("student-old"), data: confirmed() } as never))
      .rejects.toMatchObject({ code: "unavailable", details: { reason: "migration-compensated" } });
    expect(family.authPhones.get("student-old")).toBe(phone);
    expect(family.ownerOf(phone)).toBe("student-old");
    expect(family.links.size).toBe(0);
    expect(family.journals.get(familyPhoneKey(phone, pepper))?.status).toBe("compensated");

    const retry = await handler({ auth: phoneCaller("student-old"), data: confirmed() } as never);
    expect(retry.parentToken).toBe(`token-for-${retry.parentUid}`);
    expect(family.ownerOf(phone)).toBe(retry.parentUid);
    await expect(family.signIn(retry.studentAccessCode!)).resolves.toEqual({ token: "token-for-student-old" });
  });

  it("detaching the phone fails: the student keeps the number and may retry at once", async () => {
    const family = ownerFamily();
    family.faults.detachPhone = 1;
    const handler = family.handler();
    await expect(handler({ auth: phoneCaller("student-old"), data: confirmed() } as never))
      .rejects.toMatchObject({ code: "unavailable" });
    expect(family.ownerOf(phone)).toBe("student-old");
    await expect(handler({ auth: phoneCaller("student-old"), data: confirmed() } as never))
      .resolves.toMatchObject({ status: "completed" });
  });

  it("parent creation AND compensation fail: the code still opens the student and a new SMS finishes the parent", async () => {
    const family = ownerFamily();
    family.faults.createPhoneUser = 1;
    family.faults.attachPhone = 1;
    const error = await family.handler()({ auth: phoneCaller("student-old"), data: confirmed() } as never)
      .catch((caught: { code: string; details: { reason: string; studentAccessCode: string } }) => caught);
    expect(error).toMatchObject({ code: "unavailable", details: { reason: "migration-needs-recovery" } });
    // L'élève a un accès qui marche, même sans téléphone.
    const code = (error as { details: { studentAccessCode: string } }).details.studentAccessCode;
    await expect(family.signIn(code)).resolves.toEqual({ token: "token-for-student-old" });
    expect(family.ownerOf(phone)).toBeUndefined();

    // Le parent vérifie à nouveau son numéro : Firebase crée une identité vierge.
    family.authPhones.set("fresh-uid", phone);
    family.now += migrationLeaseMs;
    const resumed = await family.handler()({ auth: phoneCaller("fresh-uid", { authTimeMs: family.now - 1000 }), data: confirmed() } as never);
    expect(resumed).toMatchObject({ parentUid: "fresh-uid", parentToken: null, studentId: "student-old" });
    expect(family.links.get("fresh-uid_student-old")?.status).toBe("approved");
  });

  it("the family link fails after the parent exists: the next SMS lands on the parent and finishes", async () => {
    const family = ownerFamily();
    family.faults.finalize = 3;
    const error = await family.handler()({ auth: phoneCaller("student-old"), data: confirmed() } as never)
      .catch((caught: { code: string; details: { reason: string; studentAccessCode: string } }) => caught);
    expect(error).toMatchObject({ code: "unavailable", details: { reason: "migration-resumable" } });
    const parentUid = family.ownerOf(phone)!;
    expect(parentUid).toBe("parent-new-1");
    await expect(family.signIn((error as { details: { studentAccessCode: string } }).details.studentAccessCode))
      .resolves.toEqual({ token: "token-for-student-old" });

    const resumed = await family.handler()({ auth: phoneCaller(parentUid), data: confirmed() } as never);
    expect(resumed).toMatchObject({ status: "completed", parentUid, parentToken: null, studentAccessCode: null });
    expect(family.links.get(`${parentUid}_student-old`)?.status).toBe("approved");
  });

  it("an unrelated account cannot hijack an unfinished migration", async () => {
    const family = ownerFamily();
    family.faults.createPhoneUser = 1;
    family.faults.attachPhone = 1;
    await family.handler()({ auth: phoneCaller("student-old"), data: confirmed() } as never).catch(() => undefined);
    family.accounts.set("someone", { role: "parent", accountStatus: "active", firstName: "", establishmentId: "" });
    family.now += migrationLeaseMs;
    await expect(family.handler()({ auth: phoneCaller("someone", { authTimeMs: family.now - 1000 }), data: confirmed() } as never))
      .rejects.toMatchObject({ code: "failed-precondition" });
    expect(studentAccessRateLimit.maxFailures).toBeGreaterThan(0);
  });
});
