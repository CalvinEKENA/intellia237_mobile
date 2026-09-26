# Porte de recette propriétaire — 21 septembre 2026

Revue **en lecture seule**. Aucun code modifié, aucun AAB, aucun
déploiement, aucune fusion vers `main`. Ce document et
`OWNER_QA_FINDINGS.md` décrivent le SHA ci-dessous ; ils n’ont été versionnés
qu’ensuite, sur `fix/release-hardening-review-fixes`, sans modifier ce SHA.
Suite : `FIX_CYCLE_REPORT_2026-09-22.md`.

## 1. Identité de la revue

| | |
| --- | --- |
| Branche | `fix/release-hardening-sep2026` |
| SHA | `11eb26cfe53d7291886b6c3a45e70d5eb5ff8927` |
| Distant | `origin/fix/release-hardening-sep2026` = même SHA (poussé le 22/09, branche seule) |
| Base de comparaison | `fix/family-auth-parent-child` @ `5e4f797` (présente sur origin) |
| Arbre local | propre au moment du push |
| Version | `3.2.1+30`, inchangée par ce diff |

**CI sur ce SHA** (runs du push) :

| Workflow | Résultat |
| --- | --- |
| Backend quality — tests unitaires et build | vert |
| Backend quality — règles et intégration (émulateurs) | vert |
| Studio quality | vert |
| Mobile quality | **rouge** : contrôle des références de marque (QA-01) ; « Analyze » et « Test » sautés |

Localement, sur ce SHA : `flutter analyze` propre, `flutter test`
1 550 / 1 550, Functions 352 / 352 + `tsc`, règles 61 / 9 / 16, intégration
famille 17, réserve d’étude 8, annonces 4, suppression 7, Parcours 6,
comptes admin 4, publication 9 ; Studio analyse propre et 55 / 55.

Constats de la revue : `docs/release/OWNER_QA_FINDINGS.md` (14 constats :
2 HIGH, 3 MEDIUM, 7 LOW, 2 INFO).

## 2. Diff de revue `5e4f797..11eb26c`

41 commits : 32 en première lignée (dont la fusion `67a71ac`) et 9 commits
Studio apportés par la fusion. 222 fichiers, +31 417 / −713.

### 2.1 Commits

| Commit | Sujet | Classe |
| --- | --- | --- |
| 26d8850, 44dab81, 1071993, 69780d1 | Studio phases A à E (via la fusion) | INFRA |
| afbf729 | Studio : branchement serveur, exécutable Windows | INFRA |
| d30a205 | Studio : plus d’écriture client privilégiée | SECURITY |
| 7c5dcbd | Studio : matières par classe | RELIABILITY |
| 412fa34 | Gemini 3.8 Flash HIGH imposé, configuration exposée | RELIABILITY |
| db45f3d | Flow → Parcours (Studio) | UX |
| 67a71ac | Fusion : une seule source Functions / règles / index | INFRA |
| 8999c63 | Personas serveur, bornes de jetons | SECURITY |
| b98573a | Pas d’établissement auto-déclaré | SECURITY |
| 261af5f | Retrait de `generateQuiz` / `generateSummary` | SECURITY |
| 19b9858 | Idempotence du tuteur, contrat de délais | RELIABILITY |
| 25819d9 | Configuration invalide : échec immédiat | RELIABILITY |
| ee58a0f | Tests du routage des annonces parents | TEST |
| a5bdb7b | Traitement des suppressions de compte | SECURITY |
| 613026f | Accents corrompus dans les erreurs de publication | UX |
| 9272278 | Parcours paginé | PERFORMANCE |
| ef36b32 | Formatage Studio | INFRA |
| 3d2a05b | Studio : erreurs conservées, vraie spécification des compagnons | RELIABILITY |
| 7b104ef | CI en trois portes (mobile, Studio, backend) | INFRA |
| 71cd654 | Règles : `children_links`, contenus, collections inutilisées | SECURITY |
| 3951c2e | Sauvegarde Android, code de liaison | SECURITY |
| 9e6a7b2 | États indisponibles distincts Apprendre / Quiz | UX |
| 8a1147e | Formatage | INFRA |
| b0d462a | Séquences d’échappement au lieu d’octets bruts | RELIABILITY |
| 21d5069 | Blocs interactifs : serveur | UX |
| 37571d6 | Blocs interactifs : module Flutter | UX |
| 1c9f58c | Blocs interactifs dans la conversation | UX |
| 2af61db | Parcours vide traduit (EN) | UX |
| b31e919 | Licence Barlow Condensed | DOC |
| 5a1f9cd | Contrat serveur ↔ app des blocs | TEST |
| 3ad0f27 | Inventaires et décisions | DOC |
| f30cd46 | Accolades Studio (analyse) | INFRA |
| fa332b7 | Deux tests de contrat réalignés | TEST |
| b519b86 | Test Storage : hôtes d’émulateur résolus | TEST |
| 0241bfb | Parcours : `not-found` après changement d’école | RELIABILITY |
| 563ac32 | CI : deux suites d’intégration branchées | INFRA |
| 5fbe813 | Anciennes demandes de suppression jamais traitées (test) | TEST |
| 11eb26c | Rapport de durcissement | DOC |

### 2.2 Par zone

| Zone | Fichiers | Lignes | Contenu | Classes |
| --- | ---: | --- | --- | --- |
| Functions (code) | 26 | +2 534 / −231 | tuteur, suppression, Parcours, établissements, classes, config | SECURITY, RELIABILITY, PERFORMANCE |
| Functions (tests) | 18 | +2 279 / −46 | unitaires et émulateurs | TEST |
| Règles Firestore + index | 2 | +89 / −36 | voir 2.4 et 2.5 | SECURITY, PERFORMANCE |
| Règles Storage | 0 | — | inchangées | — |
| Flutter mobile (`lib/`) | 27 | +2 862 / −216 | compagnon, blocs, Parcours, Apprendre / Quiz, suppression | UX, RELIABILITY |
| Traductions (`lib/l10n`) | 5 | +996 / −40 | chaînes FR / EN | UX |
| Tests mobiles | 22 | +1 991 / −30 | | TEST |
| Studio (`apps/intellia_studio`) | 105 | +19 511 / −0 | application entière (fusion) + correctifs | INFRA, SECURITY, RELIABILITY |
| Android | 3 | +43 / −1 | sauvegarde désactivée | SECURITY |
| CI | 4 | +258 / −111 | 3 workflows créés, 1 supprimé | INFRA |
| Documentation | 10 | +854 / −2 | | DOC |

