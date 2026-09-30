# Audit Quiz et exercices — post-release +39

## Périmètre et nombres reproductibles

Le scanner parcourt récursivement tous les JSON de `assets/content/**`, puis
les JSON d'assets hors Content Engine. L'inventaire complémentaire exporte les
exercices Dart de Flow et Campus. Aucun accès au corpus distant de production.

| Mesure | Avant | Après S1 et corrections |
|---|---:|---:|
| Packs locaux | 7 | 8 |
| Questions/activités runtime | 283 | 329 |
| Autoévaluations explicites | 33 | 41 |
| Questions objectivement éligibles au Quiz | 250 | 288 |
| Erreurs structurelles scanner | 0 | 0 |
| Warnings scanner | 46 | 37 |

S1 ajoute 46 activités et inventorie séparément 29 groupes/79 consignes
sources. Les autres extractions n'ont pas un schéma homogène de consignes du
manuel : aucun total global d'exercices imprimés n'est inventé. Le total 329
désigne les activités runtime, pas 329 exercices distincts du manuel.

38 exercices statiques hérités : 35 Flow (23 QCM, 4 VF, 4 trous, 4 ordres),
3 QCM Campus. Le scanner d'assets trouve 0 ancien Quiz JSON parmi 9 fichiers
inspectés ; ces 38 contenus sont dans Dart. L'export les conserve avec leurs
énoncés, clés, explications, points et leur statut de démonstration.

Commandes : `python -X utf8 tool/content/audit_content.py --output <rapport>` ;
`python -m unittest discover -s tool/content -p test_audit_content.py`.
Le scanner retourne un code non nul pour ERROR, pas pour un soupçon lexical.

## Corrections CONFIRMED

1. `PackQuizScreen` et `PracticePanel` : un feedback de distracteur masquait
   l'explication générale alors que le Compagnon invitait à la lire. Les deux
   sont désormais visibles après correction, avec la réponse attendue. La
   revue finale montre aussi la clé et son explication.
2. Ensembles/listes : `1 -2` devenait `{1,2}` et `1/2` devenait deux entiers.
   Les signes sont préservés et une division n'est plus un séparateur.
3. Entiers : normalisation commune des moins Unicode/espaces avant de lire
   une valeur décimale à zéros, par exemple `− 5,00`.
4. Expressions : casse des variables préservée ; `T` et `t` ne sont plus
   considérées identiques. Le texte ordinaire garde son normaliseur dédié.
5. Physique M1S2 `l2_q05` : l'unité d'accélération est dérivée, pas
   « fondamentale ». L'énoncé demande maintenant son écriture en unités de
   base, sans changer la relation source.
6. Physique `l5_q03` et fonctions `l1_h1` : deux indices donnaient la valeur
   ou l'unité finale. Ils donnent désormais une procédure de résolution.
7. Arithmétique `l5_h1` : une face carrée et un volume 6647 ne suffisaient pas
   à exclure `(1,1,6647)`. Le runtime dérivé ajoute explicitement « toutes
   strictement supérieures à 1 cm » ; `(17,17,23)` devient univoque. C'est une
   **condition d'auteur ajoutée**, pas une donnée attribuée au manuel. Les
   nombres sources sont conservés. Le contre-exemple est testé.
8. Sept activités Mathématiques sans feedbacks de choix reçoivent des
   explications distinctes, attachées aux valeurs/IDs : CH01 `l1_e2`, `l2_e3`,
   `l3_m1`, `l4_m2`, `l5_e2` ; CH02 `l1_e2`, `l2_m4`.

Ces edits de contenu touchent 11 questions dans quatre packs. Les empreintes
des packs concernés sont recalculées. La science issue du manuel n'est pas
remplacée par une réponse improvisée.

## Lecture sémantique et réserves

