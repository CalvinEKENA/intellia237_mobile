# Prototype — Container Transform : Matière → Détail Matière

Premier geste de la direction artistique V2. Périmètre strictement limité à
`Hub Apprendre → tuile Matière → écran Détail Matière → retour`.

## Architecture retenue
- **`OpenContainer`** (package `animations`, déjà présent) : la tuile
  (`_SubjectTileVisual`) est le `closedBuilder` ; `SubjectDetailScreen` est le
  `openBuilder`.
- **Raison du choix** : OpenContainer gère nativement le retour **exact** à la
  tuile (collapse), l'absence de flash/écran blanc, l'absence de duplication de
  titre au retour, et la **préservation du scroll** (le hub reste monté
  dessous). C'est une **route impérative** : aucun `redirect` GoRouter n'est
  impliqué → **pas de boucle de routeur**. Un Hero cross-GoRoute aurait été plus
  fragile (retour pixel-exact, flashs). OpenContainer fonctionne avec
  l'architecture existante (IndexedStack de l'accueil + Navigator de GoRouter).
- **Continuité visuelle** : `SubjectDetailScreen` reçoit un `summary`
  (`LearnSubject` déjà connu de la tuile) → l'en-tête immersif (gradient + icône
  + titre) s'affiche **immédiatement** pendant le morph, sans spinner ; les
  chapitres se chargent ensuite (squelette). L'en-tête est factorisé
  (`_SubjectImmersiveSliverAppBar`) et partagé par l'écran chargé et l'état de
  chargement → pas de saut entre les deux.

## Transition aller
Morph 400 ms (`emphasizedDecelerate` interne d'OpenContainer), `fadeThrough` :
0–60 % expansion de la tuile (gradient/icône/titre continus), 60–100 % l'en-tête
se stabilise et les chapitres apparaissent (entrée existante `fadeIn/slideX`).

## Transition retour
Animation inverse : collapse exact vers la tuile d'origine. Déclenché par le
bouton retour du `SliverAppBar` ou le retour système. Aucun flash, aucun écran
blanc, aucune duplication de titre.

## Position de scroll
Préservée : le hub n'est pas démonté pendant l'ouverture du détail (test
automatisé vérifie l'offset avant/après aller-retour).

## Reduced motion
Pas de morph : push `FadeTransition` 200 ms vers la **même** destination
(`SubjectDetailScreen`). Navigation et retour identiques.

## Accessibilité
Tuile en `Semantics(button: true)` + libellé (titre, % complété, nb de leçons) ;
feedback **pressed** + haptique via `IntelliaPressable` ; cible ≥ 48 dp
(tuiles 160 px de haut). Progression non transmise par la seule couleur (texte
%). Testé aux facteurs de texte 1.0 / 1.3 / 1.5.

## Tests
`test/features/learn/subject_container_transform_test.dart` — 18 cas (tuiles,
tap, ouverture, titre/icône conservés, retour hub, aucune exception, reduced
motion, texte 1.3/1.5, écrans 320/360/390/430, scroll conservé, double tap →
une seule nav, retour Android pendant l'animation, navigation cohérente).
`takeException() == null` partout.

## Résultats de validation
- `git diff --check` : propre.
- `dart format --set-exit-if-changed lib test` : propre.
- `flutter analyze` : **No issues found**.
- `flutter test` (suite complète) : **96 tests passés**.
- `dart run tool/check_brand_references.dart` : passé.
- `flutter build apk --debug --flavor staging` : **non exécutable dans
  l'environnement d'intégration** (sandbox : démon Gradle « loopback »). Le
  flavor est correct (`assembleStagingDebug`). À builder sur la machine du
  propriétaire.

## Performance
**Non mesurée sur appareil / sans profilage** (pas de device disponible ici).
Aucune mesure de 60 fps n'est revendiquée. Garde-fous au niveau du code :
aucun nouveau `BackdropFilter` plein écran, aucun flou animé, aucune particule,
aucune image ajoutée, aucune animation continue après la navigation. Aucun
`RepaintBoundary` ajouté spéculativement. À profiler sur téléphone réel.

## Captures
Non produites (pas d'appareil/émulateur dans l'environnement). À capturer sur
téléphone : avant / pendant l'expansion / détail / GIF aller-retour, **sans
modifier la homepage**.

## Régressions connues
- La navigation tuile→détail n'emprunte plus la route GoRouter
  `/learn/subject/:id` (conservée pour le deep link, inchangée) ; le chemin par
  tuile utilise OpenContainer. À surveiller : si un `redirect` GoRouter survenait
  pendant l'ouverture, la route impérative pourrait être retirée — non observé
  en navigation normale (aucun redirect déclenché).

## Recommandation de généralisation
**NON** — ne pas généraliser à Chapitre, Leçon ou Quiz tant que ce prototype
n'a pas été **validé visuellement et fonctionnellement sur téléphone réel**
(rendu du morph, 60 fps, retour exact, parité de l'en-tête).