### 2.3 Functions

Exportées à HEAD : **42**.

| Fonction | Changement | Classe |
| --- | --- | --- |
| `askTutor` | persona serveur, budget, idempotence, blocs interactifs, délai 75 s | SECURITY, RELIABILITY, UX |
| `requestAccountDeletion` | programme la suppression (7 jours), prévient les parents | SECURITY |
| `cancelAccountDeletion` | **nouvelle** | SECURITY |
| `processAccountDeletions` | **nouvelle**, planifiée toutes les 60 min (Africa/Douala) | SECURITY |
| `readLearningCatalog` (action `flow`) | page bornée, mode indexé optionnel | PERFORMANCE |
| `saveFlowPublication`, `saveLessonPublication` | écrivent `audienceKeys` | PERFORMANCE |
| `submitFlowActivity` | `not-found` quand la carte n’est plus pour l’élève | RELIABILITY |
| `importCoursePages` | plafond de sortie explicite | RELIABILITY |
| `manageEstablishment`, `manageSchoolClass`, `getCompanionRuntimeConfig` | **nouvelles** (Studio) | INFRA |
| `generateQuiz`, `generateSummary` | **retirées** (logique conservée pour `scripts/pregenerate.ts`) | SECURITY |
| toutes | configuration invalide ⇒ échec au démarrage | RELIABILITY |

### 2.4 Règles Firestore

| Changement | Classe |
| --- | --- |
| `users`, `student_profiles` : `establishmentId` / `establishmentName` retirés des clés de création | SECURITY |
| `parent_profiles` : aucune clé d’établissement à la création ni en mise à jour par le titulaire | SECURITY |
| `children_links` : identifiant canonique `{parentId}_{studentId}`, pas d’auto-lien | SECURITY |
| `courses`, `courses/*/images`, `lesson_assets` : lecture réservée au personnel du périmètre | SECURITY |
| `tutor_requests` : serveur seul | SECURITY |
| `account_deletion_requests` : lecture titulaire ou super-administration, écriture serveur | SECURITY |
| `ai_conversations`, `settings/{uid}` : fermées ; `recommendations` : plus de mise à jour client | SECURITY |
| fonctions de règle mortes (transitions éditoriales) retirées | INFRA |

Ni l’app ni le Studio n’écrivent `children_links` ; aucun client ne lit
`courses`, `lesson_assets`, `settings` ni `ai_conversations` (l’espace
enseignant crée des `lesson_assets` : règle de création inchangée). Le Studio
lit `account_deletion_requests` en super-administration, autorisé.
L’inscription n’envoie jamais `establishmentId`.

### 2.5 Index

`account_deletion_requests (status, dueAt)` ; `flow_items (status,
audienceKeys CONTAINS, publishedAt desc, __name__ desc)`. **Manquant** : la
politique TTL de `tutor_requests.expireAt` (QA-03).

### 2.6 Flutter mobile

| Domaine | Fichiers principaux | Classe |
| --- | --- | --- |
| Compagnon | `ai_companion/*` (identifiant de requête, délai 90 s, historique borné, activités) | RELIABILITY, UX |
| Blocs interactifs | `interactive_learning/*` (nouveau) | UX |
| Parcours | `flow/*` (fenêtres paginées, écran vide traduit) | PERFORMANCE, UX |
| Apprendre / Quiz | `learn_unavailable_state.dart`, `quiz_unavailable_state.dart` | UX |
| Compte | `account_deletion_tile.dart`, `account_deletion_service.dart` | SECURITY |
| Démarrage | `bootstrap.dart` (licence de police) | DOC |
| Supprimé | `tutor/data/structured_ai_functions_service.dart` (client mort) | SECURITY |

### 2.7 Studio, Android, CI

Studio : application Windows complète (31 modules) apportée par la fusion,
plus les correctifs `3d2a05b` (erreurs), `f30cd46` (analyse) et le panneau
des demandes de suppression. Android : `allowBackup="false"`,
`data_extraction_rules.xml`, `backup_rules.xml`. CI :
`mobile-quality.yml`, `studio-quality.yml`, `backend-quality.yml`
(remplacent `foundation-quality.yml`), déclenchés par chemins.

## 3. Inventaire de production (rien n’est déployé)

**Préalable** : l’état réel de la production n’a pas été lu (aucun accès à la
production dans cette phase). Avant tout déploiement :
`firebase functions:list` et l’historique des règles dans la console, pour
comparer à cette branche. D’après le rapport de la mission famille, la base
`5e4f797` n’avait pas été déployée non plus (non vérifié ici).

| # | Élément | Raison | Ordre | Dépendances | Retour arrière |
| --- | --- | --- | --- | --- | --- |
| E1 | Secret `STUDENT_ACCESS_CODE_PEPPER` (Secret Manager) | 4 Functions famille le déclarent ; déploiement impossible sans lui | 1 | aucune | le garder ; **ne jamais le changer** (invalide tous les codes élèves) |
| E2 | Rôle `roles/iam.serviceAccountTokenCreator` au compte de service d’exécution | jetons personnalisés (`signInWithStudentAccessCode`, migration du téléphone familial) | 1 | aucune | retirer le rôle (casse la connexion par code) |
| E3 | API Cloud Scheduler active | `processAccountDeletions` | 1 | aucune | — |
| E4 | Valeurs de `functions/.env` de production relues | la configuration échoue désormais au démarrage si invalide | 1 | aucune | corriger la valeur et redéployer |
| D1 | Index `account_deletion_requests (status, dueAt)` | requête du traitement horaire | 2 (avant A) | aucune | laisser (additif) |
| D2 | Index `flow_items (status, audienceKeys, publishedAt, __name__)` | mode Parcours indexé | 2 | aucune | laisser |
| D3 | Politique TTL `tutor_requests.expireAt` (gcloud) | rétention réelle de 15 min (QA-03) | 2 | aucune | désactiver la politique |
| A1 | Toutes les Functions depuis **cette branche uniquement** | source unique (famille + Studio + durcissement) | 3 | E1–E4, D1 | redéployer le SHA précédemment déployé (à étiqueter avant) ; **exception `askTutor`** : voir QA-02 |
| A2 | Suppression de `generateQuiz`, `generateSummary` | ouvertes à tout compte | 3 (avec A1) | A1 | les redéployer depuis l’ancien SHA (déconseillé) |
| A3 | Tâche planifiée `processAccountDeletions` | suppressions à échéance | 3 | D1, E3 | mettre la tâche Cloud Scheduler en pause |
| B1 | Règles Firestore | voir 2.4 | 4 (après A1) | A1 (les flux famille et établissement passent par les Functions) | redéployer l’ancien jeu depuis l’historique de la console |
| C1 | Règles Storage | inchangées par ce diff | — | — | — |
| F1 | `backfillFlowAudienceKeys` (à blanc, puis `--apply --project`) | clés d’audience des publications existantes | 5 (optionnel) | A1, D2 | champ additif, ignoré si le drapeau est faux |
| F2 | `FLOW_AUDIENCE_INDEX=true` puis redéploiement | active le mode indexé (ordre « plus récent d’abord ») | 6 (optionnel) | F1, D2 | repasser à `false` et redéployer |
| G1 | Nouvelle app mobile (Play) | compagnon, blocs, Parcours, suppression, sauvegarde | 7 (**après** A1 + B1) | A1 (QA-02), B1 | retirer le déploiement progressif Play ; **pas** de retour arrière d’`askTutor` |
| H1 | Nouvelle version Studio (Windows) | outil interne complet | 7 | A1 (callables Studio), B1 | réinstaller la version précédente |

