/**
 * Budget déterministe d'une requête tuteur.
 *
 * Deux niveaux de bornes :
 * 1. la validation d'entrée (`utils/validation.ts`) refuse tout payload qui
 *    dépasse ce qu'un client, même ancien, envoie légitimement ;
 * 2. ce module réduit ensuite ce qui part réellement au modèle, quelle que soit
 *    la version du client : fenêtre d'historique, taille par message, taille
 *    totale.
 *
 * Aucune estimation monétaire ici : seules des bornes en caractères et en
 * jetons, vérifiables.
 */

/** Question de l'élève (inchangé : ce que l'application permet déjà). */
export const MAX_USER_MESSAGE_CHARS = 2_000;

/**
 * Bornes de validation de l'historique. Les versions installées envoient
 * jusqu'à 20 messages de 4 000 caractères : on les accepte encore (payload
 * borné à ~80 Ko), mais on n'en transmet qu'une fenêtre au modèle.
 */
export const MAX_HISTORY_ITEMS_ACCEPTED = 20;
export const MAX_HISTORY_ITEM_CHARS_ACCEPTED = 4_000;

/**
 * Fenêtre envoyée au modèle : les 8 derniers messages (4 échanges), 1 200
 * caractères chacun (~200 mots, la longueur d'une explication courte), 6 000
 * caractères au total. Au-delà, le fil ancien apporte peu et coûte à chaque
 * tour ; les échanges les plus récents sont conservés en priorité.
 */
export const MAX_HISTORY_MESSAGES = 8;
export const MAX_CHARS_PER_HISTORY_MESSAGE = 1_200;
export const MAX_HISTORY_CHARS = 6_000;

/** Contexte de cours autorisé (3 leçons au plus, déjà tronqué à 5 000). */
export const MAX_ACADEMIC_CONTEXT_CHARS = 5_000;

/** Prompt système canonique (persona + règles + consignes d'activité). */
export const MAX_SYSTEM_PROMPT_CHARS = 7_000;

/** Compte rendu d'une activité interactive transmis au tour suivant. */
export const MAX_ACTIVITY_OUTCOME_CHARS = 600;

/**
 * Plafond absolu de texte envoyé au modèle (système + contexte + historique +
 * question + cadre). Le pire cas de tokenisation étant d'un jeton par
 * caractère, l'entrée ne dépasse jamais 22 000 jetons ; en français courant
 * (~4 caractères par jeton) elle reste sous ~5 500 jetons.
 */
export const MAX_TOTAL_INPUT_CHARS = 22_000;
export const MAX_INPUT_TOKENS_WORST_CASE = MAX_TOTAL_INPUT_CHARS;

/**
 * Sortie du tuteur. Avec un niveau de réflexion HIGH, les jetons de réflexion
 * sont facturés comme de la sortie et comptent dans ce plafond : 8 192 laisse
 * de la place à une réflexion longue puis à une réponse de ~500 mots, tout en
 * bornant chaque tour. Une réponse coupée sans texte est traitée comme un échec
 * facturé (voir askTutorUseCase), jamais comme un appel gratuit.
 */
export const MAX_TUTOR_OUTPUT_TOKENS = 8_192;

/** Générations structurées (quiz, résumé). */
export const MAX_STRUCTURED_OUTPUT_TOKENS = 8_192;

/** Import de pages de cours : leçon + QCM + exercices + cartes Parcours. */
export const MAX_COURSE_IMPORT_OUTPUT_TOKENS = 32_768;

export interface TutorHistoryItem {
  role: "user" | "assistant";
  text: string;
}

/**
 * Garde la fin d'un texte trop long : dans un échange, c'est la partie la plus
 * récente qui porte la question ou la conclusion utile.
 */
export function clipTail(text: string, max: number): string {
  const trimmed = text.trim();
  if (trimmed.length <= max) return trimmed;
  return `…${trimmed.slice(trimmed.length - (max - 1))}`;
}

/** Fenêtre d'historique bornée, du plus récent au plus ancien. */
export function boundTutorHistory(
  history: readonly TutorHistoryItem[],
  limits: {
    maxMessages?: number;
    maxCharsPerMessage?: number;
    maxTotalChars?: number;
  } = {},
): TutorHistoryItem[] {
  const maxMessages = limits.maxMessages ?? MAX_HISTORY_MESSAGES;
  const maxCharsPerMessage = limits.maxCharsPerMessage ?? MAX_CHARS_PER_HISTORY_MESSAGE;
  const maxTotalChars = limits.maxTotalChars ?? MAX_HISTORY_CHARS;
  const kept: TutorHistoryItem[] = [];
  let total = 0;
  for (let index = history.length - 1; index >= 0 && kept.length < maxMessages; index--) {
    const item = history[index];
    const text = clipTail(item.text, maxCharsPerMessage);
    if (!text) continue;
    if (total + text.length > maxTotalChars) break;
    total += text.length;
    kept.unshift({ role: item.role, text });
  }
  return kept;
}
