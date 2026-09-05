# INTELLIA237 Mobile

Application mobile Flutter/Firebase pour INTELLIA237.

Le depot contient l'application Flutter, les Cloud Functions Firebase, les regles Firestore/Storage, les tests de securite et la documentation technique de rebranding. Le backend actif est Firebase Functions et les usages IA (quiz, resumes, tuteur) passent cote serveur par Vertex AI avec `gemini-3.8-flash`. Aucune cle Gemini n'est embarquee dans Flutter.

## Environnements

| Environnement | Nom visible | Android applicationId | iOS bundle ID | Firebase project |
| --- | --- | --- | --- | --- |
| production | INTELLIA237 | `com.edunova.app` | `com.edunova.app` | `edunova-aabd1` |
| staging | INTELLIA237 Staging | `com.intellia237.app.staging` | `com.intellia237.app.staging` | `intellia237-staging` |

Les identifiants Android/iOS production restent volontairement en `com.edunova.app` pour conserver la continuite stores. Le projet Firebase production reste `edunova-aabd1`.

Le staging Android utilise le client Firebase `intellia237-staging` installe dans `android/app/src/staging/google-services.json`. Ne remplacez pas `android/app/google-services.json`, qui reste la configuration production.

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
flutter build apk --debug --flavor staging -t lib/main_staging.dart
```

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

## IA - Gemini 3.8 Flash sur Vertex AI

Le client LLM appelle l'API Vertex AI `generateContent` avec le modele `gemini-3.8-flash`, vérifié dans le projet de production avant activation.

- authentification : Application Default Credentials (ADC) du runtime Cloud Functions ;
- projet : `VERTEX_AI_PROJECT_ID`, avec repli automatique sur `GOOGLE_CLOUD_PROJECT` puis `GCLOUD_PROJECT` ;
- emplacement : `VERTEX_AI_LOCATION=global` par defaut ;
- tuteur interactif : `GEMINI_TUTOR_THINKING_LEVEL=LOW` pour limiter latence et cout ;
- quiz/resumes structures : `GEMINI_STRUCTURED_THINKING_LEVEL=MEDIUM` pour privilegier la qualite ;
- aucune cle API Gemini ne doit etre ajoutee au client Flutter ou au depot ;
- en local hors Google Cloud, utiliser ADC (`gcloud auth application-default login`) plutot qu une cle JSON versionnee.

Prerequis de deploiement : activer l'API Vertex AI dans chaque projet Firebase cible et verifier que le compte de service d'execution des Functions peut appeler Vertex AI. En production, le projet cible est `edunova-aabd1`; en staging, conserver l'auto-detection du projet afin d'eviter tout appel croise vers la production. A terme, remplacer les roles IAM trop larges par des roles minimaux tels que `roles/aiplatform.user`.

## Regles Firebase

- `firestore.rules` protège les rôles sensibles, les tentatives de quiz, les points et la progression.
- `storage.rules` limite les avatars utilisateurs.
- Les tests de regles tournent avec les emulateurs Firebase depuis `functions`.

## Rebranding

Les assets officiels copies depuis la reference web locale sont dans:

- `assets/branding/`
- `assets/companions/`

Les assets legacy pre-rebranding non references par l'UI active restent documentes dans `docs/rebranding/`. La regeneration complete des icones lanceur et splash doit etre faite dans une passe dediee, avec assets officiels valides et verification native.

## Exclusions

- Aucun deploiement Firebase automatique depuis ce changement.
- Aucun changement des identifiants stores production.
- Aucun secret IA dans le client mobile ou le depot.
- Aucune modification de donnees de production.
