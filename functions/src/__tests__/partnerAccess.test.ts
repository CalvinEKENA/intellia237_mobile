import { createHash } from "node:crypto";

import { logger } from "firebase-functions";
import { afterEach, describe, expect, it, vi } from "vitest";

import {
  createSetDemoAccessClassHandler,
  demoAccessUid,
  demoClassAccess,
  FirestoreDemoAccountStore,
  type DemoAccountStore,
} from "../services/demoAccess";
import {
  createSignInWithPartnerAccessHandler,
  FirestorePartnerAttemptLimiter,
  isPartnerEmail,
  isRevokedPartnerEmail,
  normalizePartnerEmail,
  partnerAccessUid,
  partnerAttemptLimit,
  partnerClassAccess,
  partnerClientKey,
  partnerIdentity,
  revokedPartnerEmailDigests,
  type PartnerAttemptLimiter,
} from "../services/partnerAccess";

// Valeurs fictives : la vraie valeur secrète n'est nulle part dans le dépôt
// (Secret Manager), pas plus que la valeur révoquée (seul son condensat l'est).
const configured = "partenaire.essai@exemple.test";
const compromised = "ancienne.valeur@exemple.test";
const sha256 = (value: string) => createHash("sha256").update(value).digest("hex");
const revoked = new Set([sha256(compromised)]);

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

/** Verrou en mémoire : mêmes règles, horloge maîtrisée. */
class MemoryLimiter implements PartnerAttemptLimiter {
  failures = new Map<string, number>();
  blocked = new Set<string>();
  unreadable = false;
  cannotWrite = false;
  async isBlocked(key: string) {
    if (this.unreadable) throw new Error("firestore down");
    return this.blocked.has(key);
  }
  async recordFailure(key: string) {
    if (this.cannotWrite) throw new Error("firestore down");
    const count = (this.failures.get(key) ?? 0) + 1;
    this.failures.set(key, count);
    if (count >= partnerAttemptLimit.maxFailures) this.blocked.add(key);
  }
  async reset(key: string) {
    this.failures.delete(key);
    this.blocked.delete(key);
  }
}

function signIn(email: unknown, ip = "203.0.113.7") {
  return {
    data: { email },
    rawRequest: { ip, headers: { "x-forwarded-for": ip } },
  } as never;
}

function setup(options: { closed?: boolean; read?: () => string; limiter?: MemoryLimiter } = {}) {
  const accounts = new Accounts();
  const tokens = new Tokens();
  const limiter = options.limiter ?? new MemoryLimiter();
  const handler = createSignInWithPartnerAccessHandler(options.read ?? (() => configured), {
    accounts,
    tokens,
    isClosed: () => options.closed ?? false,
    limiter,
    revoked,
  });
  return { handler, accounts, tokens, limiter };
}

const refusal = { code: "permission-denied", message: "Partner access is not available." };

afterEach(() => vi.restoreAllMocks());

describe("partner email recognition", () => {
  it("recognizes the exact value after trim and lowercase", () => {
    for (const raw of [
      configured,
      configured.toUpperCase(),
      `  ${configured}  `,
      "\tPartenaire.Essai@Exemple.TEST\n",
    ]) {
      expect(normalizePartnerEmail(raw)).toBe(configured);
      expect(isPartnerEmail(raw, configured)).toBe(true);
    }
    // Le secret lui-même peut porter des espaces ou des majuscules.
    expect(isPartnerEmail(configured, `  ${configured.toUpperCase()}\n`)).toBe(true);
  });

  it("recognizes nothing else", () => {
    for (const raw of [
      "partenaire.essai@exemple.com",
      "partenaire.essai2@exemple.test",
      "xpartenaire.essai@exemple.test",
      "partenaire.essai@exemple.test.evil.example",
      "partenaire.essai@@exemple.test",
      "partenaire essai@exemple.test",
      "",
      "   ",
      undefined,
      null,
      42,
      { email: configured },
    ]) {
      expect(isPartnerEmail(raw, configured), String(raw)).toBe(false);
    }
  });

  it("recognizes nothing when no value is configured", () => {
    for (const raw of ["", "   ", configured, undefined]) {
      expect(isPartnerEmail(raw, ""), String(raw)).toBe(false);
    }
  });
});

