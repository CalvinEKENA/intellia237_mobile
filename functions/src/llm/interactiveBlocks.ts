import { randomBytes } from "node:crypto";

import { z } from "zod";

import type { TutorLanguage } from "./tutorPersonas";

/**
 * Blocs d'apprentissage interactifs proposés par Kira ou Léo.
 *
 * Le modèle propose un CONTENU ; il ne choisit jamais une interface, une
 * route, une action serveur ni un composant. Le serveur :
 * - n'accepte que les types réellement rendus par l'application ET déclarés
 *   par le client dans `activities` ;
 * - valide un schéma strict, borné en taille ;
 * - fabrique lui-même les identifiants des éléments (le modèle ne fournit
 *   qu'une séquence de textes dans le bon ordre) ;
 * - retire le bloc du texte de la réponse ; un bloc invalide est ignoré,
 *   la réponse texte reste servie.
 *
 * Correction : validation LOCALE (hors ligne) pour ces activités
 * d'entraînement ; la solution voyage donc vers le téléphone. Une évaluation
 * notée devra passer par une validation serveur (clé de correction), comme
 * les quiz.
 */

/** Primitives d'interaction : une mécanique, plusieurs usages par matière. */
export const INTERACTION_PRIMITIVES = [
  "ordering",
  "choice",
  "binary",
  "gap_fill",
  "pairing",
  "grouping",
  "numeric",
  "labeling",
  "map",
  "data",
] as const;
export type InteractionPrimitive = (typeof INTERACTION_PRIMITIVES)[number];

interface BlockTypeSpec {
  primitive: InteractionPrimitive;
  /** Disposition du rendu pour les primitives qui en ont plusieurs. */
  layout?: "inline" | "stacked";
  /** Rendu livré dans l'application aujourd'hui. */
  supported: boolean;
}

/**
 * Registre des types. Seuls les types `supported` peuvent être émis ; les
 * autres sont l'architecture annoncée, refusée tant qu'aucun rendu n'existe.
 */
export const BLOCK_TYPES = {
  word_order: { primitive: "ordering", layout: "inline", supported: true },
  step_order: { primitive: "ordering", layout: "stacked", supported: true },
  equation_order: { primitive: "ordering", layout: "stacked", supported: true },
  timeline_order: { primitive: "ordering", layout: "stacked", supported: true },
  process_sequence: { primitive: "ordering", layout: "stacked", supported: true },
  sequence: { primitive: "ordering", layout: "stacked", supported: true },
  multiple_choice: { primitive: "choice", supported: false },
  true_false: { primitive: "binary", supported: false },
  fill_blank: { primitive: "gap_fill", supported: false },
  sentence_correction: { primitive: "gap_fill", supported: false },
  matching: { primitive: "pairing", supported: false },
  expression_match: { primitive: "pairing", supported: false },
  formula_match: { primitive: "pairing", supported: false },
  unit_match: { primitive: "pairing", supported: false },
  element_match: { primitive: "pairing", supported: false },
  label_match: { primitive: "pairing", supported: false },
  event_match: { primitive: "pairing", supported: false },
  cause_effect_match: { primitive: "pairing", supported: false },
  claim_match: { primitive: "pairing", supported: false },
  classification: { primitive: "grouping", supported: false },
  argument_classification: { primitive: "grouping", supported: false },
  sorting: { primitive: "grouping", supported: false },
  numeric_input: { primitive: "numeric", supported: false },
  value_input: { primitive: "numeric", supported: false },
  text_evidence: { primitive: "choice", supported: false },
  diagram_labeling: { primitive: "labeling", supported: false },
  map_interaction: { primitive: "map", supported: false },
  data_interpretation: { primitive: "data", supported: false },
} as const satisfies Record<string, BlockTypeSpec>;

export type BlockType = keyof typeof BLOCK_TYPES;

export const SUPPORTED_BLOCK_TYPES = (Object.keys(BLOCK_TYPES) as BlockType[])
  .filter((type) => BLOCK_TYPES[type].supported);

