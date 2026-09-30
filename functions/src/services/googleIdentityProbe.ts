import { createPublicKey, verify, type JsonWebKey } from "node:crypto";

import axios from "axios";
import { getAuth } from "firebase-admin/auth";
import { logger } from "firebase-functions";
import { HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import { z } from "zod";

/**
 * Sonde d'identité Google : « ce compte Google ouvre-t-il déjà un compte
 * INTELLIA237 ? », sans jamais créer d'utilisateur.
 *
 * Registre de décisions (refonte Auth V2, P0-2 de la revue de 7ea5cf0) :
 * `signInWithCredential` côté client crée un utilisateur Firebase pour tout
 * compte Google inconnu, et le SDK client n'offre aucun moyen de tester une
 * preuve fédérée sans connexion. Un parent déjà connu par téléphone recevait
 * donc un second UID avant de pouvoir dire « j'ai déjà un compte ». Le
 * serveur vérifie ici le jeton Google (signature RS256, émetteur, audience,
 * expiration) et cherche l'UID qui porte ce `sub` Google.
 *
 * Confidentialité : la réponse ne dit que `existing` ou `unknown`, jamais
 * d'UID, de rôle ni d'adresse ; elle ne parle qu'au détenteur d'un jeton
 * Google frais émis pour l'application, sur son propre compte. Aucune
 * recherche par adresse e-mail : l'identité n'est jamais déduite d'une
 * adresse.
 */

export const googleIdTokenIssuers = ["accounts.google.com", "https://accounts.google.com"];
const googleCertsUrl = "https://www.googleapis.com/oauth2/v3/certs";
const clockSkewSeconds = 300;

export interface VerifiedGoogleIdentity {
  subject: string;
}

export class InvalidGoogleIdToken extends Error {
  constructor(readonly reason: string) {
    super(`Invalid Google ID token: ${reason}`);
  }
}

export class GoogleKeysUnavailable extends Error {}

export interface GoogleKeySource {
  keyFor(kid: string): Promise<JsonWebKey | null>;
}

/** Clés publiques de Google, en cache selon `Cache-Control`. */
export class HttpGoogleKeySource implements GoogleKeySource {
  private keys = new Map<string, JsonWebKey>();
  private expiresAtMs = 0;
  private lastRefreshMs = 0;

  constructor(
    private readonly fetchKeys: () => Promise<{ keys: JsonWebKey[]; maxAgeSeconds: number }> =
      fetchGoogleKeys,
    private readonly now: () => number = Date.now,
  ) {}

  async keyFor(kid: string): Promise<JsonWebKey | null> {
    const stale = this.now() >= this.expiresAtMs;
    // Un `kid` inconnu déclenche au plus un rafraîchissement par minute : une
    // rotation de clés est suivie sans permettre de marteler Google.
    const unknownKid = !this.keys.has(kid) && this.now() - this.lastRefreshMs > 60_000;
    if (stale || unknownKid) await this.refresh();
    return this.keys.get(kid) ?? null;
  }

  private async refresh(): Promise<void> {
    let fetched: { keys: JsonWebKey[]; maxAgeSeconds: number };
    try {
      fetched = await this.fetchKeys();
    } catch {
      if (this.keys.size > 0) return;
      throw new GoogleKeysUnavailable("Google signing keys are unavailable.");
    }
    this.keys = new Map(
      fetched.keys
        .filter((key): key is JsonWebKey & { kid: string } => typeof key.kid === "string")
        .map((key) => [key.kid as string, key]),
    );
    this.lastRefreshMs = this.now();
    this.expiresAtMs = this.now() + Math.max(60, fetched.maxAgeSeconds) * 1000;
  }
}

async function fetchGoogleKeys(): Promise<{ keys: JsonWebKey[]; maxAgeSeconds: number }> {
  const response = await axios.get<{ keys?: JsonWebKey[] }>(googleCertsUrl, { timeout: 5000 });
  const cacheControl = String(response.headers["cache-control"] ?? "");
  const maxAge = /max-age=(\d+)/.exec(cacheControl)?.[1];
  return {
    keys: Array.isArray(response.data.keys) ? response.data.keys : [],
    maxAgeSeconds: maxAge ? Number(maxAge) : 3600,
  };
}

function decodeSegment(segment: string): Record<string, unknown> {
  try {
    const parsed: unknown = JSON.parse(Buffer.from(segment, "base64url").toString("utf8"));
    if (parsed && typeof parsed === "object" && !Array.isArray(parsed)) {
      return parsed as Record<string, unknown>;
    }
  } catch {
    // Traité ci-dessous comme un jeton mal formé.
  }
  throw new InvalidGoogleIdToken("malformed");
}

/**
 * Vérifie un jeton d'identité Google (OpenID Connect) et renvoie son `sub`.
 */
export async function verifyGoogleIdToken(
  idToken: string,
  audiences: readonly string[],
  keys: GoogleKeySource,
  nowSeconds: number = Math.floor(Date.now() / 1000),
): Promise<VerifiedGoogleIdentity> {
  const parts = idToken.split(".");
  if (parts.length !== 3 || parts.some((part) => part.length === 0)) {
    throw new InvalidGoogleIdToken("malformed");
  }
  const [encodedHeader, encodedPayload, encodedSignature] = parts;
  const header = decodeSegment(encodedHeader);
  if (header.alg !== "RS256" || typeof header.kid !== "string") {
    throw new InvalidGoogleIdToken("algorithm");
  }
  const jwk = await keys.keyFor(header.kid);
  if (!jwk) throw new InvalidGoogleIdToken("unknown-key");

  const signatureValid = verify(
    "RSA-SHA256",
    Buffer.from(`${encodedHeader}.${encodedPayload}`),
    createPublicKey({ key: jwk, format: "jwk" }),
    Buffer.from(encodedSignature, "base64url"),
  );
  if (!signatureValid) throw new InvalidGoogleIdToken("signature");

  const payload = decodeSegment(encodedPayload);
  if (typeof payload.iss !== "string" || !googleIdTokenIssuers.includes(payload.iss)) {
    throw new InvalidGoogleIdToken("issuer");
  }
  const audience = payload.aud;
  const audienceList = Array.isArray(audience) ? audience : [audience];
  if (!audienceList.some((value) => typeof value === "string" && audiences.includes(value))) {
    throw new InvalidGoogleIdToken("audience");
  }
  if (typeof payload.exp !== "number" || payload.exp <= nowSeconds) {
    throw new InvalidGoogleIdToken("expired");
  }
  if (typeof payload.iat !== "number" || payload.iat > nowSeconds + clockSkewSeconds) {
    throw new InvalidGoogleIdToken("issued-at");
  }
  if (typeof payload.sub !== "string" || payload.sub.length === 0) {
    throw new InvalidGoogleIdToken("subject");
  }
  return { subject: payload.sub };
}

/** Qui porte ce compte Google, sans rien créer. */
export interface GoogleAccountDirectory {
  uidForGoogleSubject(subject: string): Promise<string | null>;
}

export class FirebaseGoogleAccountDirectory implements GoogleAccountDirectory {
  async uidForGoogleSubject(subject: string): Promise<string | null> {
    try {
      const user = await getAuth().getUserByProviderUid("google.com", subject);
      return user.uid;
    } catch (error) {
      if ((error as { code?: string }).code === "auth/user-not-found") return null;
      throw error;
    }
  }
}

/** Identifiants OAuth autorisés comme audience, séparés par des virgules. */
export function parseGoogleClientIds(raw: string | undefined): string[] {
  return (raw ?? "")
    .split(",")
    .map((value) => value.trim())
    .filter((value) => value.length > 0);
}

const probeInput = z.object({ idToken: z.string().min(20).max(8192) });

export function createProbeGoogleIdentityHandler(deps: {
  audiences: () => readonly string[];
  keys?: GoogleKeySource;
  accounts?: GoogleAccountDirectory;
  now?: () => number;
}) {
  const keys = deps.keys ?? new HttpGoogleKeySource();
  const accounts = deps.accounts ?? new FirebaseGoogleAccountDirectory();
  const now = deps.now ?? (() => Math.floor(Date.now() / 1000));

  return async (request: CallableRequest<unknown>): Promise<{ status: "existing" | "unknown" }> => {
    const audiences = deps.audiences();
    if (audiences.length === 0) {
      logger.error("GOOGLE_OAUTH_CLIENT_IDS is not configured.");
      throw new HttpsError("failed-precondition", "Google sign-in is not configured.");
    }
    const parsed = probeInput.safeParse(request.data);
    if (!parsed.success) {
      throw new HttpsError("invalid-argument", "A Google ID token is required.");
    }

    let identity: VerifiedGoogleIdentity;
    try {
      identity = await verifyGoogleIdToken(parsed.data.idToken, audiences, keys, now());
    } catch (error) {
      if (error instanceof GoogleKeysUnavailable) {
        throw new HttpsError("unavailable", "Google verification is temporarily unavailable.");
      }
      const reason = error instanceof InvalidGoogleIdToken ? error.reason : "unexpected";
      logger.warn("Rejected Google ID token.", { reason });
      throw new HttpsError("unauthenticated", "Invalid Google ID token.");
    }

    const uid = await accounts.uidForGoogleSubject(identity.subject);
    // Aucun identifiant, aucune adresse dans les journaux.
    logger.info("Google identity probed.", { known: uid !== null });
    return { status: uid === null ? "unknown" : "existing" };
  };
}
