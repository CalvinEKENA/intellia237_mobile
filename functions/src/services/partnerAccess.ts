import { createHash, createHmac, timingSafeEqual } from "node:crypto";

import { getAuth } from "firebase-admin/auth";
import { FieldValue, type Firestore } from "firebase-admin/firestore";
import { logger } from "firebase-functions";
import { HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import { z } from "zod";

import { db } from "../config/firebase";
import {
  FirestoreDemoAccountStore,
  type DemoAccountStore,
  type DemoClassAccess,
  type SeededStudentIdentity,
} from "./demoAccess";
import { clientIdentity, type CustomTokenIssuer } from "./studentAccessCode";

/**
 * Accès partenaire : un compte de test canonique, « démo pour Francis »,
 * ouvert par une valeur secrète connue de son seul titulaire, sans mot de
 * passe, sans code et sans lien.
 *
 * LA VALEUR N'EST PAS DANS LE DÉPÔT. Elle vit dans Secret Manager
 * (`PARTNER_ACCESS_EMAIL`), comme `DEMO_ACCESS_CODE` : le dépôt est public.
 * Sans ce secret, l'accès est fermé. Elle n'est jamais écrite nulle part
 * ailleurs : ni dans les journaux, ni dans le compte Firebase (aucune adresse
 * n'y est posée : pas de réinitialisation de mot de passe possible), ni dans
 * le profil.
 *
 * DÉCISION ASSUMÉE DU PROPRIÉTAIRE (29/09/2026) : cette valeur est un compte
 * de test privilégié connu de lui et de son partenaire ; la connaître suffit.
 * Ce n'est pas une preuve d'identité : le risque est borné par construction.
 *
 * - le compte est un ÉLÈVE ordinaire (aucun droit adulte, aucun
 *   établissement, aucune liaison parent, aucun droit d'administration) :
 *   seuls le contenu pédagogique et l'usage des fonctions élève sont ouverts ;
 * - c'est une vraie session Firebase (jeton personnalisé émis ICI, par le
 *   serveur) : les règles Firestore et Storage ne changent pas d'une ligne ;
 * - un seul compte, un seul UID : jamais de nouvel utilisateur à la connexion,
 *   la progression et l'historique restent ceux du même UID, quelle que soit
 *   la valeur secrète en vigueur ;
 * - essais massifs : App Check (réglage global du projet, ENFORCE_APP_CHECK),
 *   et un verrou par client après trop d'échecs ; tout refus, y compris
 *   verrouillé, reçoit la même réponse ;
 * - fermeture immédiate : `PARTNER_ACCESS_DISABLED=true` (redéploiement), ou
 *   désactiver l'utilisateur dans la console Authentification, ou retirer la
 *   fonction.
 */
export const partnerAccessUid = "intellia-demo-francis";

/** Le compte canonique. AUCUNE adresse (comme le compte démo) : la valeur
 * secrète ne se retrouve ni dans Firebase Authentication ni dans Firestore. */
export const partnerIdentity: SeededStudentIdentity = {
  uid: partnerAccessUid,
  displayName: "Francis",
  firstName: "Francis",
  lastName: "Partenaire",
  email: "",
  marker: "demoForFrancis",
};

/** Le compte partenaire peut changer sa classe, comme le compte démo. */
export const partnerClassAccess: DemoClassAccess = {
  uid: partnerAccessUid,
  claim: "demoForFrancis",
};

/**
 * Valeurs révoquées : condensats SHA-256 (hexadécimal, valeur normalisée) de
 * valeurs devenues publiques. Un secret qui porte l'une d'elles ferme l'accès,
 * même si quelqu'un la reconfigure par erreur. Ce sont des condensats : la
 * valeur elle-même n'est pas dans le dépôt.
 */
export const revokedPartnerEmailDigests: ReadonlySet<string> = new Set([
  "b2a96d8ac3d7a476ae5b55e5fc381b1ad0ad1944da35a1bb6c15aa9aeb7a648e",
]);

/** Espaces autour et casse ignorés : « PARTENAIRE@EXEMPLE.FR » vaut
 * « partenaire@exemple.fr ». Seule la valeur exacte, une fois normalisée, est
 * reconnue. */
export function normalizePartnerEmail(raw: unknown): string {
  return typeof raw === "string" ? raw.trim().toLowerCase() : "";
}

const digest = (value: string) => createHash("sha256").update(value).digest();

export function isRevokedPartnerEmail(
  raw: unknown,
  revoked: ReadonlySet<string> = revokedPartnerEmailDigests,
): boolean {
  const normalized = normalizePartnerEmail(raw);
  return normalized !== "" && revoked.has(digest(normalized).toString("hex"));
}

/** [configured] est la valeur lue dans le secret. Comparaison à temps
 * constant : la valeur attendue ne se devine pas au chronomètre. */
export function isPartnerEmail(raw: unknown, configured: string): boolean {
  const candidate = normalizePartnerEmail(raw);
  const expected = normalizePartnerEmail(configured);
  if (!candidate || !expected) return false;
  return timingSafeEqual(digest(candidate), digest(expected));
}

/**
 * Verrou par client (adresse IP hachée) contre les essais massifs. Seuil
 * volontairement bas : le titulaire, lui, ne se trompe jamais (l'application
 * n'appelle la fonction qu'avec la valeur reconnue).
 */
export const partnerAttemptLimit = {
  maxFailures: 10,
  windowMs: 15 * 60 * 1000,
  blockMs: 30 * 60 * 1000,
};

export interface PartnerAttemptLimiter {
  isBlocked(clientKey: string): Promise<boolean>;
  recordFailure(clientKey: string): Promise<void>;
  reset(clientKey: string): Promise<void>;
}

/**
 * Compteurs dans `student_access_attempts` (serveur seulement, règles
 * `allow read, write: if false`), sous des identifiants préfixés `partner-` :
 * aucune collection nouvelle, aucune règle à redéployer.
 */
export class FirestorePartnerAttemptLimiter implements PartnerAttemptLimiter {
  constructor(
    private readonly firestore: Firestore = db,
    private readonly now: () => number = Date.now,
  ) {}

  private ref(clientKey: string) {
    return this.firestore.collection("student_access_attempts").doc(`partner-${clientKey}`);
  }

  async isBlocked(clientKey: string): Promise<boolean> {
    const blockedUntilMs = (await this.ref(clientKey).get()).data()?.blockedUntilMs;
    return typeof blockedUntilMs === "number" && blockedUntilMs > this.now();
  }

  async recordFailure(clientKey: string): Promise<void> {
    const ref = this.ref(clientKey);
    await this.firestore.runTransaction(async (transaction) => {
      const now = this.now();
      const data = (await transaction.get(ref)).data();
      const windowStartMs = typeof data?.windowStartMs === "number" ? data.windowStartMs : 0;
      const withinWindow = now - windowStartMs <= partnerAttemptLimit.windowMs;
      const failures = withinWindow ? (Number(data?.failures) || 0) + 1 : 1;
      transaction.set(ref, {
        failures,
        windowStartMs: withinWindow ? windowStartMs : now,
        blockedUntilMs:
          failures >= partnerAttemptLimit.maxFailures
            ? now + partnerAttemptLimit.blockMs
            : typeof data?.blockedUntilMs === "number"
              ? data.blockedUntilMs
              : 0,
        updatedAt: FieldValue.serverTimestamp(),
      });
    });
  }

  async reset(clientKey: string): Promise<void> {
    await this.ref(clientKey)
      .delete()
      .catch(() => undefined);
  }
}

/** L'identité du client : l'IP que l'infrastructure Google a ajoutée, hachée
 * avec la valeur secrète elle-même (aucune adresse IP en clair en base, aucun
 * autre secret à gérer). */
export function partnerClientKey(client: { ip: string }, secret: string): string {
  return createHmac("sha256", secret).update(`partner-access-client:${client.ip}`).digest("hex");
}

const signInInput = z.object({ email: z.string().max(254) });

/** La seule réponse de refus : valeur fausse, presque juste, secret absent,
 * accès fermé ou client verrouillé, rien ne les distingue. */
const unavailable = () => new HttpsError("permission-denied", "Partner access is not available.");

/** La valeur du secret, ou vide si elle manque, n'a pas l'allure d'une adresse
 * ou est révoquée : l'accès est alors fermé. Jamais la valeur dans les
 * journaux. */
function configuredEmail(read: () => string, revoked: ReadonlySet<string>): string {
  let value: unknown;
  try {
    value = read();
  } catch {
    value = "";
  }
  const email = normalizePartnerEmail(value);
  if (email.length < 3 || email.length > 254 || !email.includes("@")) {
    logger.error("PARTNER_ACCESS_EMAIL is missing or invalid.");
    return "";
  }
  if (isRevokedPartnerEmail(email, revoked)) {
    logger.error("PARTNER_ACCESS_EMAIL holds a revoked value.");
    return "";
  }
  return email;
}

export interface PartnerAccessDependencies {
  accounts?: DemoAccountStore;
  tokens?: CustomTokenIssuer;
  isClosed?: () => boolean;
  limiter?: PartnerAttemptLimiter;
  revoked?: ReadonlySet<string>;
}

/**
 * Callable publique : échange la valeur secrète du partenaire contre un jeton
 * de son compte canonique. Tout autre cas reçoit la même réponse de refus,
 * sans rien créer.
 *
 * [readEmail] lit le secret à chaque appel (Secret Manager, jamais le dépôt).
 */
export function createSignInWithPartnerAccessHandler(
  readEmail: () => string,
  dependencies: PartnerAccessDependencies = {},
) {
  const accounts =
    dependencies.accounts ?? new FirestoreDemoAccountStore(db, getAuth(), partnerIdentity);
  const tokens = dependencies.tokens ?? getAuth();
  const isClosed = dependencies.isClosed ?? (() => process.env.PARTNER_ACCESS_DISABLED === "true");
  const limiter = dependencies.limiter ?? new FirestorePartnerAttemptLimiter();
  const revoked = dependencies.revoked ?? revokedPartnerEmailDigests;

  return async (request: CallableRequest<unknown>): Promise<{ token: string }> => {
    if (isClosed()) throw unavailable();
    const configured = configuredEmail(readEmail, revoked);
    if (!configured) throw unavailable();

    const clientKey = partnerClientKey(clientIdentity(request), configured);
    let blocked = true;
    try {
      blocked = await limiter.isBlocked(clientKey);
    } catch {
      // Le verrou est illisible : dans le doute, refuser.
      logger.error("Partner access limiter is unreadable.");
    }
    if (blocked) {
      logger.warn("Partner access blocked.");
      throw unavailable();
    }

    const parsed = signInInput.safeParse(request.data);
    if (!parsed.success || !isPartnerEmail(parsed.data.email, configured)) {
      await limiter.recordFailure(clientKey).catch(() => undefined);
      throw unavailable();
    }

    await limiter.reset(clientKey).catch(() => undefined);
    await accounts.ensureAccount(partnerAccessUid);
    const token = await tokens.createCustomToken(partnerAccessUid, {
      accessMethod: "partner_access",
      demoForFrancis: true,
    });
    // Aucune valeur secrète dans les journaux.
    logger.info("Partner access opened.");
    return { token };
  };
}
