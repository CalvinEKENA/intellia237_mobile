# Student tab layering fix

Date: 2026-06-28  
Branch: `feature/learn-subject-container-transform`  
PR: #10 - `feat: unify student tab visuals and subject transitions`

## Cause

`_AnimatedTabStack` plaçait les cinq onglets dans un `Stack` avec un
`Positioned.fill` par onglet. `_FadeTab` appliquait ensuite un
`AnimatedOpacity` et un `AnimatedScale` pendant 240 ms. L'onglet sortant et
l'onglet entrant étaient donc peints simultanément. `IgnorePointer` bloquait
les taps, et `TickerMode` les animations, mais aucun des deux ne retirait
l'ancien onglet du rendu.

L'audit des racines Accueil, Apprendre, Quiz, Compagnon et Profil n'a pas
identifié de deuxième pile globale responsable de la superposition. Les
`Scaffold` et `BackdropFilter` restants dans Apprendre et Compagnon
appartiennent uniquement à leur mode standalone ou à des composants internes;
le mode embedded conserve les surfaces claires opaques introduites par la
PR #10.

## Architecture finale

- `_AnimatedTabStack`: supprimé.
- `_FadeTab`: supprimé.
- Navigation: `IndexedStack` avec un seul index actif.
- Nombre maximal d'onglets peints par frame: 1.
- Les cinq onglets restent montés pour conserver leurs états.
- Onglet caché: `TickerMode(enabled: false)`.
- Onglet caché: `ExcludeSemantics(excluding: true)`.
- Onglet caché: `FocusScope` non focalisable et exclu du parcours clavier.
- Onglet caché: `IgnorePointer(ignoring: true)`.
- Changement d'onglet: le champ actif est explicitement défocalisé.
- Animation globale: aucune. Aucune micro-animation n'a été ajoutée dans ce
  correctif afin de ne pas réintroduire un rendu plein écran concurrent.

Le contrat `TabSurface` / `TabPalette`, les modes `embeddedLight` et
`standaloneDark`, le contraste des onglets et le Container Transform des
matières sont conservés.

## Tests ajoutés

- exclusivité visuelle des cinq marqueurs racines;
- cinq sous-arbres toujours montés avec `skipOffstage: false`;
- état de `TickerMode`, sémantique, focus et hit testing par onglet;
- contrôle à 120 ms, ancien point médian de la transition;
- taps rapides à 20, 50 et 100 ms;
- taps répétés sur l'onglet courant;
- absence des render objects cachés dans le chemin de hit test;
- conservation de la recherche et du scroll Apprendre;
- conservation du brouillon Compagnon;
- navbar toujours interactive et retour Android vers Accueil.

## Validations

- `git diff --check`: succès.
- `dart format --output=none --set-exit-if-changed .`: succès, 240 fichiers,
  aucun changement.
- `flutter analyze --no-pub`: succès, aucune anomalie.
- `flutter test --no-pub`: succès, 122 tests.
- `flutter test --no-pub test/features/student_home/ test/features/learn/`:
  succès, 44 tests.
- Suites dédiées `test/features/quiz/` et `test/features/ai_companion/`:
  absentes du dépôt; leurs surfaces embedded sont exercées par la suite
  `student_home`.
- `dart run tool/check_brand_references.dart`: succès.
- Build staging debug: succès.

APK:

- chemin: `build/app/outputs/flutter-apk/app-staging-debug.apk`;
- taille: 197821150 octets;
- SHA256: `97BBD93473E2A68303977AF4F91F80242EF774E7331131D52C63053C5E401865`.

## Validation visuelle

Aucun téléphone Android n'était connecté. L'émulateur disponible n'a pas pu
démarrer car son chemin système AVD est invalide (`ANDROID_SDK_ROOT` pointe
vers `C:\AndroidSDK`). Aucune vidéo ni capture des cinq onglets n'est donc
présentée comme validation réelle.

La fusion n'est pas recommandée avant confirmation sur téléphone que les cinq
onglets restent exclusifs, lisibles et interactifs, que la navbar fonctionne,
et que recherche, scroll et chat conservent leur état.