describe("revoked values", () => {
  it("knows a revoked value by its digest, after trim and lowercase", () => {
    expect(isRevokedPartnerEmail(compromised, revoked)).toBe(true);
    expect(isRevokedPartnerEmail(`  ${compromised.toUpperCase()} `, revoked)).toBe(true);
    expect(isRevokedPartnerEmail(configured, revoked)).toBe(false);
    expect(isRevokedPartnerEmail("", revoked)).toBe(false);
    expect(isRevokedPartnerEmail(undefined, revoked)).toBe(false);
  });

  it("the shipped list holds digests only, never a readable value", () => {
    expect(revokedPartnerEmailDigests.size).toBeGreaterThan(0);
    for (const entry of revokedPartnerEmailDigests) {
      expect(entry).toMatch(/^[0-9a-f]{64}$/);
    }
  });

  it("a secret that still holds a revoked value closes the access", async () => {
    const { handler, accounts, tokens } = setup({ read: () => `  ${compromised.toUpperCase()} ` });
    // Même en saisissant exactement la valeur révoquée.
    for (const email of [compromised, configured]) {
      await expect(handler(signIn(email))).rejects.toMatchObject(refusal);
    }
    expect(accounts.ensured).toEqual([]);
    expect(tokens.issued).toEqual([]);
  });

  // Contrôle local avec la vraie valeur révoquée, que le dépôt ne connaît pas :
  //   $env:PARTNER_REVOKED_CHECK_ADDRESS='…'; npx vitest run partnerAccess
  it.skipIf(!process.env.PARTNER_REVOKED_CHECK_ADDRESS)(
    "the real revoked value is known to the shipped list and refused by the handler",
    async () => {
      const value = process.env.PARTNER_REVOKED_CHECK_ADDRESS ?? "";
      expect(isRevokedPartnerEmail(value)).toBe(true);
      expect(isRevokedPartnerEmail(value.toUpperCase())).toBe(true);
      const accounts = new Accounts();
      const handler = createSignInWithPartnerAccessHandler(() => value, {
        accounts,
        tokens: new Tokens(),
        isClosed: () => false,
        limiter: new MemoryLimiter(),
      });
      await expect(handler(signIn(value))).rejects.toMatchObject(refusal);
      // Et si le secret est le nouveau, l'ancienne valeur n'ouvre rien.
      const other = createSignInWithPartnerAccessHandler(() => configured, {
        accounts,
        tokens: new Tokens(),
        isClosed: () => false,
        limiter: new MemoryLimiter(),
      });
      await expect(other(signIn(value))).rejects.toMatchObject(refusal);
      expect(accounts.ensured).toEqual([]);
    },
  );
});

