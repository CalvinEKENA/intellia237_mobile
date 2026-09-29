import { describe, expect, it } from "vitest";

import {
  createSetDemoAccessClassHandler,
  demoAccessUid,
  demoClassAccess,
  FirestoreDemoAccountStore,
  type DemoAccountStore,
} from "../services/demoAccess";
import {
  createSignInWithPartnerAccessHandler,
  isPartnerEmail,
  normalizePartnerEmail,
  partnerAccessEmail,
  partnerAccessUid,
  partnerClassAccess,
  partnerIdentity,
} from "../services/partnerAccess";

class Accounts implements DemoAccountStore {
  ensured: string[] = [];
  updates: { uid: string; fields: unknown }[] = [];
  async ensureAccount(uid: string) {
    this.ensured.push(uid);
  }
  async updateClass(uid: string, fields: unknown) {
    this.updates.push({ uid, fields });
  }
}

class Tokens {
  issued: { uid: string; claims?: Record<string, unknown> }[] = [];
  async createCustomToken(uid: string, claims?: Record<string, unknown>) {
    this.issued.push({ uid, claims });
    return `token-for-${uid}`;
  }
}

function signIn(email: unknown) {
  return { data: { email }, rawRequest: { ip: "203.0.113.7", headers: {} } } as never;
}

function setup(closed = false) {
  const accounts = new Accounts();
  const tokens = new Tokens();
  const handler = createSignInWithPartnerAccessHandler(accounts, tokens, () => closed);
  return { handler, accounts, tokens };
}

describe("partner email recognition", () => {
  it("recognizes the exact address after trim and lowercase", () => {
    for (const raw of [
      "fran6farmer@yahoo.fr",
      "FRAN6FARMER@YAHOO.FR",
      "  fran6farmer@yahoo.fr  ",
      "\tFran6Farmer@Yahoo.FR\n",
    ]) {
      expect(normalizePartnerEmail(raw)).toBe(partnerAccessEmail);
      expect(isPartnerEmail(raw)).toBe(true);
    }
  });

  it("recognizes nothing else", () => {
    for (const raw of [
      "fran6farmer@yahoo.com",
      "fran6farmer2@yahoo.fr",
      "xfran6farmer@yahoo.fr",
      "fran6farmer@yahoo.fr.evil.example",
      "fran6farmer@@yahoo.fr",
      "fran6 farmer@yahoo.fr",
      "",
      "   ",
      undefined,
      null,
      42,
      { email: partnerAccessEmail },
    ]) {
      expect(isPartnerEmail(raw), String(raw)).toBe(false);
    }
  });
});