Rien d’autre : pas de migration Firestore, pas de migration d’identifiants.

### Migrations

- **Aucune migration obligatoire.**
- F1 est optionnelle, additive, réversible, avec un mode à blanc par défaut.
- Anciennes demandes de suppression (`pending`) : aucune migration, jamais
  traitées automatiquement (décision du propriétaire) ; procédure manuelle à
  écrire (QA-13).
- Codes élèves : aucune migration ; chaque parent en émet au besoin.

## 4. Risques de régression par flux

Le diff ne modifie pas le code client de l’authentification ni les services
famille : ces flux ne sont touchés qu’indirectement (règles, configuration,
délais). Les flux compagnon, Parcours, Apprendre / Quiz et suppression sont
directement modifiés.

| Flux | Chemin de code | Tests existants | Risque résiduel | Test manuel recommandé |
| --- | --- | --- | --- | --- |
| Connexion élève par téléphone | `phone_auth_screen.dart`, `phone_auth_controller.dart`, `firebase_phone_auth_repository.dart`, `auth_controller.dart` ; règles `users` / `student_profiles` | `test/features/auth/phone_auth_*`, `seal_device_journeys_test.dart`, règles Firestore (61) | Faible : seule la clé `establishmentId` quitte la création, jamais envoyée par l’app | Nouvel élève de bout en bout, puis reconnexion |
| Connexion élève par code | `student_access_code_screen.dart` ; `studentAccessCode.ts` (`signInWithStudentAccessCode`) | `studentAccessCode.test.ts`, `familyAccess.integration` (verrou), `family_auth_journeys_test.dart` | Moyen au déploiement : dépend de E1 et E2 | Code valide, code faux, code après rotation |
| Parent multi-enfants | `parentChildrenCallable.ts`, `lib/features/parent/*` | `parent_code_first_journey_test.dart` (« plusieurs enfants »), `parent_experience_test.dart` | Faible | Deux enfants, dont un sans téléphone |
| Parent multi-écoles | facturation par enfant (`mobileMoneyCallables.ts`), annonces | `familyBilling.integration` (11), `announcementFanout.integration` | Faible | Deux enfants dans deux écoles : offres et annonces |
| Migration téléphone élève → parent | `familyPhoneMigration.ts`, `migrateStudentPhoneToParent` | `familyPhoneMigration.test.ts`, `familyAccess.integration` (compensation) | Moyen au déploiement : E1, E2 | Téléphone familial ouvert sur l’élève : migration complète |
| Réserve d’étude par enfant | `studyReserve.ts`, `studyReserveConsumption.ts` (**modifié** : échec facturé comptabilisé) | `studyReserve.integration` (8), `studyReserveConsumption.test.ts`, `companion_reserve_exhausted_test.dart` | Faible : un échec facturé est désormais débité (voulu) | Réserve presque vide, question, jauge |
| Annonces parents | `announcementNotificationFanout.ts` (inchangé) | `announcementFanout.integration` (4) | Faible | Annonce « Parents » d’une école : seuls ses parents la reçoivent, une fois |
| Changement d’établissement | `accountEstablishmentChangeCallable.ts` ; `flowPointsCallable.ts` (**modifié**) | `accountEstablishmentChangeCallable.test.ts`, `lessonPublication.integration` | Faible | Transfert d’un élève, puis carte Parcours de l’ancienne école |
| Kira | `askTutorUseCase.ts`, `tutorPersonas.ts`, `cloud_ai_repository.dart` | `tutorPersonaAuthority.test.ts` (16), `tutorRequestIdempotency.test.ts` (10), `askTutorUseCase.test.ts`, `tutor_request_contract_test.dart` | **Élevé** si l’app sort avant les Functions (QA-02) ; réponses tronquées possibles (QA-04) | Question longue, coupure réseau puis « Réessayer », quota épuisé |
| Léo | idem, persona `leo` | idem | idem | Élève anglophone : réponse en anglais |
| Parcours | `learningCatalogCallable.ts`, `flow_screen.dart`, `flow_controller.dart` | `flowFeed.integration` (6), `flow_pagination_test.dart`, `flow_first_entry_stability_test.dart` | Faible (QA-06) | 40+ cartes : défilement, cartes déjà faites, hors ligne |
| Quiz | `quiz_hub_screen.dart`, `quiz_unavailable_state.dart` | `learn_quiz_distinct_states_test.dart`, `test/features/quiz/*` | Faible | Hors ligne, profil incomplet, catalogue vide |
| Apprendre | `learn_hub_screen.dart`, `learn_unavailable_state.dart` | `learn_quiz_distinct_states_test.dart`, `test/features/learn/*` | Faible | Hors ligne, erreur, recherche vide |
| Suppression de compte | `accountDeletionCallable.ts`, `account_deletion_tile.dart`, panneau Studio | `accountDeletion.integration` (7), `accountDeletionCallable.test.ts`, `account_deletion_tile_test.dart`, `account_deletion_panel_test.dart` | Moyen au déploiement : D1, E3 ; l’app exige A1 + B1 | Demande, annulation, échéance (compte de test) |

## 5. IA : état exact à ce SHA

