# Constats de la revue propriétaire — SHA 11eb26c

Revue en lecture seule du 22 septembre 2026, branche
`fix/release-hardening-sep2026` @ `11eb26cfe53d7291886b6c3a45e70d5eb5ff8927`
(identique sur origin). **Aucun de ces constats n’a été corrigé sur ce SHA** :
il devait rester celui soumis à la revue indépendante. Les corrections sont
faites sur `fix/release-hardening-review-fixes` : voir
`FIX_CYCLE_REPORT_2026-09-22.md`.

Gravité : **HIGH** bloque une mise en production ou le passage de la CI ;
**MEDIUM** risque réel, à traiter avant ou pendant la recette ; **LOW** défaut
limité ; **INFO** décision ou dette à connaître.

| ID | Gravité | Sujet |
| --- | --- | --- |
| QA-01 | HIGH | CI « Mobile quality » rouge sur ce SHA |
| QA-02 | HIGH | Nouvelle app incompatible avec l’ancien `askTutor` : ordre de déploiement imposé, retour arrière asymétrique |
| QA-03 | MEDIUM | Rétention de `tutor_requests` dépendante d’une politique TTL non déclarée |
| QA-04 | MEDIUM | `maxOutputTokens` 8 192 réflexion comprise, avec réflexion HIGH (non vérifié) |
| QA-05 | MEDIUM | Aucun environnement de recette de bout en bout prouvé (app sans émulateurs, staging sans Functions) |
| QA-06 | LOW | Parcours : cartes déjà terminées perdues dans les pages suivantes |
| QA-07 | LOW | Question à cheval sur minuit (Douala) non décomptée |
| QA-08 | LOW | Pas de borne de 2 000 caractères côté app |
| QA-09 | LOW | Mode Parcours indexé : curseur supprimé ou bascule du drapeau |
| QA-10 | LOW | Détection de fin de Parcours liée aux valeurs des constantes |
| QA-11 | LOW | Texte hors ligne du Quiz trop technique |
| QA-12 | LOW | Écran d’entrée : registre mélangé et libellé de bouton ambigu |
| QA-13 | INFO | Anciennes demandes de suppression : pas de procédure manuelle écrite |
| QA-14 | INFO | Un seul rôle par compte : le multi-rôle est impossible aujourd’hui |

---

## QA-01 — CI « Mobile quality » rouge sur ce SHA

- **Gravité** : HIGH (bloque la fusion ; l’analyse et les tests mobiles n’ont
  pas tourné en CI).
- **Fichier** : `docs/release/ASSET_INVENTORY_2026-09.md`, lignes 44 et 59.
- **Constat** : run GitHub `35666533200` (push de `11eb26c`), étape « Check
  legacy brand references » en échec : `tool/check_brand_references.dart`
  refuse deux mentions de l’ancienne marque dans ce document (écrit pendant le
  durcissement). Les étapes « Analyze » et « Test » ont été **sautées**. Les
  workflows « Backend quality » (tests unitaires, build, règles et
  intégration sur émulateurs) et « Studio quality » sont verts.
  Localement, `flutter analyze` et `flutter test` (1 550 / 1 550) passaient,
  mais ce contrôle n’avait pas été lancé.
- **Risque** : aucun effet en production ; la preuve CI de l’app mobile
  manque pour ce SHA.
- **Correction recommandée** : reformuler les deux lignes sans le nom de
  l’ancienne marque (par exemple « ancien logo »), ou ajouter
  `docs/release/ASSET_INVENTORY_2026-09.md` à `_skipFiles` avec une
  justification ; ajouter `dart run tool/check_brand_references.dart` à la
  routine locale de vérification.

## QA-02 — Nouvelle app incompatible avec l’ancien `askTutor`

- **Gravité** : HIGH (ordre de mise en production).
- **Fichiers** : `lib/features/ai_companion/data/cloud_ai_repository.dart:128`
  (l’app n’envoie plus que `tutorId`) ; schéma de la base `5e4f797`,
  `functions/src/utils/validation.ts:24-41` (`tutor` **obligatoire**) ; à HEAD,
  `functions/src/utils/validation.ts:68`.
- **Constat** : le serveur actuel de la base exige l’objet `tutor
  { name, specialty, personality, motto }`. La nouvelle app ne l’envoie plus.
  Nouvelle app + anciennes Functions ⇒ `invalid-argument` à chaque question
  (« Kira ne peut pas traiter cette question »). Même logique, moins grave :
  `cancelAccountDeletion` n’existe pas sur l’ancien serveur et l’ancienne
  règle refuse la lecture de `account_deletion_requests`.
  Le sens inverse est compatible : l’app déjà installée envoie `tutor`, que
  le nouveau schéma accepte (nom ≤ 40, autres champs ≤ 200 ; les textes
  réels font au plus 43 caractères).
- **Risque** : publier l’app avant les Functions, ou revenir en arrière sur
  `askTutor` après la publication, coupe le compagnon pour tous les
  utilisateurs de la nouvelle version.
