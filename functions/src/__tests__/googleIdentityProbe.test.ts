import { generateKeyPairSync, sign, type JsonWebKey, type KeyObject } from "node:crypto";

import { HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import { describe, expect, it } from "vitest";

import {
  createProbeGoogleIdentityHandler,
  GoogleKeysUnavailable,
  HttpGoogleKeySource,
  parseGoogleClientIds,
  verifyGoogleIdToken,
  type GoogleAccountDirectory,
  type GoogleKeySource,
} from "../services/googleIdentityProbe";

const audience = "123-web.apps.googleusercontent.com";
const now = 1_800_000_000;

function keyPair(kid: string): { privateKey: KeyObject; jwk: JsonWebKey } {
  const { privateKey, publicKey } = generateKeyPairSync("rsa", { modulusLength: 2048 });
  return { privateKey, jwk: { ...publicKey.export({ format: "jwk" }), kid, alg: "RS256", use: "sig" } };
}

const googleKey = keyPair("google-kid");
const attackerKey = keyPair("google-kid");

function token(
  claims: Record<string, unknown> = {},
  options: { key?: KeyObject; header?: Record<string, unknown> } = {},
): string {
  const header = { alg: "RS256", kid: "google-kid", typ: "JWT", ...options.header };
  const payload = {
    iss: "https://accounts.google.com",
    aud: audience,
    sub: "google-sub-1",
    email: "parent@example.cm",
    iat: now - 10,
    exp: now + 3600,
    ...claims,
  };
  const encode = (value: unknown) => Buffer.from(JSON.stringify(value)).toString("base64url");
  const signingInput = `${encode(header)}.${encode(payload)}`;
  const signature = sign("RSA-SHA256", Buffer.from(signingInput), options.key ?? googleKey.privateKey);
  return `${signingInput}.${signature.toString("base64url")}`;
}

const keys: GoogleKeySource = {
  async keyFor(kid) {
    return kid === "google-kid" ? googleKey.jwk : null;
  },
};

class MemoryDirectory implements GoogleAccountDirectory {
  lookups: string[] = [];
  constructor(private readonly owners: Record<string, string> = {}) {}
  async uidForGoogleSubject(subject: string) {
    this.lookups.push(subject);
    return this.owners[subject] ?? null;
  }
}

function request(data: unknown): CallableRequest<unknown> {
  return { data, rawRequest: {} as never, acceptsStreaming: false } as CallableRequest<unknown>;
}

async function rejection(promise: Promise<unknown>): Promise<HttpsError> {
  try {
    await promise;
  } catch (error) {
    expect(error).toBeInstanceOf(HttpsError);
    return error as HttpsError;
  }
  throw new Error("expected a rejection");
}

describe("verifyGoogleIdToken", () => {
  it("accepts a Google-signed token for a configured audience", async () => {
    await expect(verifyGoogleIdToken(token(), [audience], keys, now)).resolves.toEqual({
      subject: "google-sub-1",
    });
  });

  it.each([
    ["a foreign signature", token({}, { key: attackerKey.privateKey }), "signature"],
    ["another audience", token({ aud: "other-app.apps.googleusercontent.com" }), "audience"],
    ["another issuer", token({ iss: "https://evil.example" }), "issuer"],
    ["an expired token", token({ exp: now - 1 }), "expired"],
    ["a token issued in the future", token({ iat: now + 3600 }), "issued-at"],
    ["a missing subject", token({ sub: "" }), "subject"],
    ["an unknown key", token({}, { header: { kid: "rotated-away" } }), "unknown-key"],
    ["an unsigned algorithm", token({}, { header: { alg: "none" } }), "algorithm"],
    ["a malformed token", "not.a-token", "malformed"],
  ])("rejects %s", async (_label, idToken, reason) => {
    await expect(verifyGoogleIdToken(idToken, [audience], keys, now)).rejects.toMatchObject({ reason });
  });
});

describe("probeGoogleIdentity", () => {
  it("answers existing for a Google account that already opens an account, without revealing it", async () => {
    const directory = new MemoryDirectory({ "google-sub-1": "uid-A" });
    const handler = createProbeGoogleIdentityHandler({
      audiences: () => [audience],
      keys,
      accounts: directory,
      now: () => now,
    });
    const response = await handler(request({ idToken: token() }));
    expect(response).toEqual({ status: "existing" });
    expect(JSON.stringify(response)).not.toContain("uid-A");
    expect(directory.lookups).toEqual(["google-sub-1"]);
  });

  it("answers unknown for a new Google account and creates nothing", async () => {
    const directory = new MemoryDirectory();
    const handler = createProbeGoogleIdentityHandler({
      audiences: () => [audience],
      keys,
      accounts: directory,
      now: () => now,
    });
    await expect(handler(request({ idToken: token() }))).resolves.toEqual({ status: "unknown" });
  });

  it("never looks up an account for a forged token", async () => {
    const directory = new MemoryDirectory({ "google-sub-1": "uid-A" });
    const handler = createProbeGoogleIdentityHandler({
      audiences: () => [audience],
      keys,
      accounts: directory,
      now: () => now,
    });
    const error = await rejection(handler(request({ idToken: token({}, { key: attackerKey.privateKey }) })));
    expect(error.code).toBe("unauthenticated");
    expect(directory.lookups).toEqual([]);
  });

  it("refuses when no OAuth client is configured", async () => {
    const handler = createProbeGoogleIdentityHandler({
      audiences: () => [],
      keys,
      accounts: new MemoryDirectory(),
      now: () => now,
    });
    const error = await rejection(handler(request({ idToken: token() })));
    expect(error.code).toBe("failed-precondition");
  });

  it("rejects a missing token as an invalid argument", async () => {
    const handler = createProbeGoogleIdentityHandler({
      audiences: () => [audience],
      keys,
      accounts: new MemoryDirectory(),
      now: () => now,
    });
    const error = await rejection(handler(request({})));
    expect(error.code).toBe("invalid-argument");
  });

  it("reports Google key outages as unavailable", async () => {
    const handler = createProbeGoogleIdentityHandler({
      audiences: () => [audience],
      keys: new HttpGoogleKeySource(async () => {
        throw new Error("offline");
      }),
      accounts: new MemoryDirectory(),
      now: () => now,
    });
    const error = await rejection(handler(request({ idToken: token() })));
    expect(error.code).toBe("unavailable");
  });
});

describe("HttpGoogleKeySource", () => {
  it("caches keys and refreshes an unknown kid at most once a minute", async () => {
    let fetches = 0;
    let clock = 0;
    const source = new HttpGoogleKeySource(
      async () => {
        fetches++;
        return { keys: [googleKey.jwk], maxAgeSeconds: 3600 };
      },
      () => clock,
    );
    expect(await source.keyFor("google-kid")).toEqual(googleKey.jwk);
    expect(await source.keyFor("google-kid")).toEqual(googleKey.jwk);
    expect(fetches).toBe(1);
    clock = 30_000;
    expect(await source.keyFor("missing")).toBeNull();
    expect(fetches).toBe(1);
    clock = 90_000;
    expect(await source.keyFor("missing")).toBeNull();
    expect(fetches).toBe(2);
  });

  it("keeps serving cached keys when a refresh fails", async () => {
    let clock = 0;
    let online = true;
    const source = new HttpGoogleKeySource(
      async () => {
        if (!online) throw new Error("offline");
        return { keys: [googleKey.jwk], maxAgeSeconds: 60 };
      },
      () => clock,
    );
    await source.keyFor("google-kid");
    online = false;
    clock = 10 * 60_000;
    expect(await source.keyFor("google-kid")).toEqual(googleKey.jwk);
  });

  it("fails loudly when no key was ever fetched", async () => {
    const source = new HttpGoogleKeySource(async () => {
      throw new Error("offline");
    });
    await expect(source.keyFor("google-kid")).rejects.toBeInstanceOf(GoogleKeysUnavailable);
  });
});

describe("parseGoogleClientIds", () => {
  it("splits and trims the configured client list", () => {
    expect(parseGoogleClientIds(" a.apps.googleusercontent.com , ,b.apps.googleusercontent.com")).toEqual([
      "a.apps.googleusercontent.com",
      "b.apps.googleusercontent.com",
    ]);
    expect(parseGoogleClientIds(undefined)).toEqual([]);
  });
});