| Sujet | Valeur |
| --- | --- |
| Modèle | `GEMINI_MODEL`, défaut `gemini-3.8-flash` (Vertex AI, `VERTEX_AI_LOCATION` défaut `global`) ; `.env.example` : `gemini-3.8-flash` |
| Niveau de réflexion | tuteur `GEMINI_TUTOR_THINKING_LEVEL`, défaut **HIGH** ; structuré `GEMINI_STRUCTURED_THINKING_LEVEL`, défaut MEDIUM ; valeurs admises LOW / MEDIUM / HIGH |
| `maxOutputTokens` | tuteur 8 192 ; structuré 8 192 ; import de pages 32 768 ; réflexion comprise (QA-04) |
| Message | 1 à 2 000 caractères après `trim` (serveur) ; aucune borne côté app (QA-08) |
| Historique accepté | 20 éléments au plus, 4 000 caractères chacun |
| Historique envoyé au modèle | 8 derniers messages, 1 200 caractères chacun (fin conservée), 6 000 au total ; même fenêtre côté app |
| Contexte de leçon | 5 000 caractères ; au plus 3 leçons publiées parmi les 8 dernières consultées, même classe, périmètre établissement respecté |
| Prompt système | 7 000 caractères au plus |
| Résultat d’activité | 600 caractères au plus |
| Entrée totale | 22 000 caractères au plus ; réduction de l’historique, puis du contexte ; la question n’est jamais coupée |
| Délais | fournisseur `min(LLM_SERVICE_TIMEOUT_MS, 45 000)` ms (défaut 45 000, bornes 1 000–120 000) ; callable 75 s, 512 MiB ; app 90 s ; attente d’une requête en cours 45 s, sondage 1,5 s |
| Idempotence | `requestId` (8–80 caractères `[A-Za-z0-9_-]`) ; `tutor_requests/{uid}__{requestId}` ; empreinte SHA-256 de `tutorId`, `classLevel`, `userMessage` ; bail 75 s ; 2 exécutions ; réponse en cache rejouée (bloc compris) ; même identifiant, autre question ⇒ `invalid-argument` ; 3ᵉ exécution ⇒ `failed-precondition` (`tutor_request_retry_limit`) ; attente dépassée ⇒ `unavailable` (`tutor_request_in_progress`) ; codes app `TUTOR-PENDING-508`, `TUTOR-RETRY-509` ; sans `requestId` (anciennes versions) : pas d’idempotence |
| Quota quotidien | `TUTOR_DAILY_QUESTION_LIMIT`, défaut 20 (1–200), journée Africa/Douala ; réservation avant l’appel (compte dans la limite, expire après 5 min) ; **débit** après réponse ou échec que le fournisseur a pu facturer (usage reçu ou délai dépassé) ; **libération** sinon ; débit idempotent par requête ; relance après échec facturé : pas de nouvelle réservation ; cas limite minuit (QA-07) |
| Réserve d’étude | réserve → exécution → débit de l’usage réel (y compris échec facturé) ou libération ; réserve non configurée : rien à débiter |
| Persona | serveur seul ; `tutorId` ∈ {`kira`, `leo`} (accents et casse ignorés) ; ancien champ `tutor.name` (≤ 40) accepté pour les versions installées, alias `ethan`, `armel`, `nathan` → Léo, `grace`, `cynthia`, `marianne` → Kira ; `specialty` / `personality` / `motto` (≤ 200) acceptés mais **jamais utilisés** ; schéma strict ; spécification publiée au Studio par `getCompanionRuntimeConfig` (super-administration seulement) |
| Langue | profil `student_profiles.preferences` : `educationalSubsystem` anglo / en ⇒ anglais, franco / fr ⇒ français ; sinon `academicLevelId` `en_` / `fr_` ; sinon `interfaceLanguage` ou `contentLanguage` commençant par `en` ; défaut français ; la langue du message n’est pas utilisée |
| Règles de sécurité | 8 règles FR et EN dans le prompt système, prioritaires sur toute demande : public mineur et refus de changer de rôle ; détresse ou auto-agression (calme, adulte de confiance, urgences, jamais de méthode, pas de secret promis) ; maltraitance (pas sa faute, pas de détails, adulte de confiance hors famille si besoin) ; demande sexuelle refusée (SVT factuelle) ; violence, armes, drogues, piratage refusés ; aucune coordonnée personnelle demandée ; aucune donnée d’un autre élève ; compagnon IA, jamais de rencontre |

## 6. Blocs d’apprentissage interactifs

| Sujet | État |
| --- | --- |
| **Implémentés (PROD-READY côté code)** | `word_order` (en ligne) ; `step_order`, `equation_order`, `timeline_order`, `process_sequence`, `sequence` (empilés) |
| **Déclarés seulement (ARCHITECTURAL PREPARATION)** | 22 types : `multiple_choice`, `true_false`, `fill_blank`, `sentence_correction`, `matching`, `expression_match`, `formula_match`, `unit_match`, `element_match`, `label_match`, `event_match`, `cause_effect_match`, `claim_match`, `classification`, `argument_classification`, `sorting`, `numeric_input`, `value_input`, `text_evidence`, `diagram_labeling`, `map_interaction`, `data_interpretation` ; refusés par le serveur (`type_not_rendered`) et par l’app |
| Schéma émis | `version: 1`, `id` (serveur), `type`, `primitive: "ordering"`, `layout`, `language`, `subject?`, `instruction?`, `items[{id,text}]` (identifiants serveur), `solution` (permutation des identifiants), `trailing?` (`.`, `?`, `!`, en ligne seulement), `hints[]`, `explanation?`, `difficulty` 1–3, `rationale?` |
| Proposition du modèle | entre `<<<ACTIVITY` et `ACTIVITY>>>` : `type`, `sequence` (textes dans le bon ordre), options ; schéma strict |
| Validation serveur | refus journalisé, texte toujours servi : `activities_not_negotiated`, `unterminated`, `too_large`, `invalid_json`, `invalid_schema`, `unknown_type`, `type_not_allowed`, `type_not_rendered`, `item_count`, `item_length`, `marker_in_item`, `not_orderable`, `trailing_on_stacked`, `id_collision` |
| Limites | brut 4 000 caractères ; consigne 160 ; en ligne 2–10 éléments de 24 ; empilé 2–8 de 140 ; 3 indices de 160 ; explication 400 ; justification 160 ; JSON relu par l’app ≤ 6 000 |
| Négociation | l’app déclare ses types (`activities`) ; sans déclaration (anciennes versions), aucune consigne d’activité |
| Rendu Flutter | `InteractiveBlockView` → `OrderingExerciseView` : tuiles (toucher-déplacer, glisser-déposer) ou étapes (monter / descendre) ; incarné par Kira ou Léo ; aucun fournisseur ni réseau |
| Correction locale | `OrderingSession` : par identifiant, textes identiques équivalents ; départ jamais résolu ; indices puis position à revoir ; solution après 3 essais, sans compter de réussite |
| Stockage | le bloc est enregistré avec le message dans l’historique local (SharedPreferences, par élève) ; côté serveur, seulement dans `tutor_requests` (15 min logiques, QA-03) |
| Reprise de conversation | résultat (`blockId`, type, réussite, essais, indices, solution montrée ; jamais la durée) envoyé **une fois** avec le message suivant, conservé si l’envoi échoue ; phrase factuelle dans le prompt utilisateur ; « Continuer avec Kira / Léo » |
| Hors ligne | exercice jouable et corrigé sans réseau, y compris après redémarrage |
| Tests | serveur 16, domaine 12, rendu 9, conversation 7, contrat serveur ↔ app 2 |
| Non prêt | correction serveur pour un usage **noté** ; rédaction dans Studio ; recette TalkBack sur appareil |

