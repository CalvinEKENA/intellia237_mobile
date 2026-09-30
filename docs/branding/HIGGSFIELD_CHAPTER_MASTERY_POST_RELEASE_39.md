# Post-release +39 — une cinématique de maîtrise, étude du 30/09/2026

## Décision

**Candidat retenu : « Le cap franchi »**, première maîtrise complète d'un
chapitre confirmée à la fin d'un Quiz. Une respiration visuelle de **1,1 s**,
derrière le vrai bilan Flutter, sans attendre pour consulter ses corrections.
Ni une bonne réponse ordinaire, ni le simple fait d'avoir terminé un Quiz ne
doivent déclencher cette scène.

**Étude réalisée ; aucune génération soumise, aucune nouvelle vidéo intégrée.**
L'offre gratuite existe, mais ses deux voies ne fournissent pas actuellement
une création vidéo libre depuis ce seul brief : Genjutsu exige une vidéo de
mouvement et une image de référence ; les presets Viral inspectés imposent des
scènes/personnages/effets éloignés du décor sobre recherché. Le rendu procédural
Flutter actuel reste fonctionnel. Les crédits et les deux essais gratuits sont
préservés. La permission de faire au maximum une génération n'est pas une
obligation de consommer un essai sur un preset inadapté.

## Vérifications du compte, en lecture seule

Outils interrogés : `higgsfield_balance`, `models_search`, `models_get`,
`get_presets`, `get_preset_instructions` (instructions `/genjutsu`).

| État observé | Valeur retournée |
|---|---|
| Plan | `free` |
| Crédits | **2,75** |
| Genjutsu | **1** essai partagé entre `hf_mult_motion_control` et `hf_mult_replace_object` |
| Contraintes gratuites Genjutsu | **480p**, maximum **30 s** |
| Viral | **1** essai `viral_hub_video`, **480p ou 720p** |
| Essai de souscription | `pending` ; `unlim_available: false` |
| Job soumis | aucun ; job ID : sans objet |
| Coût réel de cette étude | **0 crédit** |

Le champ `trial_credits: 100` ne signifie pas qu'une allocation vidéo illimitée
est utilisable : le serveur indique explicitement `unlim_available: false`.
Aucun essai de souscription n'a été activé. GPT Image 2 n'a pas été appelé et
aucune image n'est présentée comme une vidéo.

Les réponses du serveur précisent que `use_free_gens: true` refuse une demande
hors des contraintes gratuites au lieu de la facturer. Une éventuelle future
soumission devra **toujours** conserver ce paramètre, `count: 1`, 480p et une
vidéo de référence de moins de 30 s, après vérification actualisée du solde.

## Audit des emplacements réels

- Matière / cours : `content_subject_screen.dart`, `content_chapter_screen.dart`,
  `content_lesson_screen.dart`, `learn/presentation/lesson_viewer_screen.dart`.
- Cours → activité : `widgets/practice_panel.dart`, `games/game_screen.dart`.
- Quiz : `quiz/presentation/pack_quiz_screen.dart`, `_begin`, `_submit`, `_finish`,
  `_ResultView` ; anciens Quiz dans `quiz_result_screen.dart`.
- Compagnon : `content_engine/presentation/widgets/companion_sheet.dart` et
  `ai_companion/` ; l'aide doit arriver immédiatement et rester lisible.
- Maîtrise/déblocage : `content_engine/application/reward_bridge.dart`,
  `chapterMastered`, état existant `LearnerContentSnapshot`.
- Objectif : préférences/progression du Profil ; pas de nouvelle progression.
- Scènes existantes : `rewards/presentation/reward_stage.dart`,
  `reward_milestone.dart`, moteur `RewardEngine` et son délai de 25 s.

Le Splash INTELLIA AWAKENS et Auth → Home existent déjà. Ils ne font pas partie
des candidats ; leurs assets, contrôleurs et crédits ne sont pas réutilisés.

## Comparaison

Notes **de conception**, pas des mesures de télémétrie. Les fréquences sont
estimées depuis les déclencheurs dans le code. Pour les colonnes notées :
1 = faible, 5 = fort ; « coût » et « répétition » décrivent les risques.

| Moment | Fréquence probable | Émotion /5 | Pédagogie /5 | INTELLIA /5 | Repli Flutter /5 | Durée utile | Coût performance | Répétition | Gain vidéo /5 |
|---|---|---:|---:|---:|---:|---|---|---|---:|
| Entrée matière | élevée | 2 | 1 | 4 | 5 | 0,3 s | trop fréquent | fort | 1 |
| Ouverture cours | très élevée | 2 | 1 | 4 | 5 | 0,2 s | trop fréquent | très fort | 1 |
| Cours → activité | élevée | 3 | 3 | 4 | 5 | 0,4 s | modéré | fort | 2 |
| Lancement Quiz important | moyenne | 4 | 2 | 4 | 5 | 0,6 s | modéré | moyen | 3 |
| Résultat Quiz ordinaire | moyenne | 4 | 3 | 4 | 5 | 0,7 s | modéré | moyen | 3 |
| **Première maîtrise chapitre au bilan Quiz** | **rare** | **5** | **5** | **5** | **5** | **1,1 s** | **faible si préchargé** | **faible avec garde** | **4** |
| Apparition Compagnon | très élevée | 3 | 2 | 5 | 5 | 0,3 s | trop fréquent | très fort | 2 |
| Déblocage chapitre | rare | 4 | 4 | 5 | 5 | 0,8 s | faible | faible | 3 |
| Objectif hebdomadaire atteint | hebdomadaire | 4 | 4 | 5 | 5 | 0,8 s | faible | faible | 3 |

