# Lancement et icônes — identité INTELLIA237 (28/09/2026)

## Sources officielles (jamais modifiées)

| Fichier | Rôle |
|---|---|
| `assets/branding/logo.png` | wordmark officiel, fond transparent (512 × 512, wordmark de x 25 à 491, y 202 à 300) : héros du lancement |
| `assets/branding/icone.png` | icône officielle, opaque (512 × 512) : exactement `logo.png` posé sur un dégradé horizontal `#CDFFD8` → `#B0DCEB` → `#94B9FF` (écart ≤ 2/255) |

## Lancement

```
splash natif (couleur unie #F2F9FC ; Android 12+ : icône de l'application au centre)
  → première image Flutter : la même surface unie
  → séquence de marque (BootstrapScreen)
  → onboarding, porte d'accès ou espace
```

- Palette : `BrandLaunchPalette` (`lib/features/bootstrap/presentation/widgets/`).
  Surface `#F2F9FC` (médian de l'icône à 16 %), brume mint `#F6FFF8`,
  brume pervenche `#E7F0FF`, dégradé diagonal dont le centre est la surface.
  Barres système transparentes / surface, icônes sombres.
- Rythme : `LaunchMotion`, fonctions pures du temps (aperçus et tests).
  1. respiration 0–260 ms : la lumière vient sur la surface unie ;
  2. apparition 120–720 ms : opacité, échelle 0,955 → 1, flou 3 → 0 ;
  3. révélation 120–840 ms de gauche à droite (masque d'opacité seul), reflet
     640–1060 ms qui ne touche que les lettres ;
  4. signature 1060–1240 ms : une respiration à peine, une vibration légère
     (`selectionClick`) au premier lancement ;
  5. sortie 300 ms (échelle 0,97, remontée de 8 px, fondu) pendant que
     l'écran suivant apparaît.
- Allures :
  - premier lancement : séquence complète, navigation lancée à 1,24 s
    (+ le temps de décodage du logo, 150 ms au plus) ;
  - session restaurable : l'espace s'ouvre aussitôt ; le logo se pose en
    360 ms s'il en a le temps ;
  - animations réduites : logo immobile, 450 ms au premier lancement,
    immédiat avec une session restaurable.
- Le logo est affiché tel quel (`Image.asset`, `BoxFit.contain`), dimensionné
  sur sa zone utile : 78 % de la largeur, 460 px au plus.

## Icônes

- Android (hérité, API < 26) et iOS : `icone.png`, générées par
  `flutter_launcher_icons`.
- Icône adaptative (API 26+) : deux dérivées techniques produites par
  `tool/branding/derive_launcher_assets.py` (recadrage, échelle, marges) :
  - premier plan : le wordmark de `logo.png`, inscrit dans le cercle de 66 dp
    garanti sous tous les masques ;
  - fond : le dégradé de `icone.png` sur les 72 dp visibles, bords prolongés.
- Notification : `@drawable/ic_stat_intellia`, silhouette blanche du wordmark
  (Android ne garde que l'alpha de la petite icône), teinte `#0B2E4A`.

## Régénérer

```
python tool/branding/derive_launcher_assets.py
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

`flutter_native_splash` a `web: false` : le web garde sa propre page de
chargement (`web/index.html`), encore à l'ancienne couleur `#F4EFE5`.

## Limites connues

- `icone.png` fait 512 px : l'icône App Store iOS (1024 px) est un
  agrandissement. Une source 1024 px l'affinerait.
- La silhouette de notification est un wordmark très horizontal : à 24 dp
  dans la barre d'état, elle reste fine.
- ANDROID PHYSIQUE À VÉRIFIER : splash système, continuité natif → Flutter,
  vibration, icône réelle sous le masque du lanceur, icône de notification.