## 7. Apprendre et Quiz

| | Apprendre | Quiz |
| --- | --- | --- |
| En-tête | surtitre « Espace élève », titre « Apprendre » ; autonome : barre sombre | surtitre « Espace élève », titre « Quiz », introduction « Entraîne-toi avec des corrections guidées… » ; autonome : barre standard |
| Nominal | bannière de classe, recherche, cartes matières | deux entrées « S’entraîner » et « S’évaluer », filtres, historique |
| Vide | « Tes matières arrivent » ; recherche sans résultat : « Aucune matière trouvée » + « Effacer la recherche » | « Les quiz de ta classe arrivent » |
| Erreur | `LearnUnavailableState` : « Tes matières ne sont pas disponibles pour le moment », variante hors ligne | `QuizUnavailableState` : « Tes quiz ne sont pas disponibles pour le moment », modes annoncés ; message dédié si profil incomplet ou catalogue refusé ; hors ligne : « Les quiz attendent le réseau » (QA-11) |
| Actions | « Réessayer », « Continuer mon parcours » | « Réessayer », « Continuer mon parcours » ; hors ligne : « Ouvrir mon parcours hors ligne », leçons téléchargées ; glisser pour actualiser |
| Diagnostic | type d’erreur journalisé, jamais affiché | opération journalisée, jamais affichée |

Confirmé : deux composants distincts, avec leurs propres textes, icônes et
actions ; plus une vue générique centrée partagée. Test :
`learn_quiz_distinct_states_test.dart` (7).

## 8. Plan de recette locale et émulateurs

**Limite** : l’app ne se branche pas sur les émulateurs (QA-05). La recette
locale couvre le serveur sur émulateurs et l’app par ses tests à doublures ;
la recette appareil demande le projet staging (section 9).

### 8.1 Démarrage

```bash
cd functions
npm ci
npm run build
npx vitest run
```

Suites d’émulateurs, **une à la fois** (projet `demo-intellia237`, ports de
`firebase.json`). Sous Windows sur ce poste : variable
`JAVA_TOOL_OPTIONS=-Djdk.net.unixdomain.tmpdir=C:/jtmp`. Si un autre
émulateur occupe les ports, utiliser une copie locale de `firebase.json` avec
d’autres ports (`--config`), puis la supprimer.

```bash
npm run test:rules
npm run test:integration:family-access
npm run test:integration:study-reserve
npm run test:integration:announcements
npm run test:integration:account-deletion
npm run test:integration:parcours
npm run test:integration:admin-accounts
npm run test:integration:lesson-publication
```

Côté app :

```bash
flutter analyze lib test tool
flutter test
dart run tool/check_brand_references.dart
```

Exploration manuelle du serveur : `firebase emulators:start --only
auth,firestore,functions,storage --project demo-intellia237`, interface
d’émulateur sur le port 4005. **Ne pas** appeler `askTutor` ou
`importCoursePages` sur l’émulateur Functions : ils joindraient Vertex AI
avec les identifiants de la machine.

### 8.2 Comptes de test

Les suites créent leurs propres données (élève `stu-*`, parent `parent-p`,
écoles `school-a` / `school-b`, enseignant, administrateur). Pour la recette
appareil (staging), à créer par le propriétaire : super-administrateur ;
administrateur école A ; administrateur école B ; enseignant école A ; parent
avec deux enfants (école A, école B) ; élève avec téléphone ; élève sans
téléphone (code) ; élève sur le téléphone familial (migration) ; élève
anglophone. Numéros : numéros de test fictifs configurés dans Firebase Auth
du projet staging (code fixe), jamais de vrais numéros de famille.

### 8.3 Scénarios et résultats attendus

| Domaine | Où | Scénario | Attendu |
| --- | --- | --- | --- |
| Family Auth | `family-access`, `family_auth_journeys_test.dart`, `parent_code_first_journey_test.dart` | téléphone familial ouvert sur l’élève, migration, parent multi-enfants | parent créé, enfant lié, l’élève garde son compte ; compensation en cas d’échec |
| Code élève | `studentAccessCode.test.ts`, `family-access` | code valide, faux, 20 échecs, rotation | connexion au même UID ; verrou par client ; ancien code refusé aussitôt |
| Réserve d’étude | `study-reserve`, `studyReserveConsumption.test.ts` | réservation, débit réel, échec facturé, réserve vide | débit exact, une seule fois ; refus propre quand vide |
| Annonces parents | `announcements` | annonce « Parents » école A | parents des enfants de A seulement, une fois, jamais ceux de B |
| Suppression de compte | `account-deletion` | demande, annulation, échéance, échec puis reprise, ancienne demande | rien d’effacé avant 7 jours ; Auth en dernier ; `pending` jamais traité |
| Parcours paginé | `parcours`, `flow_pagination_test.dart` | page bornée, audience, mode indexé | ≤ 30 cartes, ≤ 200 documents lus, aucune carte d’une autre classe |
| Kira / Léo | `askTutorUseCase.test.ts`, `tutorPersonaAuthority.test.ts`, `tutorRequestIdempotency.test.ts`, `tutor_request_contract_test.dart` | persona forcée par le client, relance, quota | persona serveur ; relance sans double débit |
| Blocs interactifs | `interactiveBlocks.test.ts`, `test/features/interactive_learning/*`, `companion_activity_test.dart` | bloc valide, invalide, hors ligne, résultat | bloc invalide retiré, texte servi ; résultat envoyé une fois |
| Apprendre / Quiz | `learn_quiz_distinct_states_test.dart` | erreur, hors ligne, vide | états distincts, aucun code technique |

