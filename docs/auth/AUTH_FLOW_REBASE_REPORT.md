# Rapport de mise a jour du parcours Auth

Date de validation : 27 juin 2026

## References Git

- Branche : `feature/auth-complete-mobile-flow`
- Commit de depart : `8aa73fca8de207b5699884e3ac2846ef32457905`
- Main cible : `9ab099d7cfb09cf50d5a4aa09dec7892f97fd111`
- Merge PR #7 present sur main : `6859c76b52b31b2b588aef2650c39f1c61fd4e2c`
- Merge PR #8 present sur main : `9ab099d7cfb09cf50d5a4aa09dec7892f97fd111`
- Merge de `origin/main` dans la branche Auth : `409e061`

## Conflits et resolutions

Trois conflits de contenu ont ete rencontres :

- `lib/features/onboarding/domain/onboarding_slides.dart`
- `lib/features/onboarding/presentation/onboarding_screen.dart`
- `lib/features/onboarding/presentation/widgets/onboarding_slide_view.dart`

Les trois conflits ont ete resolus avec les versions de `main`, conformement a
la priorite donnee a l'onboarding Web mobile de la PR #7. Le routeur a fusionne
automatiquement les routes Auth avec la route `/flow` de la PR #8.

## Elements preserves

### PR #7 - Onboarding Web mobile

- scenes, visuels et navigation premium conserves ;
- boutons `Passer` et `Commencer` conserves ;
- premier lancement dirige toujours vers l'onboarding ;
- test widget de la premiere scene conserve et valide.

### PR #8 - Flow

- route `/flow` conservee ;
- module `lib/features/flow/` conserve ;
- carte d'entree Flow sur l'accueil eleve conservee ;
- controleur, progression locale de demonstration et tests Flow conserves ;
- acces `/flow` refuse par le routeur aux profils non-eleves.

## Validation du parcours Auth

Le parcours controle est : Splash/Bootstrap, Onboarding, Connexion, choix de
creation de compte, inscriptions Eleve/Parent/Enseignant/Administrateur, puis
redirection vers l'accueil du role.

- Eleve : Firebase Auth puis documents `users` et `student_profiles`.
- Parent : Firebase Auth puis documents `users` et `parent_profiles` ; la
  liaison d'enfant reste optionnelle et peut etre vide.
- Enseignant et administrateur : Firebase Auth puis callable
  `submitStaffRegistration`.
- Staff : statut initial `pending_validation`.
- Administrateur : permissions initiales sensibles toutes a `false`.
- Firestore Rules : les comptes staff en attente n'obtiennent aucun droit
  enseignant ou administrateur actif.
- Aucun mock d'authentification, UID de demonstration ou changement de role
  local n'est actif dans le parcours Auth.

La decision de redirection GoRouter a ete isolee dans `resolveAppRedirect` afin
de tester le premier lancement, la redirection post-authentification et la
restriction de Flow sans instancier les ecrans animes.

## Tests et builds

| Controle | Resultat |
| --- | --- |
| `dart format --output=none --set-exit-if-changed .` | Succes apres formatage mecanique de 18 fichiers issus des PR #7/#8 |
| `flutter pub get` | Succes |
| `flutter analyze` | Succes, aucune anomalie |
| `flutter test --no-pub` | Succes, 26 tests |
| `dart run tool/check_brand_references.dart` | Succes |
| APK production debug | Succes : `build/app/outputs/flutter-apk/app-production-debug.apk` |
| APK staging debug | Succes : `build/app/outputs/flutter-apk/app-staging-debug.apk` |
| `npm ci` | Succes ; avertissement Node 22 utilise alors que Node 20 est declare |
| `npm test` | Succes, 21 tests |
| `npm run build` | Succes |
| `npm audit --audit-level=high` | Succes ; 8 vulnerabilites moderees transitives |
| Firestore Rules | Succes, 15 tests |
| Storage Rules | Succes, 8 tests |

Les tests ajoutes couvrent :

- inscription eleve et authentification automatique du role eleve ;
- inscription parent sans liaison d'enfant obligatoire ;
- premier lancement vers l'onboarding ;
- redirection apres authentification ;
- acces Flow reserve au role eleve.

Les tests Functions existants couvrent la creation staff en attente et
l'absence de permissions admin elevees. Les tests Rules couvrent
l'auto-promotion interdite et le blocage des privileges staff en attente.

## Fichiers modifies apres le merge

- `lib/app/router/app_router.dart`
- `test/app/router/app_router_redirect_test.dart`
- `test/features/auth/registration_controllers_test.dart`
- `docs/auth/AUTH_FLOW_REBASE_REPORT.md`
- 15 fichiers de `lib/features/flow/`, `lib/features/onboarding/` et
  `lib/features/student_home/` normalises uniquement par `dart format`
- 3 tests Flow/Onboarding normalises uniquement par `dart format`

## Test Android manuel

Aucun appareil Android physique n'etait connecte. L'AVD
`Pixel_3a_API_34_extension_level_7_x86_64` etait reference, mais son lancement
a echoue car l'image
`C:/AndroidSDK/system-images/android-34/google_apis/x86_64` n'est pas installee.
Le parcours doit donc encore etre valide sur un telephone reel ou un AVD dont
l'image systeme est complete.

## Risques restants

- validation manuelle du parcours complet sur Android reel ;
- confirmation des emails et documents crees dans un projet Firebase de test ;
- migration future vers Built-in Kotlin signalee par Flutter ;
- alignement de l'environnement Functions sur Node 20 ;
- mise a jour controlee des dependances responsables des vulnerabilites npm
  moderees.

## Garanties d'execution

- Aucun deploiement Firebase n'a ete effectue.
- Aucune donnee de production n'a ete lue ou modifiee par un test manuel.
- Gemini et les paiements n'ont pas ete modifies.
- Aucun push direct sur `main` n'a ete effectue.
- La PR #6 n'a pas ete fusionnee.