describe("signInWithPartnerAccess", () => {
  it("opens the single canonical account with a server-issued token", async () => {
    const { handler, accounts, tokens } = setup();
    const result = await handler(signIn(`  ${configured.toUpperCase()} `));
    expect(result).toEqual({ token: `token-for-${partnerAccessUid}` });
    expect(accounts.ensured).toEqual([partnerAccessUid]);
    expect(tokens.issued).toEqual([
      {
        uid: partnerAccessUid,
        claims: { accessMethod: "partner_access", demoForFrancis: true },
      },
    ]);
  });

  it("reuses the same account and the same UID at every sign-in, whatever the secret", async () => {
    const first = setup();
    await first.handler(signIn(configured));
    await first.handler(signIn("PARTENAIRE.ESSAI@exemple.test"));
    // Le secret change (nouvelle valeur) : toujours le même UID.
    const rotated = setup({ read: () => "autre.valeur@exemple.test" });
    await rotated.handler(signIn("autre.valeur@exemple.test"));
    const uids = new Set([
      ...first.accounts.ensured,
      ...first.tokens.issued.map((issued) => issued.uid),
      ...rotated.accounts.ensured,
      ...rotated.tokens.issued.map((issued) => issued.uid),
    ]);
    expect(uids).toEqual(new Set([partnerAccessUid]));
  });

  it("carries no demo flag: the account is marked demoForFrancis only", async () => {
    const { handler, tokens } = setup();
    await handler(signIn(configured));
    const claims = tokens.issued[0].claims ?? {};
    expect(claims).not.toHaveProperty("demo");
    expect(claims.demoForFrancis).toBe(true);
    expect(partnerIdentity.marker).toBe("demoForFrancis");
    expect(partnerAccessUid).not.toBe(demoAccessUid);
  });

  it("refuses every other value the same way, and creates nothing", async () => {
    const { handler, accounts, tokens } = setup();
    for (const email of [
      "partenaire.essai@exemple.com",
      "partenaire.essai2@exemple.test",
      "partenaire.essai@exemple.tes",
      compromised,
      "",
      "someone@example.com",
    ]) {
      await expect(handler(signIn(email))).rejects.toMatchObject(refusal);
    }
    await expect(handler({ data: {}, rawRequest: { headers: {} } } as never)).rejects.toMatchObject(
      refusal,
    );
    expect(accounts.ensured).toEqual([]);
    expect(tokens.issued).toEqual([]);
  });

  it("is closed at once by PARTNER_ACCESS_DISABLED", async () => {
    const { handler, accounts, tokens } = setup({ closed: true });
    await expect(handler(signIn(configured))).rejects.toMatchObject(refusal);
    expect(accounts.ensured).toEqual([]);
    expect(tokens.issued).toEqual([]);
  });

  it("stays closed when the secret is missing, empty, malformed or unreadable", async () => {
    const unreadable = () => {
      throw new Error("secret not bound");
    };
    for (const read of [() => "", () => "   ", () => "sans-arobase", unreadable]) {
      const { handler, accounts, tokens } = setup({ read });
      // Même l'entrée vide ou la valeur « attendue » ne passent pas.
      for (const email of [configured, "", "sans-arobase"]) {
        await expect(handler(signIn(email))).rejects.toMatchObject(refusal);
      }
      expect(accounts.ensured).toEqual([]);
      expect(tokens.issued).toEqual([]);
    }
  });

  it("needs no signed-in caller: the secret value alone is the decision", async () => {
    const { handler } = setup();
    // Aucune propriété `auth` dans la requête.
    await expect(handler(signIn(configured))).resolves.toHaveProperty("token");
  });
});

describe("no hint, no matter how close the guess", () => {
  it("every refusal is byte-identical: wrong, almost right, blocked, closed, no secret", async () => {
    const almost = [
      "partenaire.essai@exemple.tes",
      "partenaire.essai@exemple.testt",
      "partenaire.essa@exemple.test",
      "Partenaire.Essai@Exemple.Tes",
      "",
    ];
    const seen: unknown[] = [];
    const capture = async (promise: Promise<unknown>) => {
      try {
        await promise;
        seen.push("resolved");
      } catch (error) {
        seen.push({
          name: (error as Error).name,
          code: (error as { code: string }).code,
          message: (error as Error).message,
          details: (error as { details?: unknown }).details ?? null,
        });
      }
    };
    const normal = setup();
    for (const email of almost) await capture(normal.handler(signIn(email)));
    const blocked = setup({ limiter: new MemoryLimiter() });
    for (let i = 0; i < partnerAttemptLimit.maxFailures; i++) {
      await blocked.handler(signIn("x@y.z")).catch(() => undefined);
    }
    await capture(blocked.handler(signIn(configured)));
    await capture(setup({ closed: true }).handler(signIn(configured)));
    await capture(setup({ read: () => "" }).handler(signIn(configured)));
    expect(seen.length).toBe(almost.length + 3);
    expect(new Set(seen.map((entry) => JSON.stringify(entry))).size).toBe(1);
    expect(seen[0]).toMatchObject(refusal);
  });
});

