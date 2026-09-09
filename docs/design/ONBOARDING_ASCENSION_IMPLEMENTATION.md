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
- `presentation/widgets/campaign/campaign_signature.dart` : empreinte gravée,
  lecture au maintien du pouce et reconnaissance.
- `core/animations/screen_shatter.dart` : capture, tremblement et éclats,
  peints au-dessus du navigateur par `ScreenShatterLayer`.
- `presentation/widgets/campaign/campaign_scenes.dart` : compositions et personnages.
- `presentation/widgets/campaign/campaign_challenge.dart` : interaction pédagogique.
- `presentation/widgets/campaign/campaign_design.dart` : typographie, boutons,
  révélations et adaptation aux écrans courts et au texte agrandi.

## Signature et passage à l’inscription

La dernière séquence ne se termine pas par un bouton. À sa place, le pass porte
un espace de signature : une empreinte gravée en traits fins, un cadre mat, et
une invitation qui respire — « Maintiens ton pouce pour signer. »

1. **Au repos.** Les crêtes de l’empreinte et le message pulsent lentement.
   Rien ne brille, rien ne clignote sèchement.
2. **Pendant la lecture (1 150 ms).** Les crêtes s’encrent du bas vers le haut,
   avec un filet de laiton à la limite, et le cadre du pavé se trace dans le
   sens des aiguilles : le pouce cache le centre, la progression reste donc
   lisible sur les bords. Un doigt levé trop tôt fait refluer l’encre et le
   message devient « Reste appuyé jusqu’au bout. »
3. **Reconnaissance (320 ms).** L’empreinte passe en violet plein, le cadre se
   ferme, et le pass affiche « C’est toi. »
4. **Rupture (980 ms).** L’écran est capturé tel quel, la route est échangée
   dessous, et la capture se brise au-dessus de l’inscription : la surface
   tremble d’abord, puis se disloque en éclats qui partent du pouce vers les
   bords, tournent, s’éloignent et s’effacent. L’inscription apparaît dans les
   trous, jamais par une coupe.

Les éclats survivent à la route dont ils viennent : `ScreenShatterLayer`
enveloppe l’application au-dessus du navigateur, donc l’écran visible entre les
morceaux est déjà le suivant. La route d’onboarding sort en durée nulle, pour
que ses pixels ne soient jamais dessinés deux fois, et `/register` peint son
fond dès la première image.

Rien ne peut être touché pendant la rupture. La préférence `has_seen_onboarding`
et la télémétrie partent au moment de la signature, pas à la fin de l’animation.
Une capture qui échoue ne bloque personne : la remise redevient une simple
navigation. En mouvement réduit, la lecture dure 420 ms et l’écran ne se brise
pas. Le pavé est un bouton pour les technologies d’assistance et pour le
clavier : une seule activation signe, sans maintien.

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
  17 tests, tous réussis (navigation, réponses, état au retour, swipe, inscription,
  préférence persistée, anglais, réduction du mouvement, écrans courts et texte
  agrandi, chorégraphie de la signature et de la rupture, doigt levé trop tôt,
  remise à l’inscription, activation par technologie d’assistance).
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
