# Onboarding — L’Ascension

Le premier lancement présente cinq séquences interactives, avec une direction
publicitaire : grands titres condensés, surfaces mates et architecture en perspective.

1. **Tu peux comprendre.** Ouverture typographique, Kira et Léo en pied, premier pas.
2. **Commence ici.** Quatre affiches de matières. L’affiche sélectionnée s’agrandit
   depuis sa position réelle pour ouvrir le défi.
3. **Ça prend sens.** Défi propre à la matière, explication après chaque réponse,
   suite numérique transformée en marches. Aucune pénalité visuelle en cas d’erreur.
4. **Avance à ta façon.** Choix de Kira ou Léo par toucher ou glissement horizontal.
   Les aplats, les noms et les personnages suivent le mouvement.
5. **La suite t’appartient.** Recul et déplacement du cadrage architectural, puis
   carte INTELLIA PASS avec matière et compagnon choisis, et accès à l’inscription.

## Implémentation

- `lib/features/onboarding/presentation/onboarding_screen.dart` : navigation,
  contrôleurs de caméra/révélation, transition de l’affiche, cycle de vie, inscription.
- `presentation/widgets/campaign/ascension_architecture.dart` : décor natif
  `CustomPainter`, neuf marches, portique et surfaces en perspective. Aucun halo.
  Expose aussi la géométrie du passage (`ascensionPassageQuad`), calculée avec
  la caméra qui dessine le décor.
- `presentation/widgets/campaign/ascension_passage.dart` : chorégraphie et
  ouverture de la porte vers l’inscription.
- `presentation/widgets/campaign/campaign_scenes.dart` : compositions et personnages.
- `presentation/widgets/campaign/campaign_challenge.dart` : interaction pédagogique.
- `presentation/widgets/campaign/campaign_design.dart` : typographie, boutons,
  révélations et adaptation aux écrans courts et au texte agrandi.

## Passage vers l’inscription

La dernière séquence ne coupe pas vers l’inscription : le portique gravi pendant
tout le parcours s’ouvre, et l’écran suivant est déjà derrière.

1. **0 → 294 ms.** L’interface part immédiatement : elle grandit depuis le
   portique, passe devant la caméra et s’efface. Le mouvement précède le
   fondu, sinon le départ se lirait comme une surimpression.
2. **154 → 602 ms.** L’ouverture part du panneau en creux du portique — un
   quadrilatère en perspective, pas un rectangle — et se redresse jusqu’au
   cadre. Elle est remplie par `AuthAmbientBackground`, la surface même que
   peint l’inscription, et bordée d’un filet de laiton qui s’efface en
   s’élargissant.
3. **602 ms.** Le fond de l’inscription couvre l’écran : les barres système
   prennent le ton clair de cette page avant que la route ne change.
4. **700 ms.** La route est échangée sous cette surface commune. `/register`
   peint son fond dès la première image (`transitionBackground`), donc rien ne
   clignote entre les deux écrans ; seul le contenu monte en place.

Le passage est purement décoratif : il ne peut ni être touché, ni lu par un
lecteur d’écran, et il n’ouvre aucune seconde navigation si l’action finale est
répétée. La préférence `has_seen_onboarding` et la télémétrie partent à
l’ouverture de la porte, pas à son terme. En mouvement réduit, l’inscription
s’affiche immédiatement, sans passage.

Le parcours avance uniquement sur action. Le retour conserve matière, résultat du
défi et compagnon ; choisir une autre matière réinitialise le résultat. Aucun accès
« Passer » n’est introduit. La fin conserve le comportement existant : préférence
`has_seen_onboarding`, télémétrie de fin et navigation vers l’inscription.

Les animations s’arrêtent en arrière-plan. Le mode mouvement réduit affiche les
états immédiatement, avec les mêmes interactions. La copie est disponible en
français et en anglais. Les éléments essentiels restent accessibles par sémantique.

Les anciens sept écrans et leurs anciens visuels inutilisés ont été retirés.
Les images officielles de Kira et Léo sont réutilisées ; l’affiche lumineuse de
l’ancien final n’est plus affichée.

## Typographie

Barlow Condensed ExtraBold/Black pour les grands titres, Manrope pour la lecture.
Les polices sont embarquées, sans téléchargement au lancement. Barlow Condensed
provient du [dépôt officiel Google Fonts](https://github.com/google/fonts/tree/main/ofl/barlowcondensed)
et sa licence SIL OFL est fournie dans `assets/fonts/OFL-BarlowCondensed.txt`.

## Vérification

- `flutter analyze --no-pub` : aucune erreur.
- `flutter test test/features/onboarding/onboarding_screen_test.dart --no-pub` :
  15 tests, tous réussis (navigation, réponses, état au retour, swipe, inscription,
  préférence persistée, anglais, réduction du mouvement, écrans courts et texte
  agrandi, géométrie et chorégraphie du passage, remise à l’inscription).
- Formats couverts par les tests : 320 × 568, 844 × 390 et 390 × 844, jusqu’à 1,6×.
- Revue visuelle dans le navigateur Flutter, avec contrôle des cinq séquences à
  390 × 844 et vérification du cadrage large.
- Pas de mesure de fluidité sur un appareil Android ou iOS physique.

## Aperçu indépendant

```powershell
flutter run -d chrome -t tool/onboarding_preview.dart
```

Cet aperçu utilise les vrais widgets de l’onboarding, sans initialisation Firebase.
Le bouton final mène à un écran de contrôle local ; il ne crée aucun compte.
L’application principale conserve son véritable parcours d’inscription.