La première maîtrise relie l'émotion à un apprentissage confirmé. Une vidéo à
l'ouverture d'un cours retarderait une action fréquente ; un effet sur chaque
bonne réponse diluerait la valeur d'une réussite importante.

## Emplacement exact et garde proposée

Dans `lib/features/quiz/presentation/pack_quiz_screen.dart`, au passage unique de
`_changed` vers `PackQuizPhase.finished`, après calcul et enregistrement du
résultat dans `_finish`, pendant que `_ResultView` est déjà disponible.

Pour chaque chapitre représenté par les réponses objectives du résultat :

1. comparer les instantanés réels avant/après avec `chapterMastered` ;
2. exiger `false → true` ; une auto-évaluation ne suffit jamais ;
3. exiger toutes les réponses validées et la phase `finished` ;
4. conserver un marqueur local par élève et `contentId` pour éviter une seconde
   première-maîtrise après relecture ; le marqueur reste distinct du score ;
5. choisir un seul chapitre si plusieurs seuils sont franchis simultanément ;
6. respecter le délai du moteur, Reduce Motion, data saver et cycle de vie.

Ce branchement est **proposé, non implémenté** sans clip validé. L'actuel bloc
`result.perfect` n'est pas à utiliser comme preuve de maîtrise : un sans-faute
sur quelques questions et la maîtrise de toutes les notions sont différents.
Ne pas déclencher depuis `_submit` en évaluation : ce serait un indice avant le
bilan final. Ne pas ajouter de navigation ni de délai au Quiz.

## Direction de la scène

Objectif émotionnel : « j'ai construit une compréhension solide ». Un volume
de verre diffus s'éclaire doucement, l'espace s'ouvre puis se calme. Palette
crème, indigo très désaturé, menthe et reflets dorés discrets. Centre dégagé.
Aucun trophée générique, explosion, tunnel, flash, élève ou personnage.

| Temps dans l'app | Décor | Flutter souverain |
|---|---|---|
| 0–150 ms | lumière périphérique très douce | bilan et boutons déjà accessibles |
| 150–700 ms | réfraction et profondeur, expansion lente | vrai titre du chapitre et anneau de maîtrise |
| 700–1100 ms | retour à la surface calme | score, corrections et navigation inchangés |

Higgsfield pourrait apporter des caustiques, une réfraction organique et de la
profondeur volumétrique à faible coût de lecture, calculées une fois hors de
l'application. Flutter dessine très bien l'anneau, la progression et les
fondus ; obtenir ce seul supplément de matière réaliste avec des shaders
temps réel serait plus complexe sur les Android modestes. Ce gain reste
**potentiel tant qu'un clip n'a pas été produit et vu**. Flutter seul est déjà
plus robuste pour tout ce qui porte l'information.

Interdits dans les pixels générés : texte, logo, lettres, chiffres, score,
boutons, interface, cours, élève. Tous les éléments exacts sont des widgets.

## Modèle et faisabilité de l'offre gratuite

Modèle envisagé : **Genjutsu `hf_mult_motion_control`**, **480p**, un résultat.
Il transfère un mouvement existant vers une image de référence. L'alternative
`hf_mult_replace_object` remplace un objet dans une vidéo ; elle n'est pas
adaptée à la création de ce décor abstrait depuis un texte.

**Essai gratuit présent : oui. Utilisable directement avec les entrées
disponibles pour ce brief : non.** Il manque une nouvelle vidéo de mouvement
appropriée et une image de décor conforme. Les clips Splash/Auth existants sont
expressément exclus. Aucun média d'une ancienne génération ni vidéo tierce
n'a été utilisé comme référence sans lien avec ce travail.

Viral : consultation de 30 presets, puis recherches `crystal`, `light`,
`levitation`. `crystal` et `levitation` n'ont rien retourné ; `light` a surtout
retourné des personnages, néons, scènes de foule ou forte exposition. Les
presets examinés (dont Floating fall, World morphing, Cutout, Cold vision,
Superstar, Overexposed et 3D render) ne respectent pas cette intention sans
transformer arbitrairement leur scénario. L'étude ne prétend pas avoir rejeté
les 87 presets du catalogue un par un.

La génération est donc conservée. Aucun deuxième essai, aucun paiement,
aucun polling, aucun job en attente.

## Contrat d'une future intégration

- Asset local H.264 sans son, 24/30 fps, 480p, 1,1 s utiles, taille cible
  inférieure à 500 Ko **à mesurer**, pas un résultat déjà obtenu.
- Préparer le contrôleur pendant la dernière question, seulement si la
  maîtrise est éligible, sans initialisation avec Reduce Motion/data saver.
- Ne jamais attendre son chargement ; fichier absent, décodeur lent ou erreur
  → l'anneau et le fond Flutter actuels restent immédiatement disponibles.
- Zéro téléchargement au moment de la réussite ; fonctionnement hors ligne.
- `IgnorePointer` et `ExcludeSemantics` sur le décor ; ne pas masquer les
  corrections ; message réel accessible indépendamment de l'animation.
- Flutter fixe début/fin, opacité et durée ; arrêt en arrière-plan et libération
  du lecteur ; aucune boucle, aucun son, aucune navigation par callback vidéo.
- Reduce Motion : aucune vidéo, aucun décodeur préchargé, bilan statique.
- Vérifications requises avant intégration : première/dernière image, absence
  de pseudo-texte, contraste du vrai titre, 320/360/412/480 px et texte agrandi,
  lecteur absent/lent/en erreur, navigation pendant la scène, Android physique.

Les tests existants `test/features/rewards/reward_stage_test.dart` couvrent le
repli procédural, le passage des gestes et Reduce Motion. Ils ne prouvent ni
la performance d'un futur clip ni son rendu sur appareil réel.
