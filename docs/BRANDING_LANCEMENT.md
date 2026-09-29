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
  Séquence cinématique (première expérience, **2,5 s**) :
  1. **Atmosphère** 0–420 ms : la lumière vient sur la surface unie, puis
     dérive très lentement. Sur Android, la **matière Higgsfield** la remplace
     (voir plus bas).
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
     invisible traverse le fond (620 ms), au-dessus de la matière.
  5. **Sweep** 1420–1780 ms : une lumière très fine (blanc à 30 %) parcourt
     les seules lettres, par-dessus le PNG intact.
  6. **Respiration** 1780–2100 ms : la marque, immobile.
  7. **Sortie** 2100–2500 ms : le logo avance vers la caméra (×1,035),
     remonte de 6 px et s'efface ; la navigation est libérée au début de la
     sortie, l'écran suivant apparaît derrière.
- Allures :
  - première expérience (onboarding jamais vu, aucune session) : séquence
    complète, 2,5 s (+ 150 ms au plus de décodage du logo) ;
  - retour (onboarding vu ou session restaurable) : apparition 380 ms
    (échelle 0,965 → 1, légère inclinaison), lock, sortie à 620 ms, fin à
    900 ms ; ni fragments, ni vibration, **ni clip** (Flutter seul) ;
  - animations réduites : logo présent (opacité 0,6 → 1 en 240 ms),
    aucun mouvement, **ni clip**, navigation à 450 ms.
- Si l'écran suivant tarde (session lente à résoudre), le logo revient au
  lieu d'un écran vide.
- Le logo est affiché tel quel (`Image.asset`, `BoxFit.contain`), dimensionné
  sur sa zone utile : 78 % de la largeur sur téléphone, 520 px au plus.

### Démarrage en parallèle (barrière de navigation)

`completeBootstrap` (restauration de session, profil, cache) ne partait
qu'au début de la sortie du logo : le démarrage attendait la marque. Il part
désormais **à la première image**, en parallèle de la séquence.

- `LaunchGate` (`lib/features/bootstrap/application/launch_gate.dart`) retient
  seulement la *navigation* qui quitte la route de lancement ; le routeur
  (`AppRouterNotifier.redirect`) la réévalue à la libération.
- Session prête avant la sortie : rien n'est ajouté, la navigation part à
  l'instant de la sortie (2,1 s la première fois, 0,62 s au retour).
- Session pas prête : le logo revient (`_waiting`), jamais un écran vide.
- Erreur de démarrage : elle attend la libération, la marque n'est jamais
  coupée par un message ; « Réessayer » relance le démarrage.
- Filet de sécurité : la barrière est fermée par l'écran de lancement lui-même
  et libérée au plus tard 2 s après la durée de la séquence, ou à sa
  disparition.

### INTELLIA AWAKENS — la matière Higgsfield (première expérience, Android)

Higgsfield ne fournit que la **matière** : verre, réfraction, lumière diffuse.
Le logo (`assets/branding/logo.png`), les fragments, le 2-3-7, le LOCK, le
sweep, la vibration et tout texte restent du Flutter. Le clip ne contient ni
logo, ni texte, ni interface.

