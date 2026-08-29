export type FlowAnswer = string | number | boolean | string[] | null;
export type FlowActivityKind = "content" | "choice" | "boolean" | "text" | "ordering";

export interface FlowCatalogEntry {
  readonly kind: FlowActivityKind;
  readonly pointsReward: number;
  readonly acceptedAnswers?: readonly FlowAnswer[];
}

const content = (pointsReward: number): FlowCatalogEntry => ({
  kind: "content",
  pointsReward
});
const choice = (correctIndex: number, pointsReward = 25): FlowCatalogEntry => ({
  kind: "choice",
  pointsReward,
  acceptedAnswers: [correctIndex]
});
const booleanAnswer = (answer: boolean): FlowCatalogEntry => ({
  kind: "boolean",
  pointsReward: 18,
  acceptedAnswers: [answer]
});
const textAnswer = (...answers: string[]): FlowCatalogEntry => ({
  kind: "text",
  pointsReward: 22,
  acceptedAnswers: answers
});
const ordering = (...items: string[]): FlowCatalogEntry => ({
  kind: "ordering",
  pointsReward: 25,
  acceptedAnswers: [items]
});

/**
 * Catalogue de récompenses FLOW publié avec les Functions.
 *
 * Le client contient une copie éditoriale pour le rendu et le feedback rapide,
 * mais cette allowlist est l'unique autorité pour la correction et les points.
 */
export const FLOW_CATALOG: Readonly<Record<string, FlowCatalogEntry>> = {
  "m-pythagore": content(12),
  "m-parabole": content(12),
  "reward-1": content(0),
  "pc-volta": content(10),
  "pc-pendule": content(12),
  "pc-ciel-bleu": content(10),
  "svt-photosynthese": content(15),
  "svt-mitose": content(12),
  "reward-2": content(0),
  "fr-mongo-beti": content(10),
  "fr-metaphore": content(12),
  "en-polite": content(10),
  "philo-conscience": content(12),
  "reward-final": content(0),

  "m-quiz-pythagore": choice(0),
  "svt-quiz-photo": choice(0),
  "en-quiz": choice(0),
  "math-equation-1": choice(1),
  "math-fraction-1": choice(2),
  "math-percent-1": choice(2),
  "pc-ohm-1": choice(2),
  "pc-energy-1": choice(0),
  "pc-density-1": choice(0),
  "svt-cell-1": choice(0),
  "svt-blood-1": choice(0),
  "svt-ecosystem-1": choice(0),
  "fr-grammar-1": choice(0),
  "fr-figure-1": choice(0),
  "fr-agreement-1": choice(0),
  "en-tense-1": choice(0),
  "en-vocab-1": choice(0),
  "en-past-1": choice(0),
  "hg-cameroon-1": choice(0),
  "hg-capital-1": choice(0),
  "hg-climate-1": choice(0),
  "philo-truth-1": choice(0),
  "philo-freedom-1": choice(0),

  "tf-math-square": booleanAnswer(true),
  "tf-pc-series-current": booleanAnswer(true),
  "tf-svt-genes": booleanAnswer(true),
  "tf-hg-capital": booleanAnswer(false),

  "fill-math-equation": textAnswer("6", "six"),
  "fill-fr-author": textAnswer("Mongo Beti", "Beti"),
  "fill-en-past-go": textAnswer("went"),
  "fill-svt-photosynthesis": textAnswer("carbone", "carbone co2", "CO2"),

  "order-math-equation": ordering(
    "Soustraire 5 aux deux membres",
    "Obtenir 3x = 15",
    "Diviser les deux membres par 3",
    "Vérifier que x = 5"
  ),
  "order-science-method": ordering(
    "Observer un phénomène",
    "Formuler une hypothèse",
    "Réaliser une expérience",
    "Interpréter et conclure"
  ),
  "order-fr-narrative": ordering(
    "Situation initiale",
    "Élément perturbateur",
    "Péripéties",
    "Dénouement",
    "Situation finale"
  ),
  "order-hg-cameroon": ordering(
    "Indépendance du Cameroun oriental — 1960",
    "Réunification — 1961",
    "État unitaire — 1972"
  )
};

export function isAcceptedFlowAnswer(
  entry: FlowCatalogEntry,
  answer: FlowAnswer
): boolean {
  if (entry.kind === "content") {
    return answer === null;
  }
  return (entry.acceptedAnswers ?? []).some((accepted) =>
    normalizedFlowAnswer(accepted) === normalizedFlowAnswer(answer)
  );
}

export function normalizedFlowAnswer(answer: FlowAnswer): string {
  if (Array.isArray(answer)) {
    return JSON.stringify(answer.map((item) => normalizeText(item)));
  }
  if (typeof answer === "string") {
    return normalizeText(answer);
  }
  return JSON.stringify(answer);
}

function normalizeText(value: string): string {
  return value
    .trim()
    .toLocaleLowerCase("fr")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[’‘`´]/g, "'")
    .replace(/[^a-z0-9']+/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}
