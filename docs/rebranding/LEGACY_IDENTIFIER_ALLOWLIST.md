# Legacy Identifier Allowlist

Date: 2026-06-18

This allowlist documents EDUNOVA-era identifiers that intentionally remain after the technical INTELLIA237 rebrand.

The executable policy is `tool/check_brand_references.dart`.

## Production Continuity

| Identifier | Location | Reason |
| --- | --- | --- |
| `com.edunova.app` | Android production flavor, iOS production target, Firebase options | Store continuity for the published production mobile app. |
| `edunova-aabd1` | `.firebaserc`, Flutter Firebase options, Functions emulator scripts/tests, README | Current production Firebase project. |
| `edunova-aabd1.firebasestorage.app` | Flutter Firebase options, Functions env default, scripts, README | Current production Storage bucket. |
| `com.example.edunova` | `android/app/google-services.json` | Historical Firebase client entry in the existing production config file. |
| Production identifiers in `test/app/config/app_config_test.dart` | App config regression test | Ensures production continuity identifiers are not accidentally changed. |

## Native Package Paths

| Identifier | Location | Reason |
| --- | --- | --- |
| `android/app/src/main/kotlin/com/edunova/app/MainActivity.kt` | Android Kotlin package path | Matches the preserved production namespace/application ID. |

## Historical Documentation

The following documentation keeps historical references intentionally:

- `docs/audits/`
- `docs/architecture/FIREBASE_ENVIRONMENTS.md`
- `docs/stabilization/FOUNDATION_STABILIZATION_REPORT.md`
- `docs/rebranding/`

## Legacy Assets

| Path | Reason |
| --- | --- |
| `assets/icons/edunova.png` | Legacy visual source, no longer referenced by active Flutter UI. |
| `assets/lottie/onboarding_welcome.json` | Legacy generated animation, no longer referenced by active Flutter UI. |
| `assets/lottie/education-excellence-v2.json` | Legacy generated animation, no longer referenced by active Flutter UI. |

## Policy

New EDUNOVA references must fail CI unless they are one of the documented continuity identifiers above. If a new exception is truly required, update both this document and `tool/check_brand_references.dart` in the same commit.
