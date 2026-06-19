# INTELLIA237 Technical Rebrand Report

Date: 2026-06-18

Branch: `refactor/intellia237-rebrand-foundations`

## Objective

Transform the active technical identity from EDUNOVA to INTELLIA237 while preserving production store and Firebase continuity.

## Completed Changes

- Renamed the Dart package from `edunova` to `intellia237`.
- Renamed root app widget `EduNovaApp` to `Intellia237App`.
- Renamed the active curved navigation widget and related imports to Intellia naming.
- Replaced active visible Flutter copy from EduNova to INTELLIA237.
- Added typed `AppConfig` with production and staging identities.
- Added `lib/main_production.dart` and `lib/main_staging.dart`.
- Added runtime Firebase option validation so staging cannot accidentally start against production Firebase options.
- Added Android `production` and `staging` flavors.
- Renamed Android/iOS visible names to INTELLIA237.
- Copied source-backed web reference assets into `assets/branding/` and `assets/companions/`.
- Renamed Functions package metadata and active backend prompts/User-Agent to INTELLIA237.
- Added a CI brand reference check with an explicit allowlist.
- Rewrote README to describe the current Flutter/Firebase repository.

## Preserved Identifiers

| Identifier | Reason |
| --- | --- |
| `com.edunova.app` | Android/iOS production store continuity. |
| `edunova-aabd1` | Current production Firebase project. |
| `edunova-aabd1.firebasestorage.app` | Current production Storage bucket. |

## Staging Status

Prepared and validated:

- Flutter entrypoint: `lib/main_staging.dart`
- Android flavor: `staging`
- Visible name: `INTELLIA237 Staging`
- App config Firebase target: `intellia237-staging`
- `.firebaserc` alias: `staging`
- Android Firebase client registered for `com.intellia237.app.staging`.
- Real Android staging Firebase client config installed at `android/app/src/staging/google-services.json`.
- Android staging debug APK build succeeded.
- Staging debug APK path: `build/app/outputs/flutter-apk/app-staging-debug.apk`.
- Staging debug APK SHA256: `041933D692753AD837CBDC8F353B07216E7850D8D668A13723ADAFA09214F3C5`.

Remaining:

- iOS staging scheme/build configuration was not generated on Windows; complete on macOS/Xcode to avoid signing drift.
- No Firebase deployment has been performed.

## Validation Status

Completed locally on 2026-06-19:

| Command | Result | Notes |
| --- | --- | --- |
| `git diff --check` | Success | Line-ending warnings only from Git autocrlf. |
| `dart format --output=none --set-exit-if-changed .` | Success | No formatting changes required after final pass. |
| `flutter pub get` | Success | Run with `FLUTTER_SUPPRESS_ANALYTICS=true`. |
| `flutter analyze --no-pub lib test tool` | Success | Root `flutter analyze` hung locally on the Windows checkout; CI now targets active Dart sources explicitly. |
| `flutter test` | Success | 7 Flutter tests passed. |
| `npm ci` | Success | Local Node 22 warns against package engine Node 20; CI uses Node 20. |
| `npm test` | Success | 16 Functions tests passed. |
| `npm run build` | Success | TypeScript compiled successfully. |
| `npm audit --audit-level=high` | Success | Moderate vulnerabilities remain, no high/critical failure. |
| `npm run test:rules` | Success | Firestore and Storage rules tests passed after adding explicit rules test timeout. |
| `dart run tool/check_brand_references.dart` | Success | No unallowed legacy brand references. |
| `flutter build apk --debug --flavor production -t lib/main_production.dart --no-pub --no-android-gradle-daemon` | Success | Produced `build/app/outputs/flutter-apk/app-production-debug.apk`. |
| `flutter build apk --debug --flavor staging -t lib/main_staging.dart` | Success | Produced `build/app/outputs/flutter-apk/app-staging-debug.apk` with Firebase project `intellia237-staging` and package `com.intellia237.app.staging`. |

Static iOS validation:

- `ios/Runner/Info.plist` uses `$(APP_DISPLAY_NAME)` for display/name.
- Runner build configurations set `APP_DISPLAY_NAME = INTELLIA237`.
- Production `PRODUCT_BUNDLE_IDENTIFIER = com.edunova.app` remains unchanged.

## Exclusions

- No Firebase deployment.
- No production data modification.
- No payment integration.
- No Gemini/provider migration.
- No generated logo, launcher icon, or splash regeneration.
- No store identifier migration for production.