export const ACTIVITY_OPEN = "<<<ACTIVITY";
export const ACTIVITY_CLOSE = "ACTIVITY>>>";

/** Bornes du bloc : un exercice court, lisible sur un téléphone de 360 px. */
export const BLOCK_LIMITS = {
  maxRawChars: 4_000,
  instructionChars: 160,
  inlineItems: { min: 2, max: 10 },
  inlineItemChars: 24,
  stackedItems: { min: 2, max: 8 },
  stackedItemChars: 140,
  hints: 3,
  hintChars: 160,
  explanationChars: 400,
  rationaleChars: 160,
} as const;

/** Nettoie un texte : ni contrôle, ni marqueur, espaces normalisés. */
function clean(value: string): string {
  return value.replace(/[\u0000-\u001f\u007f]/g, " ").replace(/\s+/g, " ").trim();
}

const text = (max: number) =>
  z.string().transform(clean).refine((value) => value.length > 0 && value.length <= max, {
    message: "text out of bounds",
  }).refine((value) => !value.includes("<<<") && !value.includes(">>>"), {
    message: "marker in text",
  });

const proposalSchema = z.object({
  type: z.string(),
  instruction: text(BLOCK_LIMITS.instructionChars).optional(),
  sequence: z.array(z.string()).min(2).max(BLOCK_LIMITS.inlineItems.max),
  trailing: z.enum([".", "?", "!"]).optional(),
  hints: z.array(text(BLOCK_LIMITS.hintChars)).max(BLOCK_LIMITS.hints).default([]),
  explanation: text(BLOCK_LIMITS.explanationChars).optional(),
  difficulty: z.number().int().min(1).max(3).default(1),
  rationale: text(BLOCK_LIMITS.rationaleChars).optional(),
  language: z.string().optional(),
  subject: z.string().max(60).optional(),
}).strict();

export type OrderingBlock = {
  version: 1;
  id: string;
  type: BlockType;
  primitive: "ordering";
  layout: "inline" | "stacked";
  language: TutorLanguage;
  subject?: string;
  instruction?: string;
  items: Array<{ id: string; text: string }>;
  solution: string[];
  trailing?: "." | "?" | "!";
  hints: string[];
  explanation?: string;
  difficulty: number;
  rationale?: string;
};

export type InteractiveBlock = OrderingBlock;

/** Types que le client sait rendre ET que le serveur sait valider. */
export function negotiateActivityTypes(requested: readonly string[] | undefined): BlockType[] {
  if (!requested || requested.length === 0) return [];
  const asked = new Set(requested);
  return SUPPORTED_BLOCK_TYPES.filter((type) => asked.has(type));
}

function opaqueId(prefix: string): string {
  return `${prefix}_${randomBytes(6).toString("hex")}`;
}

/**
 * Sépare la réponse du compagnon et son éventuel bloc. Le texte renvoyé ne
 * contient jamais le marqueur, même quand le bloc est rejeté.
 */