## 9. Liste de contrôle sur appareil (staging uniquement)

Préalable : projet staging en Blaze, section 3 appliquée **au staging**,
variante `--flavor staging -t lib/main_staging.dart`. Android 360 px, taille
de texte 1,3 puis 2,0, TalkBack sur les écrans marqués « a11y ».

1. Premier lancement : accueil, puis création d’un élève par téléphone.
2. Déconnexion, reconnexion : retour direct à l’espace élève.
3. Élève sans téléphone : code remis par le parent ; rotation du code.
4. Téléphone familial : migration élève → parent ; les deux espaces s’ouvrent.
5. Parent, deux enfants dans deux écoles : offres par enfant, annonces.
6. Kira : question simple ; question longue ; mode avion pendant l’attente puis
   « Réessayer » (pas de double débit) ; quota épuisé.
7. Léo en anglais (élève anglophone).
8. Activité : ordre des mots (tuiles, glisser), frise (monter / descendre),
   indice, solution après 3 essais, « Continuer avec Kira ». a11y.
9. Redémarrage hors ligne : l’activité se rejoue.
10. Parcours : 40 cartes et plus, défilement, cartes terminées, hors ligne.
11. Apprendre et Quiz : mode avion (états distincts), catalogue vide. a11y.
12. Suppression : demande, affichage de l’échéance, annulation.
13. Studio : demandes de suppression, spécification des compagnons.
14. Sauvegarde : `adb shell bmgr backupnow <applicationId staging>` ne sauve
    rien.
15. Journaux : taux de `finishReason = MAX_TOKENS` (QA-04).

## 10. Plan de retour arrière

| Élément | Retour arrière | Attention |
| --- | --- | --- |
| Functions | étiqueter le SHA actuellement déployé **avant** le déploiement ; redéployer ce SHA | `askTutor` : impossible une fois la nouvelle app publiée (QA-02) ; correctif en avant |
| Tâche planifiée | pause Cloud Scheduler | les demandes restent `scheduled` |
| Règles Firestore | jeu précédent depuis l’historique de la console | après retour des Functions seulement |
| Index, TTL | laisser (additifs) ; TTL désactivable | — |
| Parcours indexé | `FLOW_AUDIENCE_INDEX=false`, redéployer | curseurs en cours (QA-09) |
| App mobile | arrêt du déploiement progressif Play | les versions déjà installées restent |
| Studio | réinstaller la version précédente | — |
| Secret du code élève | **aucun retour arrière** | le changer invalide tous les codes |

## 11. Audit UX de l’authentification (addendum)

Audit en lecture seule ; rien n’a été modifié.

### 11.1 Carte actuelle des écrans

| Route | Écran | Rôle |
| --- | --- | --- |
| `/bootstrap` | démarrage | session valide ⇒ espace du rôle, directement |
| `/onboarding` | campagne en 5 actes (activation, savoir, défi, compagnons, ascension) | premier lancement seulement |
| `/register` | « Qui utilise INTELLIA237 ? » : Élève, Parent, Enseignant, puis Continuer ; lien « J’ai déjà un compte » | premier lancement sans session antérieure |
| `/auth` | porte : Élève, « Pas de téléphone ? Entre avec ton code… », Parent, Enseignant, bouclier « direction », lien « Qui utilise INTELLIA237 ? » | après une déconnexion |
| `/auth/parent` | code de liaison de l’enfant **avant** authentification, ou « déjà parent » | parent |
| `/auth/phone?role=…` | numéro (+237 seulement), puis code SMS (6 cases, collage, remplissage automatique, lecture automatique Android) | élève, parent, direction |
| `/auth/student/code` | code d’accès élève | élève sans téléphone |
| `/login/email`, `/forgot-password` | e-mail + mot de passe | enseignant, direction |
| `/register/student` | 4 étapes : Identité, Classe, Compagnon, Sécurité | nouvel élève |
| `/register/parent` | 3 étapes : Identité, Enfants, Final | nouveau parent |
| `/register/teacher` | 3 étapes, puis validation par l’école | nouvel enseignant |
| `/register/admin` | demande d’accès direction | direction |
| `/auth/profile-recovery` | profil introuvable ou incohérent | tous |

### 11.2 Étapes par scénario (aujourd’hui)

| Scénario | Écrans avant le numéro | Total jusqu’à l’espace |
| --- | ---: | ---: |
| Nouvel élève (téléphone) | 6 (5 actes + choix du rôle) | ≈ 12 (+ numéro, code, 4 étapes) |
| Nouveau parent | 7 (5 actes + rôle + code enfant) | ≈ 12 (+ numéro, code, 3 étapes) |
| Retour après déconnexion | 1 (choix du rôle) | 3 |
| Session valide | 0 | 0 (direct) |
| Élève avec code | 1 à 2 | 2 à 3 |
| Nouvel enseignant | 6 | ≈ 9 (formulaire e-mail, puis attente de validation) |
| Direction | 2 (bouclier, feuille) | variable |

### 11.3 Points de confusion

1. **Rôle demandé avant l’identité**, sur deux écrans différents (`/register`
   et `/auth`) qui ne se ressemblent pas.
2. **Code enfant demandé au parent avant même son numéro** (`/auth/parent`).
3. **Enseignant renvoyé vers l’e-mail** alors que tout le reste passe par le
   téléphone ; la direction a trois chemins (e-mail, téléphone, demande).
4. **Registre mélangé** sur la porte (« vous retrouver », « veux-tu ») ;
   bouton de création libellé par une question (QA-12).
5. **Bouclier « direction »** discret en haut à droite : difficile à trouver
   pour un chef d’établissement peu habitué.
6. **Premier lancement long** : 5 actes avant de pouvoir entrer son numéro,
   même pour un parent pressé.
7. **Conflit de rôle** : un numéro déjà élève ouvert en « parent » aboutit à un
   message de conflit après le code SMS (géré, mais c’est la conséquence du
   choix de rôle préalable).

Écrans ou choix inutiles dans la cible : choix de rôle avant
authentification (les deux écrans), code enfant avant authentification,
chemin e-mail séparé pour l’enseignant (le garder pour les comptes existants),
bouclier séparé.

### 11.4 Ce que l’architecture permet déjà

