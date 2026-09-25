# INTELLIA237 — Content Engine (contenus pédagogiques locaux)

Moteur générique qui transforme des packs JSON validés en expérience
d'apprentissage complète **sans aucun appel à un modèle de langage** :
cours à trois niveaux d'explication, visuels manipulables, exercices corrigés
de façon déterministe, jeux, Compagnon hors ligne, adaptation et maîtrise
par notion.

Pilote : `assets/content/terminale_d/mathematiques/ch01_arithmetique/`.
Aucune ligne du moteur n'est propre à ce chapitre.

## Principes

1. **Aucun LLM en usage normal.** Un pack qui déclare `llm_required: true`
   n'est pas proposé.
2. **Deux axes indépendants.** Difficulté (1 Facile, 2 Intermédiaire,
   3 Défi Bac) et explication (`standard`, `simple`, `ultra_simple`). Changer
   d'explication ne change jamais la difficulté.
3. **Données souveraines.** Le moteur ne corrige jamais une donnée : une
   incohérence devient une `ContentIssue`. Si elle rend la correction
   incertaine, la question est retirée des exercices notés.
4. **Validation respectée.** Un pack sans rapport, ou dont le statut
   contient `FAIL`, n'est pas proposé. Les anomalies de source
   (`source_quality_flags`) voyagent avec les questions concernées.

## Architecture (`lib/features/content_engine/`)

| Couche | Fichiers | Rôle |
|---|---|---|
| `domain/` | `curriculum`, `pedagogy` (Concept, Lesson, ExplanationMode, DifficultyLevel), `question` (Question, Answer scellé), `game_blueprint`, `companion_action`, `mastery` (MasteryState, préférences, suggestions), `validation` (ValidationFlag, rapport), `chapter` (Chapter, Subject), `visual_kind`, `content_issue` | Modèles fortement typés |
| `data/` | `content_pack_parser`, `content_pack_repository`, `learner_content_store` | Lecture tolérante et versionnée ; chargement depuis les assets ; progression derrière une interface (local aujourd'hui, Firebase plus tard) |
| `engine/` | `answer_checker`, `adaptive_engine` (+ `QuestionSelector`), `companion_engine` (+ `ConceptRouter`), `number_theory` | Correction déterministe, adaptation, Compagnon, arithmétique exacte |
| `application/` | `content_providers`, `practice_session` | Riverpod, séance d'entraînement partagée avec le Compagnon |
| `presentation/` | écrans chapitre / leçon / intégration / jeu, visuels, jeux, Compagnon | Interface (textes dans les ARB, préfixe `ce`) |

Entrées dans l'app : section « Chapitres interactifs » d'Apprendre (aussi
visible quand le catalogue en ligne ne répond pas), routes `/learn/local/…`.
Les parcours Firestore, Quiz et le compagnon en ligne ne sont pas modifiés.

## Ajouter un chapitre

1. Déposer le dossier du pack sous `assets/content/<classe>/<matiere>/<chapitre>/`
   avec `manifest.json`, `source.json`, `pedagogy.json`, `runtime.json`,
   `validation_report.json`.
2. Déclarer le dossier dans `pubspec.yaml` (un test échoue s'il est oublié).
3. Lancer `flutter test test/features/content_engine/` : les anomalies du
   pack sont listées par `Chapter.issues`.

Le chapitre apparaît automatiquement pour les élèves dont la classe
correspond à `curriculum.level` (ex. « Terminale D » → `terminale-d`).

## Schéma accepté (v1) et extensions facultatives

* `schema_version` : `intellia.<famille>.v<majeure>`. Une majeure supérieure
  à celle connue est refusée.
* Types de questions : `numeric`, `mcq`, `true_false`, `reasoning`,
  `procedure` (oui/non), `multi_step`, `solution_set` (entiers, ou
  congruences `n≡k (mod m)`), `multi_select`, `factorization`. Un type
  inconnu est signalé et non noté.
* Facultatifs reconnus dès maintenant (pour les futurs packs) :
  * `question.hints` / `question.hint` : indices propres à la question ;
  * `concept.visual_kind` : `grouping`, `place_value`, `remainder_band`,
    `modular_clock`, `factor_bricks`, `tiling` (sinon déduit de
    `visual_model`) ;
  * `concept.aliases` : mots-clés du Compagnon ;
  * `game.engine` : `grouping`, `place_value`, `modular_clock`,
    `factor_forge`, `tiling` (sinon déduit de la notion visée) ;
  * `source_quality_flags[].question_ids` : cible précise d'une anomalie ;
  * `manifest.content_id`, `manifest.curriculum` : catalogue sans lire
    `source.json`.

## Anomalies relevées sur le pilote (non corrigées)

| Code | Détail | Effet |
|---|---|---|
| `validation_flag_page_level` ×2 | Les anomalies de `page_025.jpg` nomment une page, pas des questions | Rattachées aux 5 questions de la page ; affichées seulement sur `int_awa2` et `int_awa3` (marquées `quality_sensitive` / `critical_thinking`). **Recommandation : ajouter `question_ids`.** |
| `game_concept_unknown` | `mission_awa` vise `chapter_integration`, absent de `pedagogy.concepts` | Jeu affiché « En préparation » |
| `game_engine_unavailable` ×2 | `remainder_zone`, `mission_awa` : aucun moteur encore | Affichés « En préparation » |

Autres constats : aucune question n'a d'indice propre (le Compagnon utilise
alors les pièges `common_mistakes`, puis l'explication « simple ») ; le
libellé du pack « Donne un indice » est reconnu comme l'action « indice ».

## Règles d'adaptation (depuis `runtime.mastery`)

* 2 erreurs sur une notion → proposer « Simple » ; 1 de plus → proposer
  « Comme si j'avais 12 ans » ; rien n'est imposé, une préférence
  verrouillée n'est jamais remise en question.
* 3 réussites consécutives → proposer la difficulté supérieure.
* Score de maîtrise 0–100 par notion ; la leçon suivante est conseillée à
  partir de 70 (jamais interdite).