describe("rate limiting", () => {
  it("blocks a client after too many failures, even with the right value", async () => {
    const { handler, accounts, tokens } = setup();
    for (let i = 0; i < partnerAttemptLimit.maxFailures; i++) {
      await expect(handler(signIn(`essai${i}@exemple.test`))).rejects.toMatchObject(refusal);
    }
    // Verrouillé : la bonne valeur elle-même est refusée, par la même réponse.
    await expect(handler(signIn(configured))).rejects.toMatchObject(refusal);
    expect(accounts.ensured).toEqual([]);
    expect(tokens.issued).toEqual([]);
  });

  it("does not block another client", async () => {
    const { handler } = setup();
    for (let i = 0; i < partnerAttemptLimit.maxFailures; i++) {
      await handler(signIn(`essai${i}@exemple.test`, "198.51.100.9")).catch(() => undefined);
    }
    await expect(handler(signIn(configured, "203.0.113.7"))).resolves.toHaveProperty("token");
  });

  it("a success clears the client's failures", async () => {
    const limiter = new MemoryLimiter();
    const { handler } = setup({ limiter });
    for (let i = 0; i < partnerAttemptLimit.maxFailures - 1; i++) {
      await handler(signIn("faux@exemple.test")).catch(() => undefined);
    }
    await handler(signIn(configured));
    expect(limiter.failures.size).toBe(0);
    await handler(signIn("faux@exemple.test")).catch(() => undefined);
    expect([...limiter.failures.values()]).toEqual([1]);
  });

  it("an unreadable limiter refuses instead of opening", async () => {
    const limiter = new MemoryLimiter();
    limiter.unreadable = true;
    const { handler, accounts } = setup({ limiter });
    await expect(handler(signIn(configured))).rejects.toMatchObject(refusal);
    expect(accounts.ensured).toEqual([]);
  });

  it("a failure that cannot be recorded still gives the same refusal", async () => {
    const limiter = new MemoryLimiter();
    limiter.cannotWrite = true;
    const { handler } = setup({ limiter });
    await expect(handler(signIn("faux@exemple.test"))).rejects.toMatchObject(refusal);
  });

  it("the client key depends on the address and the secret, and hides the address", () => {
    const one = partnerClientKey({ ip: "203.0.113.7" }, configured);
    expect(partnerClientKey({ ip: "203.0.113.7" }, configured)).toBe(one);
    expect(partnerClientKey({ ip: "203.0.113.8" }, configured)).not.toBe(one);
    expect(partnerClientKey({ ip: "203.0.113.7" }, "autre@exemple.test")).not.toBe(one);
    expect(one).toMatch(/^[0-9a-f]{64}$/);
    expect(one).not.toContain("203");
  });

  describe("the Firestore limiter", () => {
    class FakeFirestore {
      docs = new Map<string, Record<string, unknown>>();
      collection(name: string) {
        return {
          doc: (id: string) => {
            const path = `${name}/${id}`;
            return {
              path,
              get: async () => ({ data: () => this.docs.get(path) }),
              delete: async () => {
                this.docs.delete(path);
              },
            };
          },
        };
      }
      async runTransaction(work: (t: unknown) => Promise<void>) {
        await work({
          get: async (ref: { path: string }) => ({ data: () => this.docs.get(ref.path) }),
          set: (ref: { path: string }, data: Record<string, unknown>) => {
            this.docs.set(ref.path, data);
          },
        });
      }
    }

    function limiterAt(clock: { now: number }) {
      const firestore = new FakeFirestore();
      return {
        firestore,
        limiter: new FirestorePartnerAttemptLimiter(firestore as never, () => clock.now),
      };
    }

    it("counts failures under a partner- key in the server-only collection", async () => {
      const clock = { now: 1_000_000 };
      const { firestore, limiter } = limiterAt(clock);
      await limiter.recordFailure("abc");
      expect([...firestore.docs.keys()]).toEqual(["student_access_attempts/partner-abc"]);
      expect(await limiter.isBlocked("abc")).toBe(false);
    });

    it("blocks at the threshold, then lets the client back in when the block ends", async () => {
      const clock = { now: 1_000_000 };
      const { limiter } = limiterAt(clock);
      for (let i = 0; i < partnerAttemptLimit.maxFailures; i++) {
        expect(await limiter.isBlocked("abc")).toBe(false);
        await limiter.recordFailure("abc");
      }
      expect(await limiter.isBlocked("abc")).toBe(true);
      clock.now += partnerAttemptLimit.blockMs - 1;
      expect(await limiter.isBlocked("abc")).toBe(true);
      clock.now += 2;
      expect(await limiter.isBlocked("abc")).toBe(false);
    });

    it("forgets old failures once the window has passed", async () => {
      const clock = { now: 1_000_000 };
      const { firestore, limiter } = limiterAt(clock);
      for (let i = 0; i < partnerAttemptLimit.maxFailures - 1; i++) {
        await limiter.recordFailure("abc");
      }
      clock.now += partnerAttemptLimit.windowMs + 1;
      await limiter.recordFailure("abc");
      expect(firestore.docs.get("student_access_attempts/partner-abc")?.failures).toBe(1);
      expect(await limiter.isBlocked("abc")).toBe(false);
    });

    it("reset forgets the client", async () => {
      const clock = { now: 1_000_000 };
      const { firestore, limiter } = limiterAt(clock);
      await limiter.recordFailure("abc");
      await limiter.reset("abc");
      expect(firestore.docs.size).toBe(0);
    });
  });
});