- Session valide ⇒ espace du rôle sans rien demander (`resolveAppRedirect`).
- Le rôle vient de `users/{uid}.role` après authentification : le choisir
  avant est inutile pour un compte existant.
- Auto-inscription : un client ne peut créer lui-même que `student` ou
  `parent`, sans établissement ; enseignant et administration passent par le
  serveur. C’est une règle d’auto-inscription, **pas** une limite de
  fournisseur : Google pourra authentifier aussi un enseignant ou un
  dirigeant, sans jamais lui attribuer ce rôle (voir
  `docs/architecture/IDENTITY_ACCESS_METHODS.md`).
- Un compte sans rôle ne lit aucun contenu du catalogue (`audienceAllows`).
- Liaison de fournisseurs déjà utilisée : téléphone lié à un compte e-mail
  existant par `linkWithCredential` (`firebase_phone_auth_repository.dart`).
- Code élève : jeton personnalisé pour l’UID de l’élève, indépendant du
  téléphone et de Google.

Limites : **un seul rôle par compte** (QA-14) ; téléphone limité aux mobiles
camerounais `+237 6XXXXXXXX` (`cameroon_phone_number.dart`) ; aucun paquet
Google Sign-In (`firebase_auth ^6.6.1` seul).

### 11.5 Architecture cible

**Entrée** (une seule, premier lancement et retour) :

> Bienvenue dans INTELLIA237
> [ Continuer avec mon numéro ] (principal)
> [ G  Continuer avec Google ]
> ——
> J’ai un code élève

Présentation de l’app : accessible depuis l’entrée (« Découvrir en 1
minute »), plus imposée avant le numéro.

**Après authentification** : un appel serveur `resolveMyAccess` renvoie les
espaces autorisés (`student`, `parent`, `teacher`, `admin`…), les
invitations en attente et l’état (`known`, `new`, `visitor`).

- un seul espace ⇒ ouverture directe ;
- plusieurs ⇒ « Comment voulez-vous utiliser INTELLIA237 aujourd’hui ? »
  (choix mémorisé, modifiable dans Paramètres) ;
- nouveau ⇒ « Que souhaitez-vous faire ? » [Découvrir INTELLIA237]
  [Rejoindre mon école] [Retrouver mon compte].

**Séparation des notions** : Identity (UID Firebase) ; Access Methods
(`PHONE`, `GOOGLE`, `STUDENT_ACCESS_CODE`, et `EMAIL` existant) ;
Relationships (liens parent-enfant approuvés, appartenance d’école accordée
par le serveur) ; Beneficiary / Payer (facturation par enfant, inchangée). Le
rôle ne dépend jamais du fournisseur.

### 11.6 Google Sign-In

- **Paquet** : `google_sign_in` (API 7.x, Credential Manager sur Android)
  puis `GoogleAuthProvider.credential(idToken:)` et
  `signInWithCredential`. Repli : `FirebaseAuth.signInWithProvider(
  GoogleAuthProvider())` (flux navigateur, sans paquet). Compatibilité des
  versions avec Flutter 3.44 et `firebase_auth` 6.x à vérifier au moment de
  l’implémentation.
- **Console** : fournisseur Google activé (staging, puis production) ;
  empreintes SHA-1 et SHA-256 de la clé de signature Play, de la clé
  d’upload et de la clé debug ; `google-services.json` régénérés ;
  identifiant client Web comme `serverClientId`.
- **Bouton** : logo « G » multicolore officiel, non modifié, texte
  « Continuer avec Google », variantes claire et sombre des directives de
  marque Google ; libellé TalkBack « Continuer avec Google ».
- **Déconnexion** : `GoogleSignIn.signOut()` en plus de Firebase, sinon un
  appareil familial partagé rouvrirait le compte Google précédent ;
  `disconnect()` à la suppression du compte.
- **Aucun droit** : un nouveau compte Google n’a ni établissement, ni
  classe, ni enfant, ni rôle enseignant ou administration ; règles
  inchangées sur ce point ; l’adresse Gmail n’est jamais une preuve de rôle
  ni d’appartenance.

### 11.7 Liaison de comptes (sans fusion automatique)

| Cas | Traitement |
| --- | --- |
| Parent connu par téléphone (UID A) ajoute Google | Paramètres → Méthodes de connexion → « Ajouter Google » ⇒ `linkWithCredential` sur A ; même UID |
| A ouvre « Continuer avec Google » sur un nouvel appareil | Firebase crée un UID B vide. Aucun profil créé. Écran : « As-tu déjà un compte INTELLIA237 avec ton numéro ? » Oui ⇒ code SMS (A) ⇒ callable `adoptGoogleIdentity` : vérifie le jeton Google, vérifie que B est vide et récent, supprime B, lie le fournisseur Google à A (`updateUser(A, { providerToLink })`, à confirmer avec la version du SDK Admin). Preuve des deux moyens exigée. Si B a déjà des données : aucune fusion, procédure d’assistance |
| Google déjà lié à un autre compte | `credential-already-in-use` ⇒ message clair, jamais de bascule silencieuse |
| Collision d’e-mail (enseignant e-mail + mot de passe, même Gmail) | paramètre « un compte par adresse » à vérifier dans la console ; si `account-exists-with-different-credential` ⇒ se connecter avec la méthode existante puis lier ; comportement Firebase à tester : Google peut devenir le fournisseur de référence d’une adresse Gmail non vérifiée |
| Compte Google créé d’abord, téléphone ajouté ensuite | `linkWithCredential(phone)` (chemin existant) ; numéro déjà utilisé ⇒ se connecter par téléphone puis adopter Google (cas 2) |
| Google retiré | seulement s’il reste un autre moyen |
| Numéro changé | vérification du nouveau numéro, `updatePhoneNumber` ; cohérence avec la migration du téléphone familial |
| Récupération | téléphone perdu ⇒ Google ; Google perdu ⇒ téléphone ; les deux ⇒ procédure super-administration avec attestation (école ou parent), jamais par e-mail seul |
| Élève à code | inchangé ; le code élève reste l’accès sans téléphone, aucun élève n’est obligé de passer par Google ; proposer Google aux comptes élèves (mineurs) reste **à décider** par le propriétaire |
| Enseignant ou dirigeant par Google | Google prouve l’identité ; le rôle vient d’une invitation acceptée ou d’une validation serveur, jamais du fournisseur |

### 11.8 Mode découverte

- **État `visitor`** : utilisateur authentifié sans profil qui choisit
  « Découvrir ». Aucun document `users` créé (les règles n’acceptent que
  `student` et `parent`) ; aucune lecture de données scolaires possible.
