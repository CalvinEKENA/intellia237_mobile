# INTELLIA237 — livraison post-release +39

30 septembre 2026. Branche `feat/content-engine`, base `3556599`, version
**3.2.1+39**. Première vague P0 livrée en lots distincts. Les limites ci-dessous
font partie du résultat : S2–S19 ne sont pas annoncées comme des packs livrés.

## 1. SVT Terminale D

Le stash nommé `svt-source-pre-build-38` a été retrouvé, inspecté avec ses
fichiers non suivis, sans `pop`. Deux fichiers seulement ont été récupérés
depuis son troisième parent : `corpus_index.json` et
`sequence_01_les_echanges_cellulaires_source.json`. Aucun ancien changement
Auth/release du stash n'a été restauré.

S1 canonique : cours imprimé p.3–14, exercices p.15–21 ; 15 images inspectées,
5 leçons, 14 notions, 46 activités dont **38 auto-corrigibles** et 8 productions
en autoévaluation. L'inventaire source distingue 29 groupes et 79 consignes.
Les incertitudes restent déclarées ; aucune valeur ambiguë n'est notée.
Source, pédagogie, runtime, validation, manifeste et asset Flutter sont intégrés
à Learn, Quiz et au Compagnon déterministe. Tests propres S1 : 8.

Le plan S2→S19 priorise le Module 1. Un petit lot de source S2 p.23–29 est
commité : quatre images, 14 éléments vérifiés, deux réserves. Il reste
**PARTIAL_SOURCE_ONLY_NOT_RUNTIME** ; p.30–42 doivent encore être inspectées.
La mission ne prétend pas avoir publié 19 séquences.

Détails : [SVT_POST_RELEASE_39](../content_engine/SVT_POST_RELEASE_39.md).

## 2. Audit Quiz / exercices

Scan récursif et lecture sémantique locale de **8 packs, 329 activités**,
dont **288 éligibles au Quiz** et 41 manuelles ; 43 JSON Content Engine et
9 JSON d'assets hérités inventoriés. L'export Dart ajoute 38 exercices statiques
hérités, avec leur statut de démonstration. Aucun corpus distant n'a été
présenté comme audité sans export de production.