describe("signInWithPartnerAccess", () => {
  it("opens the single canonical account with a server-issued token", async () => {
    const { handler, accounts, tokens } = setup();
    const result = await handler(signIn("  FRAN6FARMER@YAHOO.FR "));
    expect(result).toEqual({ token: `token-for-${partnerAccessUid}` });
    expect(accounts.ensured).toEqual([partnerAccessUid]);
    expect(tokens.issued).toEqual([
      {
        uid: partnerAccessUid,
        claims: { accessMethod: "partner_access", demoForFrancis: true },
      },
    ]);
  });

  it("reuses the same account and the same UID at every sign-in", async () => {
    const { handler, accounts, tokens } = setup();
    await handler(signIn(partnerAccessEmail));
    await handler(signIn("FRAN6FARMER@yahoo.fr"));
    expect(new Set(accounts.ensured)).toEqual(new Set([partnerAccessUid]));
    expect(new Set(tokens.issued.map((issued) => issued.uid))).toEqual(new Set([partnerAccessUid]));
  });

  it("carries no demo flag: the account is marked demoForFrancis only", async () => {
    const { handler, tokens } = setup();
    await handler(signIn(partnerAccessEmail));
    const claims = tokens.issued[0].claims ?? {};
    expect(claims).not.toHaveProperty("demo");
    expect(claims.demoForFrancis).toBe(true);
    expect(partnerIdentity.marker).toBe("demoForFrancis");
    expect(partnerAccessUid).not.toBe(demoAccessUid);
  });

  it("refuses every other address the same way, and creates nothing", async () => {
    const { handler, accounts, tokens } = setup();
    for (const email of ["fran6farmer@yahoo.com", "fran6farmer2@yahoo.fr", "", "someone@example.com"]) {
      await expect(handler(signIn(email))).rejects.toMatchObject({
        code: "permission-denied",
        message: "Partner access is not available.",
      });
    }
    await expect(handler({ data: {}, rawRequest: { headers: {} } } as never)).rejects.toMatchObject({
      code: "permission-denied",
    });
    expect(accounts.ensured).toEqual([]);
    expect(tokens.issued).toEqual([]);
  });

  it("is closed at once by PARTNER_ACCESS_DISABLED", async () => {
    const { handler, accounts, tokens } = setup(true);
    await expect(handler(signIn(partnerAccessEmail))).rejects.toMatchObject({
      code: "permission-denied",
    });
    expect(accounts.ensured).toEqual([]);
    expect(tokens.issued).toEqual([]);
  });

  it("needs no signed-in caller and no secret: the address alone is the decision", async () => {
    const { handler } = setup();
    // Aucune propriété `auth` dans la requête.
    await expect(handler(signIn(partnerAccessEmail))).resolves.toHaveProperty("token");
  });
});

describe("setDemoAccessClass for the partner account", () => {
  const both = [demoClassAccess, partnerClassAccess] as const;
  const callAs = (uid: string | null, token: Record<string, unknown>) =>
    ({
      auth: uid ? { uid, token } : undefined,
      data: { classLevel: "Terminale", series: "D" },
    }) as never;

  it("lets the partner change class with the server-issued claim", async () => {
    const accounts = new Accounts();
    const handler = createSetDemoAccessClassHandler(accounts, both);
    await expect(
      handler(callAs(partnerAccessUid, { demoForFrancis: true })),
    ).resolves.toEqual({ classLevel: "Terminale", series: "D" });
    expect(accounts.updates.map((update) => update.uid)).toEqual([partnerAccessUid]);
  });

  it("refuses the partner UID without the claim, and the claim on another UID", async () => {
    const handler = createSetDemoAccessClassHandler(new Accounts(), both);
    await expect(handler(callAs(partnerAccessUid, {}))).rejects.toMatchObject({
      code: "permission-denied",
    });
    await expect(handler(callAs("someone-else", { demoForFrancis: true }))).rejects.toMatchObject({
      code: "permission-denied",
    });
    await expect(handler(callAs(null, {}))).rejects.toMatchObject({ code: "permission-denied" });
  });

  it("keeps refusing any other user, and keeps the demo account working", async () => {
    const accounts = new Accounts();
    const handler = createSetDemoAccessClassHandler(accounts, both);
    await expect(handler(callAs("student-42", { demo: true }))).rejects.toMatchObject({
      code: "permission-denied",
    });
    await expect(handler(callAs(demoAccessUid, { demo: true }))).resolves.toBeTruthy();
    expect(accounts.updates.map((update) => update.uid)).toEqual([demoAccessUid]);
  });

  it("the historical single-account handler is unchanged", async () => {
    const handler = createSetDemoAccessClassHandler(new Accounts());
    await expect(
      handler(callAs(partnerAccessUid, { demoForFrancis: true })),
    ).rejects.toMatchObject({ code: "permission-denied" });
  });
});

