# Validation finale sur téléphone — INTELLIA237

Branche : `feature/auth-complete-mobile-flow` · PR #6 (à ne PAS fusionner avant validation device)

Ce document trace l'état des problèmes observés sur téléphone et la checklist
de validation finale. **La mission Firebase n'est PAS validée par un build
APK, un test mock, `flutter analyze` ou une CI verte** : elle exige une
création de compte réelle sur appareil.

## A — Lisibilité Classe / Série
- **Bug** : sur l'étape Classe, les choix non sélectionnés apparaissaient en
  blocs blancs avec texte blanc (illisibles). Cause : `_SelectionPill` reposait
  sur un `ChoiceChip` dont le fond/texte pouvaient être écrasés par le
  `ChipTheme` global.
- **Correctif** : nouveau composant contrôlé `AuthSelectionPill`, indépendant du
  thème (couleurs littérales). Non sélectionné : fond blanc 6 %, bordure 14 %,
  texte blanc 90 %, hauteur min 52, rayon 16. Sélectionné : gradient
  indigo→violet, texte blanc, coche, halo, haptique.
- **Tests** : `auth_selection_pill_test.dart` (couleurs, contraste, sélection,
  changement de série, aucune option vide). ✅
- **À confirmer sur téléphone** : lisibilité des 7 classes (6e→Tle) et des
  séries (A/C/D) en staging, thème clair/sombre, grand texte.

## B — Découverte cinématique Kira / Léo
- **Bug** : Kira et Léo affichés ensemble.
- **Correctif** : `CompanionDiscovery` — `PageView` une scène à la fois, révélation
  (fondu + flou→net + tracking resserré), flèche animée « Découvrir Léo »,
  transition halo violet→bleu-indigo, retour possible, sélection après
  découverte, CTA « Continuer » actif seulement après choix. Un contrôleur par
  scène, libéré ; pause en arrière-plan ; reduced-motion ; images précachées.
- **Tests** : `student_registration_experience_test.dart` (Kira seule au départ,
  Léo révélé via la flèche, assets officiels uniquement, tailles 320→430). ✅
- **À confirmer sur téléphone** : fluidité 60 fps, petites hauteurs d'écran.

## C — Inscription Firebase (staging)
- **Cause connue** : Firebase Authentication non initialisé ou Email/Mot de
  passe non activé dans `intellia237-staging` → erreur `configuration-not-found`
  → message « Le service d'inscription est momentanément indisponible. »
- **Côté code (fait)** : diagnostics `AUTH-CONFIG-001` copiables en staging +
  log non sensible (env, projectId, appId tronqué, étape, code). Aucun secret
  journalisé.
- **Action propriétaire (requise)** : activer dans la console Firebase
  `intellia237-staging` → Authentication → Sign-in method → **Email/Password**.
- **Statut** : ⏳ en attente d'activation console + test device.

### Vérifications runtime à effectuer après activation
- [ ] `Firebase.app().options.projectId == intellia237-staging`
- [ ] package Android `com.intellia237.app.staging`
- [ ] `createUserWithEmailAndPassword()` atteint le bon projet
- [ ] compte visible dans Authentication → Utilisateurs
- [ ] `users/{uid}` créé
- [ ] profil Élève créé, rôle `student`
- [ ] classe + série correctes
- [ ] compagnon (Kira/Léo) enregistré
- [ ] aucun établissement exigé
- [ ] redirection accueil + Intellia Flow accessible

### Cas d'erreur à tester
création réussie · e-mail déjà utilisé · mot de passe faible · e-mail invalide ·
absence réseau · permission Firestore refusée · profil partiel · réessai.

## D — Splash
- **Bug** : frame blanche au démarrage ; bootstrap ≠ splash Web.
- **Correctif** : splash natif (#FAFAFD + logo officiel) + splash Flutter fidèle
  au Web (voir `docs/design/WEB_SPLASH_TO_FLUTTER_REPORT.md`).
- **Tests** : `bootstrap_splash_test.dart` (fond non blanc, logo officiel, pas
  d'ancien logo). ✅
- **À confirmer sur téléphone** : cold start après désinstallation, aucune frame
  blanche, pas de saut logo/couleur.

## Procédure de test device
```
flutter build apk --debug --flavor staging -t lib/main_staging.dart
# installer l'APK staging sur le téléphone du propriétaire
```
Créer un compte avec une **nouvelle** adresse e-mail, puis cocher la checklist C.

> ⚠️ Build APK non exécutable dans l'environnement d'intégration actuel
> (sandbox : démon Gradle « Unable to establish loopback connection »).
> À builder sur une machine standard.

## Recommandation de fusion
**À NE PAS fusionner** tant que : l'inscription réelle n'a pas réussi · les
classes ne sont pas confirmées lisibles sur device · Kira/Léo confirmés séparés ·
le splash validé sur téléphone · aucune frame blanche.

## Captures téléphone
_(à insérer après test device : étape Classe, scènes Kira & Léo, splash cold start, compte Firebase)_