Lecture locale de tous les énoncés/clés des 329 activités, par matière et
notion, complétée par les tests de notation et les sources canoniques :
division entière signée, divisibilité, congruences, nombres premiers, PGCD,
complexes, racines/limites/asymptotes, moyennes/incertitudes/arrondis, équations
aux dimensions, vocabulaire/grammaire anglaise, échanges cellulaires. La
relecture a trouvé le cas du coffret ci-dessus. Elle ne constitue ni une
certification éditoriale ni une nouvelle inspection intégrale de toutes les
photos des anciens manuels. S1 possède sa propre revue des images.

Les 37 warnings restants sont :

- **29 PROBABLE `choice_feedback_generic`** : les distracteurs répètent un
  retour générique dans certaines questions, surtout en Physique. La clé et
  l'explication source sont désormais visibles ; leur amélioration spécifique
  reste à faire après revue de chacun des distracteurs.
- **3 CONFIRMED `correct_choice_position_bias`** dans les données brutes.
  Les interfaces actives mélangent les choix par tentative avec IDs/valeurs
  stables ; tests maintenus. Pas de déplacement arbitraire des clés.
- **4 NEEDS_SOURCE_REVIEW `short_text_alternatives_review`** : phrases
  verbales passives anglaises. Les formes attendues sont grammaticalement
  cohérentes ; il faut revoir d'autres formulations réellement légitimes sans
  rendre la correction permissive à toute phrase ressemblante.
- **1 PROBABLE `hint_reveals_answer`**, fonctions `l1_m5` : le chiffre 3
  apparaît comme coefficient de la dérivée, alors que la réponse est un nombre
  de racines. Ce signal lexical est un **faux positif probable**, pas une fuite
  démontrée. L'indice mathématique utile est conservé.

Les flags source déjà présents (données graphiques peu lisibles, coordonnées
floues, limites/notations du manuel, audio manquant, sign-off anglais
contradictoire) restent explicites. Les six familles S1 sont détaillées dans
son rapport. Les sources insuffisantes ne donnent pas de corrigé inventé.

## Modes, progression et héritage

TRAINING : verdict, erreur choisie, réponse attendue et explication visible
immédiatement. ÉVALUATION : ni correction ni indice/Compagnon révélateur avant
le bilan validé. POST-ÉVALUATION : revue complète. Les tests UI contrôlent
l'absence de fuite et la présence de la correction.

Les productions libres sont hors correction automatique et Quiz objectif.
Leur autoévaluation nourrit la révision sans compter comme bonne réponse.
Routage de classe/série et ordre de choix utilisent les contrats existants.

FlowDemoContent est un corpus de debug ; le backend `FLOW_CATALOG` fournit
l'équivalent pédagogique côté serveur. Campus est actuellement piloté par
`DemoCampusRepository` : les 3 questions statiques sont inventoriées et son
générateur `index % 4` fabrique des clés de prévisualisation arbitraires.
**CONFIRMED : ces Quiz générés ne doivent pas être publiés comme contenu validé.**
Ils ne constituent pas un corpus pédagogique quantifiable ; leur nombre
dépend de l'action de prévisualisation. Cette mission ne transforme pas les
fixtures Campus en évaluations certifiées.

Dans l'ancien scoring Functions, `parseInt` accepte un préfixe comme
`0junk`, et la réponse courte normalise seulement trim/lowercase. Ce sont
des limites CONFIRMED du chemin hérité, documentées pour un lot Functions
distinct. Les fonctions déployées et leur code n'ont pas été modifiés.
Sans export distant, le nombre et la qualité des questions production restent
**inconnus** ; l'audit local ne prétend pas les avoir vérifiés.

## Tests

11 tests du scanner et 81 tests Flutter ciblés sont verts. Régressions de normalisation,
contre-exemple du coffret, feedbacks, UI corrigée, modes et anciens exercices
complètent les tests Content Engine/Quiz/Compagnon. Les totaux de la suite
finale et analyze sont consignés dans le rapport global.