describe("the partner account is an ordinary student, seeded once", () => {
  class FakeAuth {
    users = new Map<string, { uid: string; email?: string; displayName?: string }>();
    claims = new Map<string, unknown>();
    creates: unknown[] = [];
    failEmailOnce = false;
    async getUser(uid: string) {
      const user = this.users.get(uid);
      if (!user) throw new Error("not found");
      return user;
    }
    async createUser(user: { uid: string; email?: string; displayName?: string }) {
      this.creates.push(user);
      if (this.failEmailOnce && user.email) {
        this.failEmailOnce = false;
        throw Object.assign(new Error("email exists"), { code: "auth/email-already-exists" });
      }
      this.users.set(user.uid, user);
      return user;
    }
    async setCustomUserClaims(uid: string, claims: unknown) {
      this.claims.set(uid, claims);
    }
  }

  class FakeFirestore {
    docs = new Map<string, Record<string, unknown>>();
    creates: string[] = [];
    collection(name: string) {
      return { doc: (id: string) => ({ path: `${name}/${id}` }) };
    }
    async runTransaction(work: (t: unknown) => Promise<void>) {
      const transaction = {
        get: async (ref: { path: string }) => ({ exists: this.docs.has(ref.path) }),
        create: (ref: { path: string }, data: Record<string, unknown>) => {
          this.creates.push(ref.path);
          this.docs.set(ref.path, data);
        },
      };
      await work(transaction);
    }
  }

  function store(auth = new FakeAuth()) {
    const firestore = new FakeFirestore();
    return {
      auth,
      firestore,
      accounts: new FirestoreDemoAccountStore(firestore as never, auth as never, partnerIdentity),
    };
  }

  it("creates a student profile in Terminale D with no adult right, no school, no demo flag", async () => {
    const { auth, firestore, accounts } = store();
    await accounts.ensureAccount(partnerAccessUid);
    const user = firestore.docs.get(`users/${partnerAccessUid}`)!;
    const profile = firestore.docs.get(`student_profiles/${partnerAccessUid}`)!;
    expect(user).toMatchObject({
      uid: partnerAccessUid,
      role: "student",
      classLevel: "Terminale",
      series: "D",
      firstName: "Francis",
      email: partnerAccessEmail,
      profileCompleted: true,
      accountStatus: "active",
      demoForFrancis: true,
    });
    expect(user).not.toHaveProperty("demo");
    expect(user).not.toHaveProperty("establishmentId");
    expect(user).not.toHaveProperty("roles");
    expect(profile).toMatchObject({ classLevel: "Terminale", series: "D", demoForFrancis: true });
    expect(profile).not.toHaveProperty("demo");
    expect(profile).toMatchObject({
      preferences: { academicLevelId: "fr_general_terminale", streamOrSpeciality: "D" },
    });
    expect(auth.claims.get(partnerAccessUid)).toEqual({ demoForFrancis: true });
  });

  it("never rewrites an existing account: progress and history stay on the same UID", async () => {
    const { firestore, accounts } = store();
    await accounts.ensureAccount(partnerAccessUid);
    firestore.docs.get(`student_profiles/${partnerAccessUid}`)!.points = 480;
    firestore.creates.length = 0;
    await accounts.ensureAccount(partnerAccessUid);
    await accounts.ensureAccount(partnerAccessUid);
    expect(firestore.creates).toEqual([]);
    expect(firestore.docs.get(`student_profiles/${partnerAccessUid}`)!.points).toBe(480);
  });

  it("creates the Firebase user once, then reuses it", async () => {
    const { auth, accounts } = store();
    await accounts.ensureAccount(partnerAccessUid);
    await accounts.ensureAccount(partnerAccessUid);
    expect(auth.creates).toHaveLength(1);
  });

  it("still works when the address already belongs to another Firebase user", async () => {
    const auth = new FakeAuth();
    auth.failEmailOnce = true;
    const { accounts, firestore } = store(auth);
    await accounts.ensureAccount(partnerAccessUid);
    expect(auth.creates).toHaveLength(2);
    expect(auth.creates[1]).not.toHaveProperty("email");
    expect(firestore.docs.get(`users/${partnerAccessUid}`)).toMatchObject({ email: partnerAccessEmail });
  });

  it("refuses to seed any other UID", async () => {
    const { accounts } = store();
    await expect(accounts.ensureAccount("someone-else")).rejects.toThrow("Unexpected account.");
  });
});