| | |
|---|---|
| Fichier | `assets/branding/cinematic/splash_awaken_e.mp4` (dossier déclaré dans `pubspec.yaml`) |
| Poids | 357 404 octets (plafond testé : 400 Ko) |
| Format | H.264 High, 540×960, 30 fps, 2,5 s, sans audio, yuv420p, bt709 (plage tv), une image clé toutes les 15 images |
| Provenance | génération Higgsfield V1 (Wan 3.0, 9:16, 3 s), traitée par `tool/branding/derive_awaken_clip.sh` (reproduit le fichier à l'octet près) ; voir `docs/branding/HIGGSFIELD_AWAKENS.md` |
| Plateformes | Android seulement (seul terrain validé sur appareil). Web, Windows, macOS, iOS : le splash actuel, sans clip |

Traitement « E », validé sur TECNO CL6k :

- **cuit dans le clip** (comme en production, rien au runtime) : passe-haut
  (structure fine seulement) sur le dégradé de marque, flou léger ≈ 1,4 px ;
- **en Flutter** (`LaunchMatter`) : voile 45 % (le dégradé de marque), centre
  calme radial 50 %, échelle 1,10, et fondu par un voile de la surface unie
  (aucune couche d'opacité sur la texture vidéo) : entrée 0 → 650 ms, sortie
  1650 → 2100 ms (`LaunchMotion.matterPresence`). À présence 0, la première et
  la dernière image sont celles de Flutter, `#F2F9FC`.

Une décoration, jamais un passage obligé (`LaunchVideo`) :

- **préparé au démarrage** : `bootstrap()` lance `LaunchVideoWarmup.start()` dès
  que l'onboarding n'a pas été vu, pendant l'initialisation de Firebase.
  L'initialisation du lecteur prend 0,5 à 0,9 s à froid : elle ne doit pas
  commencer à l'ouverture de l'écran de lancement ;
- **Flutter est l'horloge maître** : la séquence démarre après ≤ 150 ms de
  décodage du logo, sans jamais attendre le clip ;
- **synchronisation** : clip prêt à l'heure → il démarre à 0, sans recalage ni
  avance ; clip prêt en retard (≤ 900 ms) → recalé à *maintenant + 130 ms*
  (`LaunchMotion.videoSeekCost`, le coût d'un `seekTo`) et il entre par un
  fondu de plus ;
- **repli** : clip absent, en erreur, initialisation > 6 s, ou pas lancé à
  900 ms → le splash actuel, à l'identique (l'atmosphère revient en fondu de
  300 ms si la matière était attendue) ;
- **libération** : le lecteur est libéré à la fin de la séquence, au démontage
  et en cas d'échec ; jamais de double initialisation.

Mesures sur appareil (TECNO CL6k, MediaTek Helio G99, Android 15 / API 35, build
profile du flavor staging, vrai `BootstrapScreen` sans Firebase, 11 lancements
à froid dont 4 témoins sans clip) :

| | Avant correction | Après |
|---|---|---|
| Dérive clip − Flutter à 1300 ms, clip prêt à l'heure | +7 / +12 ms (mais +67 ms avec une avance de 130 ms) | **+5 à +13 ms** (6 mesures) |
| Dérive, clip prêt en retard et recalé | −141 ms (−129 ms au rejeu du preview) | **−19 / +14 / +16 ms** |

- initialisation du clip à froid, sans aucune avance Firebase (pire cas) :
  540 à 858 ms (médiane 654) ; clip lancé à 517–818 ms de la séquence, donc
  dans la fenêtre de 900 ms 7 fois sur 7 ; clip déjà prêt : 136–261 ms ;
- passages avec clip déjà prêt : aucune image > 33 ms, pire image 12 à 20 ms ;
- passage à froid : 1 à 3 images > 33 ms, dont des rendus de première image
  dans les 150 premières ms (63 à 105 ms) qu'on retrouve **aussi sans clip** ;
  aucun pic à l'arrivée du clip ; mémoire du processus : 275–290 → 343–371 Mo
  avec ou sans clip, stable sur trois passages (aucune fuite constatée).

### INTELLIA AWAKENS — la traversée Authentification → Home (Android)

Même univers que le lancement : Higgsfield ne fournit que la **matière** (une
traversée d'un espace de savoir abstrait : courbes, orbites, cellule, points de
données, glyphes illisibles, qui s'éclaircit). Le PASS, le prénom, la classe et
le Home sont le vrai Flutter, au-dessus ; le clip ne contient ni logo, ni
texte, ni bouton, ni interface.

| | |
|---|---|
| Fichier | `assets/branding/cinematic/auth_home_matter.mp4` |
| Poids | 239 410 octets (plafond testé : 300 Ko) |
| Format | H.264 High, 480×854, 30 fps, 0,8 s (24 images), sans audio, bt709 (plage tv), dernière image = crème `#FBF8F1` du Home |
| Provenance | génération Higgsfield (Wan 3.0, 480p, 9:16, 2 s, 2,0 crédit), traitée par `tool/branding/derive_auth_home_clip.sh` |
| Plateformes | Android seulement ; ailleurs, la transition native |

Tempo (`AuthHomeMotion`, durée de la route 820 ms, Flutter est l'horloge
maître) :

- 0 → 110 ms : la matière naît sur l'écran d'accès ;
- 300 → 760 ms : le vrai PASS et le vrai Home émergent de la clarté (même
  courbe `easeOutCubic` que la transition native) ; retour haptique léger
  (`selectionClick`) une seule fois quand ils se stabilisent ;
- la dernière image du clip est la surface du Home : elle disparaît dessous ;
  le clip est alors libéré.

Une décoration, jamais un passage obligé :

- **préparé pendant l'accès** : chaque écran d'accès (`AuthExperienceScaffold`)
  lance `AuthHomeVideoWarmup.start()`, le lecteur est initialisé bien avant la
  validation (1,7 s à froid sur TECNO CL6k) ;
- **décidé une fois** : `AppRouterNotifier.homeArrivalCinematic` n'est vrai que
  si le clip est prêt à l'instant où la page d'arrivée est bâtie ; une session
  restaurée au démarrage (aucun écran d'accès) garde son arrivée immédiate ;
- **jamais attendu** : clip en préparation, en erreur, absent, ou pas lancé à
  140 ms → la transition native, courte (360 ms) ; la navigation ne dépend
  jamais du clip ;
- **entrées absorbées** pendant la traversée (appuis et retour système) : pas
  de double navigation, pas de tap sur un Home encore invisible ;
- **mouvement réduit** : aucun clip préparé ni joué, le Home est posé tel quel ;
- un seul lecteur, adopté une fois (`AuthHomeVideoWarmup.take()`), libéré à la
  fin, au démontage ou en cas d'échec.

Tests : `test/features/auth/auth_home_cinematic_test.dart` (tempo, préparation,
clip prêt / absent / en erreur / lent / tardif, entrées, haptique, mouvement
réduit) et `test/features/auth/auth_home_journey_test.dart` (vrais écrans, vrai
routeur, vraies pages).

**À vérifier sur téléphone** : la fluidité de la lecture pendant l'émergence du
Home (accueil réel, pas un accueil simulé) et le raccord de la dernière image.

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
