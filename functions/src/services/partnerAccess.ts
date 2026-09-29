import { getAuth } from "firebase-admin/auth";
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
import type { CustomTokenIssuer } from "./studentAccessCode";

/**
 * Accès partenaire : un compte de test canonique, « démo pour Francis »,
 * ouvert par l'adresse exacte de son titulaire, sans mot de passe, sans code
 * et sans lien.
 *
 * DÉCISION ASSUMÉE DU PROPRIÉTAIRE (29/09/2026) : cette adresse est un compte
 * de test privilégié connu de lui et de son partenaire ; la connaître suffit.
 * Ce n'est pas une preuve d'identité, et l'adresse est dans un dépôt public :
 * le risque est borné par construction.
 *
 * - le compte est un ÉLÈVE ordinaire (aucun droit adulte, aucun
 *   établissement, aucune liaison parent, aucun droit d'administration) :
 *   seuls le contenu pédagogique et l'usage des fonctions élève sont ouverts ;
 * - c'est une vraie session Firebase (jeton personnalisé émis ICI, par le
 *   serveur) : les règles Firestore et Storage ne changent pas d'une ligne ;
 * - un seul compte, un seul UID : jamais de nouvel utilisateur à la connexion,
 *   la progression et l'historique restent ceux du même UID ;
 * - fermeture immédiate : `PARTNER_ACCESS_DISABLED=true` (redéploiement), ou
 *   désactiver l'utilisateur dans la console Authentification, ou retirer la
 *   fonction.
 */
export const partnerAccessUid = "intellia-demo-francis";

/** L'adresse canonique : minuscules, sans espaces. */
export const partnerAccessEmail = "fran6farmer@yahoo.fr";

export const partnerIdentity: SeededStudentIdentity = {
  uid: partnerAccessUid,
  displayName: "Francis",
  firstName: "Francis",
  lastName: "Partenaire",
  email: partnerAccessEmail,
  marker: "demoForFrancis",
};

/** Le compte partenaire peut changer sa classe, comme le compte démo. */
export const partnerClassAccess: DemoClassAccess = {
  uid: partnerAccessUid,
  claim: "demoForFrancis",
};

/** Espaces autour et casse ignorés : « FRAN6FARMER@YAHOO.FR » vaut l'adresse
 * canonique. Seule l'adresse exacte, une fois normalisée, est reconnue. */
export function normalizePartnerEmail(raw: unknown): string {
  return typeof raw === "string" ? raw.trim().toLowerCase() : "";
}

export function isPartnerEmail(raw: unknown): boolean {
  return normalizePartnerEmail(raw) === partnerAccessEmail;
}

const signInInput = z.object({ email: z.string().max(254) });

const unavailable = () => new HttpsError("permission-denied", "Partner access is not available.");

/**
 * Callable publique : échange l'adresse exacte du partenaire contre un jeton
 * de son compte canonique. Toute autre adresse reçoit la même réponse de
 * refus, sans rien créer.
 */
export function createSignInWithPartnerAccessHandler(
  accounts: DemoAccountStore = new FirestoreDemoAccountStore(db, getAuth(), partnerIdentity),
  tokens: CustomTokenIssuer = getAuth(),
  isClosed: () => boolean = () => process.env.PARTNER_ACCESS_DISABLED === "true",
) {
  return async (request: CallableRequest<unknown>): Promise<{ token: string }> => {
    if (isClosed()) throw unavailable();
    const parsed = signInInput.safeParse(request.data);
    if (!parsed.success || !isPartnerEmail(parsed.data.email)) throw unavailable();
    await accounts.ensureAccount(partnerAccessUid);
    const token = await tokens.createCustomToken(partnerAccessUid, {
      accessMethod: "partner_access",
      demoForFrancis: true,
    });
    // Aucune adresse dans les journaux.
    logger.info("Partner access opened.");
    return { token };
  };
}