- **Contenu** : présentation, cartes de démonstration **étiquetées comme
  telles** (pas de faux élèves), une activité interactive jouée hors ligne
  (fonctionne sans serveur), Kira / Léo en démonstration scriptée locale.
  Un vrai compagnon pour visiteurs exigerait une callable séparée, sans
  contexte, avec quota strict et App Check imposé : à décider plus tard.
- **Sorties** : « Rejoindre mon école » (élève : inscription habituelle),
  « J’ai un code élève », « Je suis parent » (liaison par code enfant
  **après** authentification), « J’ai une invitation » (personnel).
- **International** : Google est la voie des personnes sans numéro
  camerounais ; la politique SMS (+237 seulement) reste inchangée dans cette
  phase.

### 11.9 Enseignant et direction : invitations

Collection `staff_invitations` créée par une administration autorisée
(Studio ou campus) avec téléphone ou e-mail, usage unique, expiration.
Après authentification, le serveur rapproche le numéro vérifié ou l’e-mail
Google **vérifié** : « Vous avez été invité par École X » [Accepter]. Le rôle
est accordé par le serveur, jamais par le fournisseur.

### 11.10 Faible littératie numérique

Une action principale par écran ; phrases courtes ; boutons de 56 px ;
+237 affiché, saisie « 6XX XXX XXX » normalisée (déjà le cas) ; clavier
numérique et remplissage automatique du code (déjà en place) ; « Nous
t’envoyons un code par SMS » ; erreurs : « Tu n’as pas reçu le code ? »
[Renvoyer le code], « Vérifie ton numéro et réessaie », « La connexion
Google a été annulée », « Ton compte est prêt. Découvrons maintenant
INTELLIA237. » ; jamais de code Firebase brut (les messages d’erreur
d’authentification restent à traduire : 26 chaînes FR seulement dans
`firebase_error_mapper.dart`). Registre : tu pour l’élève, vous pour
l’adulte ; sur l’écran commun, formulation neutre.

### 11.11 Sécurité

| Sujet | Position |
| --- | --- |
| Énumération de comptes | le conflit de rôle n’apparaît qu’après le code SMS ; garder les messages génériques avant preuve ; vérifier dans la console que la protection contre l’énumération d’e-mails est activée |
| Collision de fournisseurs | voir 11.7 ; jamais de fusion automatique |
| Jetons | jetons d’identité Firebase uniquement côté serveur ; jeton Google vérifié côté serveur (audience = notre client) pour l’adoption |
| Déconnexion | Firebase + Google ; frontière de session élève déjà en place (`learnerSessionBoundaryProvider`) |
| Révocation | suppression de compte : `deleteUser` supprime tous les fournisseurs ; `disconnect()` côté app |
| App Check | inchangé ; à imposer sur les nouvelles callables d’authentification |
| Fixation de session | sans objet (jetons Firebase) ; choix d’espace stocké localement mais vérifié par le serveur à chaque accès |
| Multi-rôle | rôles attribués par le serveur ; règles adaptées (`hasRole`) |

### 11.12 Fichiers à modifier au prochain cycle

`pubspec.yaml` ; configuration Android (`google-services.json` des deux
variantes) ; `lib/features/auth/presentation/auth_gateway_screen.dart`,
`register_screen.dart`, `phone_auth_screen.dart`,
`student_access_code_screen.dart`, `widgets/auth_choices.dart`,
`widgets/school_head_access.dart` ; nouveau bouton Google et logo officiel ;
`lib/features/parent/presentation/parent_entry_screen.dart` ;
`lib/features/auth/data/repositories/` (dépôt Google) ;
`auth_controller.dart`, `auth_state.dart`, `app_role.dart` ;
`lib/app/router/app_router.dart`, `app_routes.dart` ; Paramètres (méthodes
de connexion) ; ARB FR / EN ; Functions : `resolveMyAccess`,
`adoptGoogleIdentity`, invitations ; `firestore.rules` (multi-rôle,
invitations) ; suppression de compte (Google) ; tests.

### 11.13 Tests à prévoir

- **Téléphone** : parent nouveau, parent existant, code faux, renvoi, numéro
  invalide.
- **Google** : nouveau compte, compte existant, annulation, collision,
  liaison, déconnexion puis reconnexion sur appareil partagé.
- **Code élève** : valide, invalide, après rotation.
- **Multi-rôle** : parent, enseignant, parent + enseignant (sélecteur).
- **Sécurité** : un compte Google ne s’attribue ni école, ni rôle enseignant
  ou administration ; un visiteur ne lit aucune donnée scolaire (règles et
  callables).
- **UX** : 360 px, texte 1,3 et 2,0, TalkBack, zones tactiles, logo Google
  accessible, états de chargement.

### 11.14 Plan d’implémentation atomique (après validation)

1. **Entrée simplifiée** : écran unique (numéro, Google désactivé derrière un
   drapeau, code élève) ; rôle retiré avant authentification ; présentation
   optionnelle. Tests de routage et de mise en page.
2. **Routage automatique** : a) espace unique déduit du profil après
   authentification ; nouveau compte ⇒ « Que souhaitez-vous faire ? » ;
   b) multi-rôle : rôles gérés par le serveur, règles `hasRole`, sélecteur.
3. **Fournisseur Google** : paquet, console staging, bouton officiel,
   déconnexion complète ; drapeau activé en staging seulement.
4. **Liaison de comptes** : ajout dans Paramètres, `adoptGoogleIdentity`,
   gestion des collisions ; tests émulateur Auth.
5. **Mode découverte** : état `visitor`, contenu de démonstration étiqueté,
   sorties.
6. **Invitations du personnel** : `staff_invitations`, acceptation.
7. **Tests** complets (11.13) et recette staging.
8. **Finitions** : accessibilité, animations discrètes, textes.

Chaque étape : un commit atomique, tests verts, aucun déploiement.

## 12. Verdict

Le SHA `11eb26c` est poussé et figé. Le code est prêt à être relu : tests
locaux et CI backend / Studio verts, diff inventorié, risques et ordre de
déploiement écrits. Réserves à transmettre au relecteur : CI mobile rouge
pour une raison documentaire (QA-01, analyse et tests mobiles non rejoués en
CI), ordre de déploiement imposé par `askTutor` (QA-02), politique TTL
manquante (QA-03). Aucune ne justifie de modifier le SHA avant la revue.

READY FOR INDEPENDENT REVIEW
