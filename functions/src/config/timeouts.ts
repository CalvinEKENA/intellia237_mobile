/**
 * Contrat de délais du tuteur : fournisseur < callable < client.
 *
 * - le fournisseur (Vertex AI) dispose de 45 s ;
 * - le serveur a besoin d'au plus 15 s autour de l'appel (profil, contexte,
 *   transactions de quota, de Réserve d'étude et d'idempotence) ;
 * - la callable vit donc 75 s ;
 * - le téléphone attend 90 s (callable + 15 s de réseau), de sorte qu'il
 *   n'abandonne jamais une réponse que le serveur est encore en train de
 *   produire — et de facturer.
 *
 * `test/features/ai_companion/tutor_timeout_contract_test.dart` relit ce
 * fichier : toute modification ici doit rester cohérente avec le client.
 */
export const TUTOR_PROVIDER_TIMEOUT_MS = 45_000;
export const TUTOR_SERVER_OVERHEAD_BUDGET_MS = 15_000;
export const ASK_TUTOR_CALLABLE_TIMEOUT_SECONDS = 75;

/**
 * Une relance avec le même identifiant attend la fin de la première
 * exécution au plus ce délai, puis rend la main (la callable doit survivre).
 */
export const TUTOR_IN_PROGRESS_WAIT_MS = 45_000;
export const TUTOR_IN_PROGRESS_POLL_MS = 1_500;
