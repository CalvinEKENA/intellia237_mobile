# INTELLIA237 — consignes pour Claude Code

Application éducative Flutter (Cameroun), élèves / parents / enseignants /
direction. Propriétaire : Calvin EKENA. Écrire et répondre **en français**,
sans flatterie ; challenger les demandes comme un CPO.

## Branche de travail
- Branche à jour : `fix/auth-v2-final-rework` (tout le travail récent).
- `main` est en retard : ne pas repartir de `main` sans l'accord du
  propriétaire.
- État détaillé et reste à faire : `docs/HANDOFF_CLOUD_2026-09-24.md`.

## Règles absolues (sauf demande explicite du propriétaire, à chaque fois)
- Aucun `firebase deploy`, aucune modification gcloud / console, aucune
  écriture dans Firestore de production.
- Aucun envoi Google Play, aucun changement de version sans demande.
- Lecture de production autorisée (journaux, Firestore en lecture).
- Ne jamais committer de secret (`android/key.properties`, keystore, clés de
  service). Le dépôt GitHub est **public**.

## Langage à l'écran
- 100 % humain : aucun terme technique (Firebase, API, token, OTP…). Garde-fou
  `dart run tool/user_facing_jargon_audit.dart` (0 attendu).
- Élèves : tutoiement, phrases courtes. Parents et personnel : vouvoiement.
- Textes dans les ARB (`lib/l10n/app_fr.arb`, `app_en.arb`), jamais en dur
  (cliquet `test/l10n/hardcoded_french_audit_test.dart`).

## Contrôles avant tout commit important
```
dart format --output=none --set-exit-if-changed lib test tool
dart run tool/check_brand_references.dart
dart run tool/user_facing_jargon_audit.dart
flutter analyze
flutter test
cd functions && npm test && npm run build
```
Studio : `cd apps/intellia_studio && flutter analyze && flutter test`.

## Constructions
- APK : `flutter build apk --flavor production -t lib/main_production.dart --release`
- AAB : `flutter build appbundle --flavor production -t lib/main_production.dart --release`
  (signature : `android/key.properties`, absent du dépôt, fourni par le
  propriétaire). Prochain `versionCode` Play : **33 ou plus**.
- Web : `flutter build web --release -t lib/main_production.dart --base-href /`
  (voir `docs/web/DEPLOIEMENT_HOSTINGER.md`).

Commits : terminer par la ligne `Co-Authored-By` demandée par l'outil.
