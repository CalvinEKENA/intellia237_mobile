import { describe, expect, it } from "vitest";

import {
  createSetDemoAccessClassHandler,
  createSignInWithDemoAccessHandler,
  demoAcademicFields,
  demoAccessUid,
  demoClasses,
  demoDefaultClass,
  matchesDemoAccessCode,
  type DemoAccountStore,
} from "../services/demoAccess";

// Le vrai code d'invitation vit dans Secret Manager, jamais dans le dépôt.
const secret = "INVITE2026";
const pepper = "test-pepper";

class Attempts {
  failures = new Map<string, number>();
  async isClientBlocked(key: string) {
    return (this.failures.get(key) ?? 0) >= 20;
  }
  async recordClientFailure(key: string) {
    this.failures.set(key, (this.failures.get(key) ?? 0) + 1);
  }
  async resetClientFailures(key: string) {
    this.failures.delete(key);
  }
}

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

function signIn(code: unknown, ip = "203.0.113.7") {
  return {
    data: { code },
    rawRequest: { ip, headers: {} },
    app: { appId: "android-app" },
  } as never;
}

function setup(configured: () => string | undefined = () => secret) {
  const attempts = new Attempts();
  const accounts = new Accounts();
  const tokens = new Tokens();
  const handler = createSignInWithDemoAccessHandler(
    () => pepper,
    configured,
    attempts,
    accounts,
    tokens,
  );
  return { handler, attempts, accounts, tokens };
}

describe("demo access code", () => {
  it("matches the secret, ignoring case, spaces and dashes", () => {
    expect(matchesDemoAccessCode("INVITE2026", secret)).toBe(true);
    expect(matchesDemoAccessCode("  invite 2026 ", secret)).toBe(true);
    expect(matchesDemoAccessCode("INVI-TE20-26", secret)).toBe(true);
    expect(matchesDemoAccessCode("INVITE2027", secret)).toBe(false);
    expect(matchesDemoAccessCode("INVITE202", secret)).toBe(false);
    expect(matchesDemoAccessCode(42, secret)).toBe(false);
  });

  it("stays closed without a configured secret", () => {
    for (const configured of [undefined, "", "abc"]) {
      expect(matchesDemoAccessCode("INVITE2026", configured)).toBe(false);
      expect(matchesDemoAccessCode("", configured)).toBe(false);
    }
  });
});

describe("signInWithDemoAccessCode", () => {
  it("opens the shared demo student account with a demo token", async () => {
    const { handler, accounts, tokens } = setup();
    const result = await handler(signIn("invite2026"));
    expect(result).toEqual({ token: `token-for-${demoAccessUid}` });
    expect(accounts.ensured).toEqual([demoAccessUid]);
    expect(tokens.issued).toEqual([
      { uid: demoAccessUid, claims: { accessMethod: "demo_access", demo: true } },
    ]);
  });

  it("refuses any other code like an unknown student code, and counts it", async () => {
    const { handler, attempts, accounts, tokens } = setup();
    await expect(handler(signIn("WRONG2026"))).rejects.toMatchObject({
      code: "permission-denied",
      message: "Invalid student access code.",
    });
    expect([...attempts.failures.values()]).toEqual([1]);
    expect(accounts.ensured).toEqual([]);
    expect(tokens.issued).toEqual([]);
  });

  it("refuses everything when the secret is missing", async () => {
    const { handler, tokens } = setup(() => undefined);
    await expect(handler(signIn("INVITE2026"))).rejects.toMatchObject({
      code: "permission-denied",
    });
    expect(tokens.issued).toEqual([]);
  });

  it("shares the student access anti-bruteforce lock", async () => {
    const { handler, attempts, tokens } = setup();
    for (let attempt = 0; attempt < 20; attempt++) {
      await handler(signIn(`WRONG${attempt}`)).catch(() => undefined);
    }
    await expect(handler(signIn("INVITE2026"))).rejects.toMatchObject({
      code: "resource-exhausted",
    });
    expect(tokens.issued).toEqual([]);
    expect([...attempts.failures.values()]).toEqual([20]);
  });
});

describe("demo classes", () => {
  it("lands on Terminale D, the richest programme", () => {
    expect(demoDefaultClass).toEqual({ classLevel: "Terminale", series: "D" });
    expect(demoAcademicFields("Terminale", "D")).toEqual({
      classLevel: "Terminale",
      series: "D",
      educationalSubsystem: "francophone",
      educationType: "general",
      academicLevelId: "fr_general_terminale",
      streamOrSpeciality: "D",
    });
  });

  it("covers every class of both subsystems, with valid series only", () => {
    expect(demoClasses.map((entry) => entry.classLevel)).toEqual([
      "6eme", "5eme", "4eme", "3eme", "Seconde", "Premiere", "Terminale",
      "Form1", "Form2", "Form3", "Form4", "Form5", "LowerSixth", "UpperSixth",
    ]);
    expect(demoAcademicFields("6eme", null)?.academicLevelId).toBe("fr_general_6e");
    expect(demoAcademicFields("UpperSixth", null)?.academicLevelId).toBe(
      "en_general_upper_sixth",
    );
    expect(demoAcademicFields("Seconde", "c")?.series).toBe("C");
    expect(demoAcademicFields("Seconde", "D")).toBeNull();
    expect(demoAcademicFields("Terminale", null)).toBeNull();
    expect(demoAcademicFields("6eme", "A")).toBeNull();
    expect(demoAcademicFields("Licence", null)).toBeNull();
  });
});

describe("setDemoAccessClass", () => {
  const demoAuth = { uid: demoAccessUid, token: { demo: true } };

  it("changes the demo account class", async () => {
    const accounts = new Accounts();
    const handler = createSetDemoAccessClassHandler(accounts);
    const result = await handler({
      auth: demoAuth,
      data: { classLevel: "Premiere", series: "C" },
    } as never);
    expect(result).toEqual({ classLevel: "Premiere", series: "C" });
    expect(accounts.updates).toEqual([
      {
        uid: demoAccessUid,
        fields: {
          classLevel: "Premiere",
          series: "C",
          educationalSubsystem: "francophone",
          educationType: "general",
          academicLevelId: "fr_general_1ere",
          streamOrSpeciality: "C",
        },
      },
    ]);
  });

  it("is refused to every other account, even with a forged uid or claim", async () => {
    const accounts = new Accounts();
    const handler = createSetDemoAccessClassHandler(accounts);
    for (const auth of [
      undefined,
      { uid: "student-a", token: { demo: true } },
      { uid: demoAccessUid, token: {} },
    ]) {
      await expect(
        handler({ auth, data: { classLevel: "Terminale", series: "D" } } as never),
      ).rejects.toMatchObject({ code: "permission-denied" });
    }
    expect(accounts.updates).toEqual([]);
  });

  it("rejects an unknown class", async () => {
    const accounts = new Accounts();
    const handler = createSetDemoAccessClassHandler(accounts);
    await expect(
      handler({ auth: demoAuth, data: { classLevel: "Terminale", series: "Z" } } as never),
    ).rejects.toMatchObject({ code: "invalid-argument" });
    expect(accounts.updates).toEqual([]);
  });
});