describe("no secret in the logs", () => {
  it("logs nothing that carries the value, a typed guess or an address of the client", async () => {
    const calls: unknown[][] = [];
    for (const level of ["debug", "info", "log", "warn", "error", "write"] as const) {
      vi.spyOn(logger, level).mockImplementation((...args: unknown[]) => {
        calls.push(args);
      });
    }
    const typed = ["Devine.Une@Valeur.test", compromised, "  ", configured.toUpperCase()];
    const ip = "203.0.113.77";
    const { handler } = setup();
    for (const email of typed) await handler(signIn(email, ip)).catch(() => undefined);
    // Verrouillé, fermé, secret manquant, secret révoqué : chaque chemin journalise.
    const blocked = setup({ limiter: new MemoryLimiter() });
    for (let i = 0; i < partnerAttemptLimit.maxFailures + 1; i++) {
      await blocked.handler(signIn("faux@exemple.test", ip)).catch(() => undefined);
    }
    await setup({ read: () => "" })
      .handler(signIn(configured, ip))
      .catch(() => undefined);
    await setup({ read: () => compromised })
      .handler(signIn(compromised, ip))
      .catch(() => undefined);

    expect(calls.length).toBeGreaterThan(0);
    const everything = JSON.stringify(calls).toLowerCase();
    for (const secret of [configured, compromised, "devine.une", "faux@exemple", ip]) {
      expect(everything).not.toContain(secret.toLowerCase());
    }
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
    await expect(handler(callAs(partnerAccessUid, { demoForFrancis: true }))).resolves.toEqual({
      classLevel: "Terminale",
      series: "D",
    });
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
    await expect(handler(callAs(partnerAccessUid, { demoForFrancis: true }))).rejects.toMatchObject(
      { code: "permission-denied" },
    );
  });
});

describe("the partner account is an ordinary student in Terminale D, seeded once", () => {
  class FakeAuth {
    users = new Map<string, { uid: string; email?: string; displayName?: string }>();
    claims = new Map<string, unknown>();
    creates: unknown[] = [];
    async getUser(uid: string) {
      const user = this.users.get(uid);
      if (!user) throw new Error("not found");
      return user;
    }
    async createUser(user: { uid: string; email?: string; displayName?: string }) {
      this.creates.push(user);
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

  it("writes no address anywhere: not in Firebase Authentication, not in Firestore", async () => {
    const { auth, firestore, accounts } = store();
    await accounts.ensureAccount(partnerAccessUid);
    expect(partnerIdentity.email).toBe("");
    expect(auth.creates).toHaveLength(1);
    expect(auth.creates[0]).not.toHaveProperty("email");
    for (const doc of firestore.docs.values()) {
      expect(doc.email).toBe("");
    }
    const everything = JSON.stringify([...firestore.docs.values(), auth.creates]);
    expect(everything).not.toContain("@");
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

  it("refuses to seed any other UID", async () => {
    const { accounts } = store();
    await expect(accounts.ensureAccount("someone-else")).rejects.toThrow("Unexpected account.");
  });
});
