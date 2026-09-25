# INTELLIA237 — Content Engine (contenus pédagogiques locaux)

Moteur générique qui transforme des packs JSON validés en expérience
d'apprentissage complète **sans aucun appel à un modèle de langage** :
cours à trois niveaux d'explication, visuels manipulables, exercices corrigés
de façon déterministe, jeux, Compagnon hors ligne, adaptation et maîtrise
par notion, fil « Mon Parcours ».

Pilote : `assets/content/terminale_d/mathematiques/ch01_arithmetique/`.
Aucune ligne du moteur n'est propre à ce chapitre.

## Principes

1. **Aucun LLM en usage normal.** Un pack qui déclare `llm_required: true`
   n'est pas proposé. Des tests échouent si le Compagnon, la fabrique ou le
   classement du fil importent un client réseau ou un modèle de langage
   (`test/features/content_engine/companion_no_llm_test.dart`).
2. **Deux axes indépendants.** Difficulté (1 Facile, 2 Intermédiaire,
   3 Défi Bac) et explication (`standard`, `simple`, `ultra_simple`). Changer
   d'explication ne change jamais la difficulté.
3. **Données souveraines.** Le moteur ne corrige jamais une donnée : une
   incohérence devient une `ContentIssue`. Si elle rend la correction
   incertaine, la question est retirée des exercices notés.
4. **Validation respectée.** Un pack sans rapport, ou dont le statut
   contient `FAIL`, n'est pas proposé. Les anomalies de source
   (`source_quality_flags`) voyagent avec les questions concernées.
5. **Classe déclarée obligatoire.** Un contenu n'est montré qu'à la classe
   (et série) qu'il déclare ; son emplacement n'est jamais une preuve.

## Architecture (`lib/features/content_engine/`)

| Couche | Fichiers | Rôle |
|---|---|---|
| `domain/` | `curriculum`, `pedagogy`, `question`, `game_blueprint` (+ `GameStatus`), `companion_action`, `mastery`, `validation`, `chapter` (Chapter, Subject, ChapterEntry, PackOrigin), `pack_catalog` (catalogue distant, bundle), `visual_kind`, `content_issue` | Modèles fortement typés |
| `data/` | `content_pack_parser`, `content_pack_repository`, `content_delivery` (synchronisation), `content_pack_cache*` (fichiers ; web : préférences), `firebase_content_gateway`, `learner_content_store` | Lecture tolérante et versionnée, diffusion distante, cache, progression |
| `engine/` | `answer_checker`, `adaptive_engine`, `companion_engine` (+ `ConceptRouter`), `companion_name_policy`, `mission_planner`, `number_theory` | Correction déterministe, adaptation, Compagnon, prénom, missions |
| `feed/` | `learning_card`, `learning_card_factory`, `learning_card_history`, `learning_feed_ranker` | Cartes « Mon Parcours » tirées des packs |
| `application/` | `content_providers`, `learning_feed_providers`, `practice_session` | Riverpod |
| `presentation/` | écrans chapitre / leçon / intégration / jeu, visuels, jeux, Compagnon | Textes dans les ARB (préfixe `ce`) |

Classe et série : `lib/core/academics/class_key.dart` (`ClassKey`), partagé
avec Apprendre (`lib/features/learn/domain/learn_class_guard.dart`).

## Filtrage par classe (classe + série + matière)

* `ClassKey(level, series)` ; une cible sans série couvre toutes les séries
  du niveau ; `terminale-c-d` couvre C et D.
* Packs : `manifest.class_keys` (ou `curriculum.level`). Un pack sans classe
  n'est proposé à personne. Le filtrage a lieu avant toute lecture du
  chapitre, avant la fabrication des cartes et avant le cache.