export function extractInteractiveBlock(
  reply: string,
  params: { allowed: readonly BlockType[]; language: TutorLanguage; generateId?: (prefix: string) => string },
): { text: string; block: InteractiveBlock | null; rejection?: string } {
  const start = reply.lastIndexOf(ACTIVITY_OPEN);
  if (start < 0) return { text: reply.trim(), block: null };
  const end = reply.indexOf(ACTIVITY_CLOSE, start);
  const raw = reply.slice(start + ACTIVITY_OPEN.length, end < 0 ? undefined : end);
  const withoutBlock = `${reply.slice(0, start)}${end < 0 ? "" : reply.slice(end + ACTIVITY_CLOSE.length)}`
    .split(ACTIVITY_OPEN).join("").split(ACTIVITY_CLOSE).join("").trim();
  const reject = (reason: string) => ({ text: withoutBlock, block: null, rejection: reason });

  if (params.allowed.length === 0) return reject("activities_not_negotiated");
  if (end < 0) return reject("unterminated");
  if (raw.length > BLOCK_LIMITS.maxRawChars) return reject("too_large");
  let decoded: unknown;
  try {
    decoded = JSON.parse(raw.trim());
  } catch {
    return reject("invalid_json");
  }
  const parsed = proposalSchema.safeParse(decoded);
  if (!parsed.success) return reject("invalid_schema");
  const proposal = parsed.data;
  if (!(proposal.type in BLOCK_TYPES)) return reject("unknown_type");
  const type = proposal.type as BlockType;
  if (!params.allowed.includes(type)) return reject("type_not_allowed");
  const spec = BLOCK_TYPES[type];
  if (spec.primitive !== "ordering") return reject("type_not_rendered");

  const layout = spec.layout;
  const bounds = layout === "inline" ? BLOCK_LIMITS.inlineItems : BLOCK_LIMITS.stackedItems;
  const itemChars = layout === "inline" ? BLOCK_LIMITS.inlineItemChars : BLOCK_LIMITS.stackedItemChars;
  const texts = proposal.sequence.map(clean);
  if (texts.length < bounds.min || texts.length > bounds.max) return reject("item_count");
  if (texts.some((value) => value.length === 0 || value.length > itemChars)) return reject("item_length");
  if (texts.some((value) => value.includes("<<<") || value.includes(">>>"))) return reject("marker_in_item");
  // Sans deux textes différents, tout ordre serait juste : pas d'exercice.
  if (new Set(texts.map((value) => value.toLocaleLowerCase())).size < 2) return reject("not_orderable");
  if (layout !== "inline" && proposal.trailing !== undefined) return reject("trailing_on_stacked");

  const generate = params.generateId ?? opaqueId;
  const items = texts.map((value) => ({ id: generate("it"), text: value }));
  if (new Set(items.map((item) => item.id)).size !== items.length) return reject("id_collision");
  const language: TutorLanguage = proposal.language === "en" || proposal.language === "fr"
    ? proposal.language
    : params.language;

  return {
    text: withoutBlock,
    block: {
      version: 1,
      id: generate("blk"),
      type,
      primitive: "ordering",
      layout,
      language,
      ...(proposal.subject ? { subject: clean(proposal.subject) } : {}),
      ...(proposal.instruction ? { instruction: proposal.instruction } : {}),
      items,
      solution: items.map((item) => item.id),
      ...(proposal.trailing ? { trailing: proposal.trailing } : {}),
      hints: proposal.hints,
      ...(proposal.explanation ? { explanation: proposal.explanation } : {}),
      difficulty: proposal.difficulty,
      ...(proposal.rationale ? { rationale: proposal.rationale } : {}),
    },
  };
}

/**
 * Politique de choix par matière, donnée au modèle : une activité n'est pas
 * WORD_ORDER partout, elle suit la matière et l'objectif.
 */
const SELECTION_POLICY = {
  fr: [
    "anglais, français, langues : word_order pour reconstruire une phrase (mots dans le bon ordre)",
    "mathématiques : step_order ou equation_order pour remettre les étapes d'une résolution dans l'ordre",
    "physique, chimie : step_order pour un protocole ou un raisonnement ; equation_order pour les étapes d'un calcul",
    "SVT : process_sequence pour les étapes d'un processus biologique",
    "histoire : timeline_order pour des événements dans l'ordre chronologique",
    "géographie, philosophie, littérature : sequence pour un raisonnement ou une démarche en étapes",
  ],
  en: [
    "English, French, languages: word_order to rebuild a sentence (words in the right order)",
    "maths: step_order or equation_order to put the steps of a solution in order",
    "physics, chemistry: step_order for a protocol or reasoning; equation_order for calculation steps",
    "biology: process_sequence for the stages of a biological process",
    "history: timeline_order for events in chronological order",
    "geography, philosophy, literature: sequence for a reasoning in steps",
  ],
} as const;