Le scanner donne **0 erreur structurelle et 37 warnings**, contre 46 warnings
avant S1/corrections : 29 feedbacks génériques PROBABLE, 3 biais de position
CONFIRMED dans les données (choix mélangés dans l'UI), 4 réponses anglaises à
revoir avec la source, 1 indice PROBABLE probablement faux positif.

Corrections de 11 activités dans quatre packs : sept ensembles de feedbacks
spécifiques, unité d'accélération, deux indices révélateurs et condition
explicite de non-dégénérescence du coffret de volume 6647. Cette dernière est
une condition d'auteur déclarée, avec contre-exemple testé. Le correcteur
préserve les moins Unicode, les signes d'entiers et la casse des variables ;
une division ne devient plus une liste. En entraînement, clé et explication
restent visibles même avec un feedback de distracteur. En évaluation, aucune
correction ne fuit avant le bilan ; la revue finale est complète.

Réserves : source partiellement lisible, variantes grammaticales, clés Campus
de prévisualisation arbitraires et permissivité de l'ancien scoring Functions.
Les Functions n'ont pas été modifiées. Ces constats ne deviennent pas des
corrigés improvisés. 11 tests Python et 81 tests Flutter ciblés de l'audit
passent ; les suites intégrales complètent cette validation.

Détails : [QUIZ_AUDIT_POST_RELEASE_39](../content_engine/QUIZ_AUDIT_POST_RELEASE_39.md),
[inventaire après](../content_engine/quiz_audit_after.json).

## 3. Profil

Le vrai `StudentProfileTab` et ses écrans associés ont été refaits : identité
INTELLIA PASS, progression et objectif, Compagnon, Réserve, accès parent,
réglages et sortie. Papier clair, indigo, typographies existantes, avatar avec
fallback local ; lignes à hauteur naturelle et contrôles qui se réorganisent.

Cupertino : ListSection, Button, Switch, Slider, FormSection,
TextFormFieldRow, ActionSheet, AlertDialog et DialogAction. Le shell Android
et ses routes restent utilisés. Les lignes fixes et les segments trop étroits
ont été écartés après l'audit responsive.

Édition, email immuable/vérification, liaison téléphone, avatar, objectifs,
rappels, préférences, vibrations, rôles, parent, confidentialité, suppression,
liens légaux et déconnexion sont conservés. Une écriture d'avatar échouée
annule la prévisualisation ; une édition échouée garde les champs.
**23 tests dédiés**, dont FR/EN × 320/360/412/480 px, texte ×2 et hors ligne.

Détails : [PROFILE_POST_RELEASE_39](../design/PROFILE_POST_RELEASE_39.md).

## 4. Higgsfield

Balance réellement vérifiée, puis revérifiée : plan free, **2,75 crédits** ;
1 gratuit Genjutsu (motion control/object replacement, 480p, ≤30 s) et
1 gratuit Viral (480p/720p). Essai pending ; unlimited indisponible.

Neuf moments ont été comparés. Choix : **« Le cap franchi »**, une première
maîtrise complète de chapitre fondée sur les notions, au bilan final, une
fois par élève/chapitre ; durée cible 1,1 s. Flutter garde tous les nombres,
textes et commandes ; fallback natif et aucune vidéo en Reduce Motion.

Les offres gratuites inspectées ne permettent pas ici une nouvelle scène
appropriée sans entrée vidéo adéquate ou preset hors sujet. La génération
était optionnelle : **aucun job**, job ID sans objet, coût **0 crédit**, crédits
restants **2,75**, compteurs gratuits intacts. Aucune nouvelle vidéo intégrée,
aucune réutilisation Splash/Auth et aucun essai activé.

Détails : [étude Higgsfield](../branding/HIGGSFIELD_CHAPTER_MASTERY_POST_RELEASE_39.md).

## 5. Jeux Terminale D

Audit des quatre matières réellement disponibles : Maths (3 packs), Anglais
(2), Physique (2), SVT (1). Avant : 39 blueprints, 7 jouables en arithmétique,
32 draft. Mini-spec et bibliothèque de 14 familles de mécaniques, avec P0/P1/P2.

Un moteur `matching` réutilisable et trois jeux livrés : **Document Dash**
(9 associations), **Laboratoire des unités** (10), **Liens membranaires** (9).
Neuf plateaux progressifs de niveau 1 à 3, relations et corrections sourcées,
deux taps par association, paires verrouillées, erreurs expliquées et replay
déterministe à graine différente. Pas de QCM déguisé, chrono imposé ou points
arbitraires. Offline, sans LLM ni nouvel asset distant.

Le catalogue compte **40 blueprints, 10 jouables, 30 draft**. Complexes,
fonctions et d'autres mécaniques restent planifiés. Les durées 2–3 minutes
sont des cibles de conception, pas des mesures d'usage.

Les preuves vont dans le même `LearnerContentSnapshot/MasteryState` que les
leçons et Quiz. Une réussite sans erreur ni aide n'est enregistrée qu'une
fois par plateau ; un replay ne crée pas de gain supplémentaire. Une partie
aidée ne certifie pas un acquis. Une complétion erronée ajoute une tentative
négative, pas une pénalité par tap. Écriture locale vérifiée et retry.
**25 tests dédiés** : données invalides retenues en draft, notation, replay,
concurrence, aide, persistance, erreurs de stockage et toutes les largeurs.

Détails : [TERMINALE_D_GAME_MAP](../content_engine/TERMINALE_D_GAME_MAP.md).

## 6. Parcours

Le fil existant demeure monté sous une nouvelle vue d'ensemble ouverte depuis
le HUD ou l'état vide. Visualisation majeure : **carte des chapitres et anneaux
de notions maîtrisées**, avec nombres/statuts et leçon suivante réelle.
Secondaires : **heatmap Quiz de 14 jours** et **courbe de résultats par ensemble
et mode**. Une observation seule n'invente pas une évolution.

Sources : maîtrise locale par notion, historique local des 30 dernières séances
Quiz terminées, objectif déclaré et jours actifs enregistrés. Les minutes
cibles ne deviennent pas des minutes étudiées ; aucun historique de maîtrise
n'est fabriqué. Les preuves locales des jeux alimentent la même carte ; elles
ne sont pas présentées comme des métriques serveur du Profil synchronisées.

Arcs/courbe CustomPainter, heatmap native et texte accessible ; animations
finies de 350 ms, sans ticker/vidéo/token. Reduce Motion affiche les valeurs
finales et supprime la transition de feuille. **19 tests dédiés** : métriques,
FR/EN × 320/360/412/480 px × texte 1,5, CTA, modes séparés, vide/erreur,
conservation du fil et fin des animations. Aucun FPS Android physique mesuré.

Détails : [PARCOURS_VISUAL_SYSTEM](../design/PARCOURS_VISUAL_SYSTEM.md).
Captures de widgets vérifiées, polices réelles et données de test :
`build/post_release_39/profile_412.png`, `build/post_release_39/parcours_412.png`.

## Engineering et vérification finale

- `flutter analyze --no-pub lib test tool` : **0 problème**.
- `dart format --output=none --set-exit-if-changed lib test tool` :
  **860 fichiers, aucun changement**.
- `dart run tool/check_brand_references.dart` : **pass**.
- Suite Flutter intégrale : **2 667 réussis, 3 ignorés, 0 échec** (13 min 02 s).
  Les trois tests digest partenaire requièrent des variables privées non
  fournies ; aucun accès n’a été ajouté pour les exécuter. Les deux nouveaux
  contrôles d’empreintes ont été validés séparément dans la sous-suite de 62
  tests après le lancement de la suite globale.
- Scanner Python : **11 tests réussis**, 0 erreur structurelle.
- Packs/livraison/empreintes : **62 tests ciblés réussis** ; les **28 empreintes
  déclarées** correspondent aussi aux vrais blobs committés Git.
- Fins de ligne JSON LF imposées par `.gitattributes` ; les comparaisons XML/CSV
  de tests tolèrent CRLF. Le scanner de marque exclut caches et credentials
  locaux ; les sources actives restent contrôlées.

La première passe globale a signalé des attentes de catalogue à trois matières,
le registre de la nouvelle carte et deux comparaisons CRLF. Corrections testées,
puis seconde passe intégrale. Les résultats des sous-suites se recoupent : ils
ne sont pas additionnés au total global.

**CI GitHub non déclenchée/non certifiée** : aucun push, PR ou déploiement dans
cette mission ; les commandes de qualité mobile sont validées localement.
Version toujours 3.2.1+39. Aucun merge, publication Play Store, changement de
package Android, Firebase production ou Functions. L'accès partenaire reste
inchangé ; les six fichiers parasites demeurent non suivis et hors commits.
Le seul edit pubspec est la déclaration de l'asset S1.

## Commits et fichiers

| SHA | Lot |
|---|---|
| `5a495e7` | étude du moment Higgsfield |
| `3a33762` | récupération SVT et pack S1 |
| `0660a9d` | petit lot de source S2 |
| `74c88ed` | audit et corrections Quiz |
| `71ef475` | textes localisés des nouvelles interfaces |
| `9583c28` | profil Cupertino |
| `f62f141` | moteur d'association et trois jeux |
| `0d66139` | visualisations Parcours |
| `8a9897b` | intégration SVT dans les tests Hall/démo |
| `1fa3d53` | contrôles qualité portables |
| `7d87020` | vérification finale des quotas gratuits |
| `b7fab31` | empreintes des octets canoniques |

**94 fichiers** au total depuis `3556599`, rapport inclus. La majorité des
lignes ajoutées sont les données sources/runtime SVT et les inventaires
machine. Les chemins et diffs exacts sont consultables avec
`git diff 3556599 --name-only` et `git log --oneline 3556599..HEAD`.
Le commit de ce rapport est annoncé dans la réponse finale après validation.