- **Correction recommandée** : ordre imposé Functions + règles **puis**
  publication de l’app ; ne jamais revenir en arrière sur `askTutor` en deçà
  de ce SHA une fois l’app publiée (retour arrière par correctif en avant).
  Option : pendant une fenêtre de transition, envoyer aussi `tutor: { name }`
  (le nouveau serveur l’ignore, l’ancien exigerait encore les trois autres
  champs : insuffisant seul).

## QA-03 — Rétention de `tutor_requests` sans politique TTL déclarée

- **Gravité** : MEDIUM (données de mineurs).
- **Fichiers** : `functions/src/services/tutorRequestLedger.ts:19-20`
  (« politique TTL Firestore à activer ») ;
  `docs/architecture/COMPANION_CONTEXT_BUDGET.md:45` (« 15 min de
  rétention ») ; `firestore.indexes.json` (`fieldOverrides` vide).
- **Constat** : chaque question avec `requestId` crée
  `tutor_requests/{uid}__{requestId}` qui conserve la réponse du compagnon
  (et un éventuel bloc). Au-delà de 15 min, l’enregistrement est ignoré par la
  logique mais **n’est pas supprimé**. Aucune politique TTL n’est déclarée
  dans le dépôt ni dans les étapes de déploiement. La suppression de compte
  efface bien ces documents (champ `userId`).
- **Risque** : accumulation illimitée des réponses du compagnon à des
  mineurs, en contradiction avec la documentation.
- **Correction recommandée** : politique TTL sur `expireAt` pour le groupe de
  collections `tutor_requests`
  (`gcloud firestore fields ttls update expireAt --collection-group=tutor_requests --enable-ttl`),
  ajoutée à l’inventaire de déploiement ; corriger la doc : la suppression
  TTL est asynchrone (en général sous 24 h après l’échéance).

## QA-04 — Budget de sortie partagé avec la réflexion HIGH

- **Gravité** : MEDIUM (non vérifié sur `gemini-3.8-flash`).
- **Fichier** : `functions/src/llm/llmClient.ts:121-123` (« plafond
  explicite de chaque réponse, réflexion comprise »),
  `functions/src/llm/tutorBudget.ts:61` (`MAX_TUTOR_OUTPUT_TOKENS = 8_192`).
- **Constat** : le commentaire du code indique que les jetons de réflexion
  comptent dans `maxOutputTokens`. Avec `thinkingLevel: HIGH`, une question
  difficile peut consommer une grande partie du budget : réponse coupée
  (`finishReason` MAX_TOKENS, servie tronquée) ou vide (échec facturé,
  question décomptée, message d’erreur).
- **Risque** : réponses tronquées sur les exercices longs, surtout avec un
  bloc d’activité en fin de réponse (bloc alors rejeté `unterminated`).
- **Correction recommandée** : pendant la recette staging, mesurer la part de
  `finishReason = MAX_TOKENS` dans les journaux (le motif est déjà
  journalisé) ; si elle dépasse quelques pour cent, relever le plafond
  (16 384) sans baisser le niveau de réflexion.

## QA-05 — Aucun environnement de recette de bout en bout prouvé

- **Gravité** : MEDIUM.
- **Fichiers** : `lib/bootstrap.dart` (aucun `useFirestoreEmulator`,
  `useFunctionsEmulator`, `useAuthEmulator`), `lib/firebase_options.dart`
  (options staging `intellia237-staging`),
  `docs/architecture/FIREBASE_ENVIRONMENTS.md:24` (staging en plan Spark au
  18 juin 2026).
- **Constat** : l’app ne sait pas se connecter aux émulateurs ; la variante
  `staging` existe, mais le projet staging était en plan Spark, qui ne permet
  pas de déployer des Cloud Functions. Les suites d’émulateurs couvrent le
  serveur, les tests Flutter couvrent l’app avec des doublures ; rien ne
  couvre aujourd’hui l’app réelle contre les vraies Functions hors production.
- **Risque** : la recette sur appareil se ferait contre la production.
- **Correction recommandée** : passer le projet staging en Blaze (budget
  plafonné), y déployer cette branche, puis faire la recette appareil avec
  `--flavor staging`. Optionnel : un drapeau `--dart-define=USE_EMULATORS`
  pour brancher l’app en debug sur les émulateurs.

## QA-06 — Parcours : cartes déjà terminées perdues dans les pages suivantes

- **Gravité** : LOW.
- **Fichier** : `lib/features/flow/presentation/flow_screen.dart:150` et `:163`.
- **Constat** : `fresh` est un `Iterable` paresseux dont le filtre a un effet
  de bord (`known.add`). Il est parcouru deux fois : au second passage,
  `known.add` renvoie faux pour toutes les cartes, donc
  `_cards.addAll(fresh.where(completed…))` n’ajoute jamais rien.
- **Risque** : dans une page suivante, les cartes que l’élève a déjà
  terminées disparaissent de la session ; pas d’effet sur les points.
- **Correction recommandée** : `final fresh = page.cards.where((card) =>
  known.add(card.id)).toList();` et un test « carte terminée dans la page 2 ».

## QA-07 — Question à cheval sur minuit non décomptée

