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
  Séquence cinématique (première expérience, ≈ 2,55 s) :
  1. **Atmosphère** 0–420 ms : la lumière vient sur la surface unie, puis
     dérive très lentement (dégradé et lumière diffuse en légère parallaxe,
     cycles de 5 à 8 s).
  2. **Fragments** 280–840 ms : six zones de `logo.png` (I et son accent,
     diagonale du N, pointe du A, courbe du 2, haut du 3, angle du 7)
     découpées par `ClipRect`, arrivent d'une petite distance, logo incliné
     en profondeur et légèrement flou.
  3. **Assemblage** 720–1320 ms : les fragments convergent vers leur place
     exacte, « INTELLIA » se construit de gauche à droite (masque
     d'opacité), puis 2, 3, 7 montent avec 60 ms de décalage. L'inclinaison
     se stabilise, la mise au point devient nette.
  4. **LOCK** à 1320 ms : le PNG seul, entier, échelle exactement 1 ;
     vibration `selectionClick` (la plus subtile) ; une onde presque
     invisible traverse le fond (620 ms).
  5. **Sweep** 1420–1780 ms : une lumière très fine (blanc à 30 %) parcourt
     les seules lettres, par-dessus le PNG intact.
  6. **Respiration** 1780–2150 ms : la marque, immobile.
  7. **Sortie** 2150–2550 ms : le logo avance vers la caméra (×1,035),
     remonte de 6 px et s'efface ; la navigation part au début de la
     sortie, l'écran suivant apparaît derrière.
- Allures :
  - première expérience (onboarding jamais vu, aucune session) : séquence
    complète, navigation à 2,15 s (+ 150 ms au plus de décodage du logo) ;
  - retour (onboarding vu ou session restaurable) : apparition 380 ms
    (échelle 0,965 → 1, légère inclinaison), lock, sortie à 620 ms, fin à
    900 ms ; ni fragments, ni vibration ;
  - animations réduites : logo présent (opacité 0,6 → 1 en 240 ms),
    aucun mouvement, navigation à 450 ms.
- Si l'écran suivant tarde (session lente à résoudre), le logo revient au
  lieu d'un écran vide. `completeBootstrap` n'est appelé qu'une fois.
- Le logo est affiché tel quel (`Image.asset`, `BoxFit.contain`), dimensionné
  sur sa zone utile : 78 % de la largeur sur téléphone, 520 px au plus.

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
