# INTELLIA237 Mobile

Application mobile Flutter/Firebase pour INTELLIA237.

Le depot contient l'application Flutter, les Cloud Functions Firebase, les regles Firestore/Storage, les tests de securite et la documentation technique de rebranding. Le backend actif est Firebase Functions avec un client LLM compatible GLM/Z.ai. Aucun microservice `llm-service/` n'est actuellement suivi dans ce depot.

## Environnements

| Environnement | Nom visible | Android applicationId | iOS bundle ID | Firebase project |
| --- | --- | --- | --- | --- |
| production | INTELLIA237 | `com.edunova.app` | `com.edunova.app` | `edunova-aabd1` |
| staging | INTELLIA237 Staging | `com.intellia237.app.staging` | `com.intellia237.app.staging` | `intellia237-staging` |

Les identifiants Android/iOS production restent volontairement en `com.edunova.app` pour conserver la continuite stores. Le projet Firebase production reste `edunova-aabd1`.

Le staging est prepare dans le code et dans `.firebaserc`, mais les fichiers client Firebase staging ne sont pas generes dans ce depot. Ne lancez pas `flutterfire configure` et ne creez pas de faux fichiers Firebase.

## Commandes Flutter

```powershell
flutter pub get
flutter run --flavor production -t lib/main_production.dart
flutter run --flavor staging -t lib/main_staging.dart
```

Le point d'entree `lib/main.dart` reste un alias production.

## Validations Flutter

```powershell
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug --flavor production -t lib/main_production.dart
```

Le build staging Android peut echouer tant que le client Firebase `com.intellia237.app.staging` n'est pas present dans un vrai `google-services.json` staging. C'est intentionnel pour eviter d'utiliser accidentellement la configuration production.

## Cloud Functions

```powershell
cd functions
npm ci
npm test
npm run build
npm audit --audit-level=high
npm run test:rules
```

La CI bloque uniquement les vulnerabilites npm hautes ou critiques via `npm audit --audit-level=high`.

## Regles Firebase

- `firestore.rules` protege les roles sensibles, les tentatives de quiz, les XP et la progression.
- `storage.rules` limite les avatars utilisateurs.
- Les tests de regles tournent avec les emulateurs Firebase depuis `functions`.

## Rebranding

Les assets officiels copies depuis la reference web locale sont dans:

- `assets/branding/`
- `assets/companions/`

Les assets legacy pre-rebranding non references par l'UI active restent documentes dans `docs/rebranding/`. La regeneration complete des icones lanceur et splash doit etre faite dans une passe dediee, avec assets officiels valides et verification native.

## Exclusions

- Aucun deploiement Firebase.
- Aucun changement des identifiants stores production.
- Aucun appel Gemini ou changement de fournisseur LLM.
- Aucun paiement.
- Aucune modification de donnees de production.