* Catalogue en ligne (Firestore) : `LearnClassGuard` exige une classe
  déclarée sur le chapitre ou la matière ; le serveur applique la même règle
  (`declaresClass`, clause d'audience liée à `fallbackClass`) —
  **durcissement serveur codé, non déployé**.

## Diffusion sans reconstruire l'application

```
catalogue distant → pack versionné (bundle JSON) → vérifications
  → téléchargement → cache local → moteur
```

* Emplacement : Firebase Storage, `content/catalog.json` et
  `content/packs/<id>/v<version>/bundle.json`. Lecture réservée aux
  utilisateurs connectés, écriture interdite depuis l'app
  (`storage.rules`, **non déployé**).
* Priorité de lecture : version distante active validée → version
  précédente → pack embarqué → indisponible.
* Vérifications avant activation : statut `published`, classe servie,
  `minimum_engine_version ≤ kContentEngineVersion`, sha256 exact, bundle
  lisible, identité (id, version) conforme, pack jouable après analyse.
  Un échec n'écrase jamais la version en place.
* Cache : écriture atomique (fichier temporaire puis renommage), deux
  emplacements (actif, précédent). Un pack actif devenu illisible bascule
  automatiquement sur le précédent, puis sur l'embarqué. `withdrawn` retire
  le pack de l'appareil.
* Déclenchement : à l'ouverture d'Apprendre ou de Mon Parcours, en
  arrière-plan, et par « tirer pour actualiser » dans Apprendre. Un pack
  ajouté recompose le catalogue (`contentCatalogRevisionProvider`) sans
  redémarrage ; Apprendre affiche « Nouveaux contenus disponibles pour ta
  classe ». Hors ligne, rien ne change et tout reste utilisable.

### Catalogue (`content/catalog.json`)

```json
{
  "catalog_version": 3,
  "packs": [
    {
      "id": "maths_td_ch01_arithmetique",
      "version": 2,
      "status": "published",
      "class_keys": ["terminale-c-d"],
      "path": "content/packs/maths_td_ch01_arithmetique/v2/bundle.json",
      "sha256": "…64 caractères hexadécimaux…",
      "size_bytes": 81234,
      "minimum_engine_version": 1,
      "subject": "Mathématiques",
      "chapter_title": "Arithmétique"
    }
  ]
}
```

### Publier un chapitre sans reconstruire l'APK

1. Préparer le dossier du pack (5 fichiers JSON) et le valider :
   `CONTENT_PACK_DIR=<dossier> flutter test test/content_packs/validate_packs_test.dart`.
2. Construire le bundle et le catalogue :
   `dart run tool/content/publish_pack.dart --pack <dossier> --id <id> --version <n> --class terminale-c --class terminale-d`
   (`--catalog build/content_publish/catalog.json` pour repartir du
   catalogue en ligne téléchargé ; `--status draft` pour préparer sans
   publier). Sortie dans `build/content_publish/`.
3. **Avec l'accord du propriétaire**, envoyer d'abord le bundle, puis le
   catalogue (le script affiche les deux commandes `gcloud storage cp`,
   catalogue en `no-cache`).
4. Sur un appareil : ouvrir Apprendre, tirer pour actualiser. Le chapitre
   apparaît ; il reste disponible hors ligne.

Retirer : republier l'entrée avec `--status withdrawn`. Revenir en arrière :
republier la version précédente avec un numéro supérieur (jamais réutiliser
un numéro).

## Jeux

`status` explicite : `ready`, `draft`, `disabled` (sinon déduit : `ready`
si un moteur existe). Seuls les jeux `ready` avec un moteur et des niveaux
sont proposés (leçon et fil). Moteurs : `grouping`, `place_value`,
`modular_clock`, `factor_forge`, `tiling`, `remainder_zone` (Zone du Reste :
ajuster q, observer r jusqu'à 0 ≤ r < |b|, 3 niveaux dont diviseur
négatif), `integration_mission` (Mission Awa : étapes tirées des questions
d'intégration, avertissements de source affichés, esprit critique valorisé).

## Compagnon (sans modèle de langage)

Actions : « Explique-moi », « Plus simplement », « Comme si j'avais 12 ans »,
« Montre-moi », « Donne-moi un exemple », « Donne-moi un indice »,
« Pourquoi ma réponse est fausse ? », « Teste-moi » (difficulté suivant la
maîtrise, sauf choix de l'élève). Questions libres : normalisation, lexique
scolaire (PGCD, reste…), tolérance d'une faute de frappe, avantage à la
notion en cours. Hors pack : « pas encore disponible » et notions proches,
jamais d'invention. Prénom : première réponse importante, après plusieurs
erreurs, réussite notable ; jamais deux fois de suite
(`CompanionNamePolicy`, écart minimal 4 messages).

## Mon Parcours alimenté par les packs

* Cause de l'ancien « Aucune carte n'est encore publiée pour ta classe »
  en Terminale D : le fil ne lisait que `flow_items`, toutes ciblées 6e.
* `LearningCardFactory` fabrique, sans rien rédiger, 14 types de cartes
  (explication, 12 ans, question éclair, QCM, vrai/faux, exercice, visuel,
  jeu, piège fréquent, à retenir, défi, maîtrise, nouveau chapitre,
  invitation au Compagnon). Identifiants stables
  `contentId:conceptId:type:suffixe`.
* `LearningFeedRanker` : leçon en cours d'abord, remédiation après erreurs
  (simple → visuel → facile → intermédiaire), déjà-vu au repos (20 h),
  question manquée après 2 h, révision espacée 1/3/7/14 jours, variété
  (pas deux types de suite, pas plus de 3 cartes d'une notion, pas plus de
  2 questions d'affilée).
* Même pager que le fil publié (`FlowLearningCard` dans `FlowCard`) ;
  publications et packs s'entrelacent. Les réponses passent par le moteur
  de maîtrise de « S'entraîner » ; aucun point serveur n'est demandé.
* « Approfondir » ouvre la leçon à l'étape utile (`?step=`), le retour
  retrouve la même carte ; le Compagnon s'ouvre sur la carte.
* Historique local par élève (vue, répondue, juste, fausse, passée,
  dernière présentation).

## Anomalies relevées sur le pilote (non corrigées dans les JSON)

| Code | Détail | Effet / proposition |
|---|---|---|
| `validation_flag_page_level` ×2 | Les anomalies de `page_025.jpg` nomment une page, pas des questions | Rattachées aux 5 questions de la page. **Proposition : ajouter `question_ids`.** |
| `game_concept_unknown` | `mission_awa` vise `chapter_integration`, absent de `pedagogy.concepts` | Jouable via la convention « notion d'intégration ». **Proposition : `engine: "integration_mission"` et `status: "ready"` explicites.** |
| — | `remainder_zone` sans `engine` | Déduit de la notion (`remainder_band`). **Proposition : `engine: "remainder_zone"` explicite.** |
| — | Aucun `manifest.class_keys` | Classe déduite de `curriculum.level` (« Terminale D »). **Proposition : `class_keys: ["terminale-d"]`, ou `terminale-c-d` si le chapitre est commun.** |

Autres constats : aucune question n'a d'indice propre (le Compagnon utilise
les pièges, puis l'explication « simple ») ; peu d'exemples explicites
(« Donne-moi un exemple » s'appuie sur les questions faciles corrigées).

## Règles d'adaptation (depuis `runtime.mastery`)

* 2 erreurs sur une notion → proposer « Simple » ; 1 de plus → proposer
  « Comme si j'avais 12 ans » ; rien n'est imposé, une préférence
  verrouillée n'est jamais remise en question.
* 3 réussites consécutives → proposer la difficulté supérieure.
* Score de maîtrise 0–100 par notion ; la leçon suivante est conseillée à
  partir de 70 (jamais interdite).

## Vérification sur appareil Android

1. Compte Terminale D : Apprendre ne montre ni SVT « Le monde vivant » ni
   l'Anglais de 6e (garde client) ; « Chapitres interactifs » montre
   Arithmétique.
2. Compte Sixième : aucun contenu de Terminale, ni dans Apprendre ni dans
   Mon Parcours ; le fil 6e publié est inchangé.
3. Mon Parcours en Terminale D : des cartes dès l'ouverture ; balayer
   10 cartes ; répondre juste puis faux ; « Approfondir » puis retour
   (même carte) ; ouvrir le Compagnon depuis une carte ; ouvrir un jeu.
4. Mode avion après une première ouverture : Apprendre, leçon, jeux,
   Compagnon et Mon Parcours fonctionnent.
5. Texte système au maximum et écran 320–360 dp : boutons, segments,
   étapes et titres lisibles en entier (aucun « … »).
6. Zone du Reste niveaux 1 à 3 ; Mission Awa jusqu'au score final.
7. Après publication d'un pack de test (avec accord) : tirer pour
   actualiser dans Apprendre → bandeau « Nouveaux contenus… », chapitre
   visible, nouvelles cartes dans Mon Parcours sans redémarrer.
