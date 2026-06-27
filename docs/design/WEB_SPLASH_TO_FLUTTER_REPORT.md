# Splash Web → Mobile — Rapport d'analyse et d'implémentation

Branche : `feature/auth-complete-mobile-flow` · PR #6

## 1. Source de vérité analysée (Web App)

- `intellia237/src/app/(public)/splash/page.tsx`
- `intellia237/src/components/splash/LogoAnimated.tsx`
- `intellia237/src/components/splash/ParticleField.tsx`

### Composition Web relevée
| Élément | Détail |
|---|---|
| Fond | `radial-gradient(ellipse at center, #FAFAFD 0%, #F5F5F7 45%, #EDEDEF 100%)` sur blanc |
| Particules | `ParticleField` orbital, 22 particules, rayon max 42 % |
| Logo | Mot-marque « INTELLIA237 », `font-display` extrabold, 48→64px, lettres une à une (stagger 45 ms, y+16, scale 0.85→1) |
| Couleurs logo | « INTELLIA » indigo `#5856D6` ; « 237 » = vert/rouge/jaune (drapeau Cameroun) |
| Glow | `radial-gradient(circle, rgba(88,86,214,0.35), rgba(175,82,222,0.2) 40%, transparent 70%)`, blur 3xl |
| Tagline | « Apprends avec quelqu'un qui te comprend. » (spring, après les lettres) |
| Signature | « by TECH MOTION », micro, uppercase, tracking 0.2em, opacité 0.5 |
| Durée | 2,5 s puis fondu → `/onboarding` |

## 2. Implémentation mobile — deux couches

### Couche A — Splash natif (`flutter_native_splash`)
- `pubspec.yaml` : `color: "#FAFAFD"`, `image: assets/icons/icone_final.png`, idem `android_12`.
- Régénéré via `dart run flutter_native_splash:create` → Android (std + `values-v31`), iOS (`LaunchScreen.storyboard`, `LaunchImage`), Web.
- **But** : premier frame statique cohérent, couleur identique au splash Flutter → aucune frame blanche au cold start.
- Logo officiel `icone_final.png` (jamais l'ancien EduNova).

### Couche B — Splash Flutter (`BootstrapScreen`)
Fichier : `lib/features/bootstrap/presentation/bootstrap_screen.dart`
- `Scaffold.backgroundColor = kSplashBackground (#FAFAFD)` → strictement identique au natif (constante partagée).
- Fond radial `#FAFAFD → #F5F5F7 → #EDEDEF`.
- Logo officiel centré (`Alignment(0,-0.05)`, 104×104) — même position que le natif pour éviter tout saut.
- Mot-marque « INTELLIA237 » lettre par lettre (stagger 45 ms, fade + slideY + scale), « 237 » en `cmVert/cmRouge/cmJaune`, police `Manrope` extrabold (préchargée hors-ligne).
- Halo indigo→violet, particules orbitales discrètes (1 contrôleur, `RepaintBoundary`).
- Tagline + « by TECH MOTION ».
- Init en parallèle (précache non bloquant + `completeBootstrap`), **sans délai artificiel**.
- État d'erreur élégant (« Démarrage interrompu » + Réessayer) si l'init critique échoue.
- `reduced-motion` respecté ; routing inchangé (bootstrap → onboarding/login selon `hasSeenOnboarding`).

## 3. Anti-frame-blanche
- Couleur de fond natif == couleur de fond Flutter (`#FAFAFD`).
- Logo identique (`icone_final.png`) et centré sur les deux couches.
- Premier frame Flutter peint immédiatement (pas d'attente bloquante).

## 4. Tests
`test/features/bootstrap/bootstrap_splash_test.dart` :
- fond non blanc (== `kSplashBackground`, ≠ `#FFFFFF`) → aucune frame blanche ;
- logo officiel + tagline + signature présents ;
- aucun ancien logo (EduNova / `logo.png`).

## 5. À valider sur téléphone (non automatisable)
- Cold start après désinstallation complète : aucune frame blanche, pas de saut de couleur ni de taille de logo.
- Parité exacte de la **taille** du logo natif vs Flutter (peut nécessiter un léger ajustement par densité).
- Rendu sur Android 12+ (splash système) et iOS.