/** Consignes d'activité ajoutées au prompt système quand le client les rend. */
export function buildActivityInstructions(
  allowed: readonly BlockType[],
  language: TutorLanguage,
): string | undefined {
  if (allowed.length === 0) return undefined;
  const types = allowed.join(", ");
  const policy = SELECTION_POLICY[language].map((line) => `- ${line}`).join("\n");
  const example = `${ACTIVITY_OPEN}\n{"type":"word_order","instruction":"...","sequence":["I","want","to","go"],"trailing":".","hints":["..."],"explanation":"...","difficulty":1,"rationale":"..."}\n${ACTIVITY_CLOSE}`;
  if (language === "en") {
    return `INTERACTIVE ACTIVITIES (optional):
- After explaining a notion, you may add ONE short activity to check understanding, only when it genuinely helps. Never during a personal or safety conversation.
- Allowed types: ${types}. Choose by subject and goal:
${policy}
- Match the learner's class level: short, familiar content for younger classes.
- "sequence" lists the items in the CORRECT order (2 to 10 words for word_order, each up to 24 characters; 2 to 8 steps otherwise, each up to 140 characters). Do not number the steps. "trailing" is only for final punctuation of a word_order sentence.
- "hints" are progressive (at most 3) and never give the whole answer; "explanation" is one or two sentences; "rationale" says in one sentence why this activity helps.
- Write the activity at the very end of your reply, exactly in this format, with valid JSON and nothing else inside:
${example}`;
  }
  return `ACTIVITÉS INTERACTIVES (facultatif) :
- Après avoir expliqué une notion, tu peux ajouter UNE courte activité pour vérifier la compréhension, seulement si elle aide vraiment. Jamais pendant une conversation personnelle ou de sécurité.
- Types autorisés : ${types}. Choisis selon la matière et l'objectif :
${policy}
- Adapte au niveau de la classe : contenu court et familier pour les petites classes.
- "sequence" donne les éléments dans le BON ordre (2 à 10 mots pour word_order, 24 caractères chacun au plus ; 2 à 8 étapes sinon, 140 caractères chacune au plus). Ne numérote pas les étapes. "trailing" sert seulement à la ponctuation finale d'une phrase word_order.
- "hints" sont progressifs (3 au plus) et ne donnent jamais toute la réponse ; "explanation" tient en une ou deux phrases ; "rationale" dit en une phrase pourquoi cette activité aide.
- Écris l'activité tout à la fin de ta réponse, exactement sous cette forme, avec un JSON valide et rien d'autre à l'intérieur :
${example}`;
}

/** Compte rendu d'une activité, envoyé avec le message suivant de l'élève. */
export const activityOutcomeSchema = z.object({
  blockId: z.string().min(1).max(40).regex(/^[A-Za-z0-9_-]+$/),
  type: z.enum(SUPPORTED_BLOCK_TYPES as [BlockType, ...BlockType[]]),
  correct: z.boolean(),
  attempts: z.number().int().min(0).max(20),
  hintsUsed: z.number().int().min(0).max(BLOCK_LIMITS.hints),
  solutionRevealed: z.boolean().default(false),
}).strict();

export type ActivityOutcome = z.infer<typeof activityOutcomeSchema>;

/** Phrase factuelle ajoutée au prompt : le compagnon observe et s'adapte. */
export function renderActivityOutcome(outcome: ActivityOutcome, language: TutorLanguage): string {
  if (language === "en") {
    const result = outcome.solutionRevealed
      ? "the solution was shown after several tries"
      : outcome.correct ? "solved" : "not solved yet";
    return `[Previous activity (${outcome.type}): ${result}, ${outcome.attempts} attempt(s), ${outcome.hintsUsed} hint(s). Adapt: build on success, re-explain the specific difficulty otherwise.]`;
  }
  const result = outcome.solutionRevealed
    ? "solution montrée après plusieurs essais"
    : outcome.correct ? "réussie" : "pas encore réussie";
  return `[Activité précédente (${outcome.type}) : ${result}, ${outcome.attempts} essai(s), ${outcome.hintsUsed} indice(s). Adapte-toi : prolonge en cas de réussite, sinon réexplique précisément la difficulté.]`;
}