- **Gravité** : LOW.
- **Fichier** : `functions/src/services/tutorDailyQuota.ts:84-95` (et `:47`).
- **Constat** : la réservation est écrite sur le document du jour J ; si la
  réponse arrive après 00 h 00 (Africa/Douala), `consume` lit le document du
  jour J+1, n’y trouve pas la réservation et n’incrémente rien.
- **Risque** : une question gratuite par passage de minuit ; la réservation
  expirée libère la place de J.
- **Correction recommandée** : mémoriser le `dayKey` de la réservation (dans
  le registre de requêtes) et le réutiliser pour `consume` / `release`.

## QA-08 — Pas de borne de 2 000 caractères côté app

- **Gravité** : LOW (UX).
- **Fichiers** : `functions/src/utils/validation.ts:70` (serveur : 2 000) ;
  `lib/features/ai_companion/data/cloud_ai_repository.dart:255` (message
  affiché) ; composeur du compagnon (aucune limite ni compteur).
- **Constat** : un texte collé ou dicté de plus de 2 000 caractères part au
  serveur, revient en `invalid-argument` et s’affiche comme « Reformule-la en
  quelques mots ».
- **Correction recommandée** : compteur et limite dans le composeur, message
  explicite (« Ta question est trop longue : garde l’essentiel »).

## QA-09 — Mode Parcours indexé : curseur supprimé ou bascule du drapeau

- **Gravité** : LOW (seulement avec `FLOW_AUDIENCE_INDEX=true`, faux par
  défaut).
- **Fichier** : `functions/src/services/learningCatalogCallable.ts:154-157`.
- **Constat** : en mode indexé, le curseur est un identifiant de document
  relu ; s’il a été supprimé, la lecture repart du début. L’app
  dédoublonne, donc pas de doublon visible, mais des pages vides consomment
  des lectures. Un curseur émis en mode non indexé (ordre par identifiant)
  puis relu en mode indexé (ordre par date) saute ou répète des cartes.
- **Correction recommandée** : curseur composite (`publishedAt`, `id`) passé à
  `startAfter(valeurs)` ; activer le drapeau en dehors des heures d’usage.

## QA-10 — Détection de fin de Parcours liée aux constantes

- **Gravité** : LOW (maintenabilité).
- **Fichier** : `functions/src/services/learningCatalogCallable.ts:202`.
- **Constat** : la fin est détectée par `snapshot.size < FLOW_SCAN_BATCH`,
  alors que la limite réelle du lot est `min(FLOW_SCAN_BATCH, FLOW_MAX_SCAN -
  scanned)`. Correct tant que 200 est un multiple de 50 ; faux si l’une des
  constantes change.
- **Correction recommandée** : comparer à la limite effectivement demandée.

## QA-11 — Texte hors ligne du Quiz trop technique

- **Gravité** : LOW (UX).
- **Fichier** : `lib/l10n/app_fr.arb:726` (`quizOfflineBody`).
- **Constat** : « le serveur protège la correction et valide l’envoi, sans
  conserver tes réponses hors ligne » : vocabulaire technique pour un élève.
- **Correction recommandée** : « Les quiz ont besoin d’Internet pour être
  corrigés. En attendant, continue ton parcours ou une leçon téléchargée. »

## QA-12 — Écran d’entrée : registre mélangé, libellé ambigu

- **Gravité** : LOW (UX ; traité en profondeur par l’audit d’authentification).
- **Fichier** : `lib/features/auth/presentation/auth_gateway_screen.dart:49-50`
  et `:114`.
- **Constat** : « Heureux de vous retrouver. » puis « Quel espace veux-tu
  ouvrir ? » sur le même écran ; le bouton de création de compte affiche une
  question (« Qui utilise INTELLIA237 ? »).
- **Correction recommandée** : un seul registre par écran ; libellé d’action
  (« Créer mon compte »). À intégrer à la refonte de l’entrée.

## QA-13 — Anciennes demandes de suppression : pas de procédure manuelle

- **Gravité** : INFO.
- **Fichier** : `functions/src/services/accountDeletionCallable.ts:160`.
- **Constat** : décision du propriétaire respectée (jamais traitées
  automatiquement, test émulateur). L’utilisateur ne peut pas les annuler
  (seul `scheduled` est annulable), elles apparaissent dans Studio avec
  l’échéance « — », et aucune procédure écrite ne dit à la
  super-administration quoi en faire.
- **Recommandation** : écrire la procédure (contacter la personne, puis
  demande explicite dans l’app ou clôture manuelle tracée).

## QA-14 — Un seul rôle par compte

- **Gravité** : INFO (limite d’architecture, voir l’audit d’authentification).
- **Fichiers** : `firestore.rules:20-22` (`getUserRole()` lit un seul
  `users/{uid}.role`) ; `lib/app/router/app_router.dart:757-800`
  (`_resolveAuthenticatedRoleRedirect`, un seul `auth.role`).
- **Constat** : un enseignant qui est aussi parent a besoin aujourd’hui de
  deux comptes (enseignant par e-mail, parent par téléphone).
- **Recommandation** : rôles multiples gérés par le serveur (voir le plan
  d’implémentation, étape 2b).
