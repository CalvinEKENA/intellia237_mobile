# EDUNOVA Reference Inventory

Date: 2026-06-18

Branch: `refactor/intellia237-rebrand-foundations`

Scope: source inventory before replacing active EDUNOVA branding with INTELLIA237.

Scan command:

```powershell
rg -n -i "edunova|edu_nova|edu-nova|com\.edunova|edunova-aabd1" -g "!node_modules" -g "!.dart_tool" -g "!build" -g "!.git" -g "!functions/node_modules" -g "!functions/lib"
```

`functions/lib` is generated JavaScript output and mirrors `functions/src`; it will be regenerated after TypeScript changes instead of edited as a source of truth.

## Decision Rules

| Category | Decision |
| --- | --- |
| Public product copy, visible app title, web shell title, comments naming the active app | Replace with `INTELLIA237` / `Intellia237` as appropriate. |
| Dart package name, imports and active class/file symbols | Rename from `edunova` / `EduNova` to `intellia237` / `Intellia237`. |
| Android production application ID | Keep `com.edunova.app` for store continuity. |
| iOS production bundle ID | Keep `com.edunova.app` for store continuity. |
| Production Firebase project and bucket | Keep `edunova-aabd1` / `edunova-aabd1.firebasestorage.app`. |
| Historical audit/stabilization/security docs | Keep as historical references. |
| Legacy visual assets that are not used after the rebrand pass | Keep only if documented in the asset migration plan and blocked from active UI use. |

## Active Mobile And Flutter References

| File | Lines | Current reference | Action |
| --- | ---: | --- | --- |
| `pubspec.yaml` | 1-2 | package name `edunova`, description `EduNova` | Rename package to `intellia237`; update description. |
| `lib/main.dart` | 7 | `EduNovaApp` | Rename root widget usage to `Intellia237App`. |
| `lib/app/app.dart` | 7-15 | `EduNovaApp`, app title `Edunova` | Rename root class and title; wire environment config. |
| `test/widget_test.dart` | 1-5, 29 | `package:edunova`, `EduNovaApp` | Update imports and widget name. |
| `test/app/theme/app_theme_test.dart` | 1 | `package:edunova` | Update import. |
| `lib/core/widgets/edunova_curved_bottom_nav_bar.dart` | all symbol references | `EduNovaCurvedNavItem`, `EduNovaCurvedBottomNavBar` | Rename file and symbols to Intellia naming. |
| `lib/core/widgets/edunova_curved_bottom_nav_bar_example.dart` | all symbol references | example class/import/items | Rename file and symbols. |
| `lib/features/admin/presentation/admin_home_screen.dart` | 5, 22-75 | nav import and `EduNovaCurved*` symbols | Update import and symbols. |
| `lib/features/parent/presentation/widgets/parent_premium_nav_bar.dart` | 3, 15-24 | nav import and `EduNovaCurved*` symbols | Update import and symbols. |
| `lib/features/student_home/presentation/student_home_screen.dart` | 10, 46-148 | nav import and `EduNovaCurved*` symbols | Update import and symbols. |
| `lib/features/teacher/presentation/teacher_home_screen.dart` | 5, 21-68 | nav import and `EduNovaCurved*` symbols | Update import and symbols. |
| `lib/features/bootstrap/presentation/bootstrap_screen.dart` | 147, 216 | comment and `assets/icons/edunova.png` | Replace comment and point active UI to Intellia asset. |
| `lib/features/auth/presentation/login_screen.dart` | 125, 304, 336 | email hint, badge comment, `EduNova` badge text | Replace with Intellia237 values. |
| `lib/features/auth/presentation/forgot_password_screen.dart` | 220 | email hint `exemple@edunova.cm` | Replace with Intellia237 hint. |
| `lib/features/auth/application/auth_controller.dart` | 142 | fallback email `${role.name}@edunova.app` | Replace with Intellia237 domain. |
| `lib/features/student_registration/presentation/student_registration_flow_screen.dart` | 352, 423 | visible copy `EduNova` | Replace visible copy. |
| `lib/features/admin/data/mock_admin_repository.dart` | 77 | `Direction EduNova` | Replace mock display name. |
| `lib/features/student_registration/domain/academic_rules.dart` | 1 | comment `EDUNOVA` | Rename comment. |
| `lib/features/onboarding/domain/onboarding_slides.dart` | 6, 11 | comments and slide copy `EDUNOVA` / `EduNova` | Replace copy with Intellia237-aligned copy. |
| `lib/features/onboarding/presentation/onboarding_screen.dart` | 261 | visible `EduNova` | Replace visible copy. |
| `lib/features/onboarding/presentation/widgets/onboarding_slide_view.dart` | 107 | visible `EduNova` | Replace visible copy. |
| `lib/features/student_home/presentation/student_home_screen.dart` | 435, 441 | fallback user/email `Utilisateur EduNova`, `email@edunova.app` | Replace visible fallback values. |
| `lib/features/tour_guide/data/firestore_tour_guide_repository.dart` | 70, 86 | local cache key `edunova_tour_seen_$uid` | Rename to Intellia237 cache key; acceptable one-time local reset. |

## Platform Identity References

| File | Lines | Current reference | Action |
| --- | ---: | --- | --- |
| `android/app/src/main/AndroidManifest.xml` | 4 | visible label `Edunova` | Replace with string resource; flavor-specific names. |
| `android/app/build.gradle.kts` | 22, 37 | namespace/app ID `com.edunova.app` | Keep production identifier; add production/staging flavors. |
| `android/app/google-services.json` | 4-31 | Firebase prod project, prod package and historical package | Keep production Firebase config. Do not create fake staging config. |
| `android/app/src/main/kotlin/com/edunova/app/MainActivity.kt` | 1 | package path `com.edunova.app` | Keep for production application ID continuity. |
| `ios/Runner/Info.plist` | 8, 16 | visible names `Edunova` | Replace visible name with build setting/default Intellia237. |
| `ios/Runner.xcodeproj/project.pbxproj` | 371, 550, 572 | production bundle ID `com.edunova.app` | Keep production bundle ID; document staging setup on Windows. |
| `ios/Runner.xcodeproj/project.pbxproj` | 387, 404, 419 | test bundle IDs `com.edunova.app.RunnerTests` | Keep as test bundle continuity unless Xcode scheme migration is performed later. |
| `macos/Runner/Configs/AppInfo.xcconfig` | 8, 11, 14 | product name, bundle ID, copyright | Rename visible product/copyright; keep or document bundle ID if retained. |
| `macos/Runner.xcodeproj/.../Runner.xcscheme` | 18, 34, 69, 86 | build product `edunova.app` | Rename if macOS target is updated mechanically. |
| `macos/Runner.xcodeproj/project.pbxproj` | 67, 134, 220, 388-419 | macOS app/test product and IDs | Rename visible product where safe; document retained IDs. |
| `linux/CMakeLists.txt` | 7, 10 | binary name `edunova`, application ID `com.edunova.app` | Rename desktop visible binary; preserve production ID only if needed. |
| `linux/runner/my_application.cc` | 48, 52 | window title `Edunova` | Replace visible title. |
| `windows/CMakeLists.txt` | 3, 7 | project/binary `edunova` | Rename desktop project/binary if safe. |
| `windows/runner/Runner.rc` | 93, 95, 97, 98 | visible Windows metadata `Edunova` | Replace visible metadata. |
| `windows/runner/main.cpp` | 30 | window class/name `edunova` | Rename to Intellia237 naming. |
| `web/manifest.json` | 2-3 | web name `Edunova` | Replace shell metadata. |
| `web/index.html` | 24, 30 | web title `Edunova` | Replace shell metadata. |

## Firebase And Backend References

| File | Lines | Current reference | Action |
| --- | ---: | --- | --- |
| `lib/firebase_options.dart` | 53-73 | prod Firebase project/bucket and iOS bundle ID | Keep production Firebase values. |
| `.firebaserc` | observed in docs | prod/default project `edunova-aabd1` | Keep prod/default; ensure staging alias exists. |
| `functions/package.json` | 2 | package name `edunova-functions` | Rename package to `intellia237-functions`. |
| `functions/package.json` | 13-16 | emulator project `edunova-aabd1` | Keep production/emulator project ID until staging Firebase config exists. |
| `functions/package-lock.json` | 2, 7 | package name `edunova-functions` | Regenerate/update lock metadata. |
| `functions/src/llm/prompts.ts` | 41, 83, 107 | active prompt brand `EDUNOVA` | Replace with `INTELLIA237`; keep prompt logic. |
| `functions/src/llm/prompts.ts` | 107 | `tuteur d'intelligence artificielle` | Replace wording with `compagnon pedagogique` where brand copy can surface. |
| `functions/src/llm/llmClient.ts` | 80 | User-Agent `EdunovaFunctions/1.0` | Rename to `Intellia237Functions/1.0`. |
| `functions/src/config/env.ts` | 5 | default storage bucket `edunova-aabd1...` | Keep production default bucket. |
| `functions/src/__tests__/rules/firestore.rules.test.ts` | 18 | project ID `edunova-aabd1` | Keep emulator test project ID. |
| `functions/src/__tests__/rules/storage.rules.test.ts` | 12 | project ID `edunova-aabd1` | Keep emulator test project ID. |
| `functions/check.js` | 3 | project ID `edunova-aabd1` | Keep prod/emulator helper default. |
| `functions/test-glm.js` | 6, 10, 34 | project ID, emulator URL, test email | Keep project ID/URL; rename test email domain. |
| `functions/seed_all.js` | 7-8 | comment/project ID | Keep project ID; update comment wording. |
| `functions/seed_courses.js` | 9-10 | comment/project ID | Keep project ID; update comment wording. |
| `scripts/smoke_test.py` | 66 | default project ID | Keep production default. |
| `scripts/seed_sample_course.py` | 28 | default project ID | Keep production default. |
| `scripts/ingest_drive_to_storage.py` | 167-168 | default project/bucket | Keep production defaults. |

## Active Asset References

| File | Lines | Current reference | Action |
| --- | ---: | --- | --- |
| `assets/icons/edunova.png` | file path | legacy logo asset | Stop using in active UI; keep only if documented as legacy source asset. |
| `assets/lottie/onboarding_welcome.json` | 8, 4794, 5000 | embedded `Edunova` text | Treat as legacy generated animation; remove from active onboarding or document pending replacement. |
| `assets/lottie/education-excellence-v2.json` | 4778, 4984 | embedded `Edunova` text | Treat as legacy generated animation; remove from active onboarding or document pending replacement. |

## Historical Documentation References

These files document prior audits, risks, or stabilization state and should keep historical EDUNOVA references:

| File | Reason |
| --- | --- |
| `docs/audits/CODEX_TECHNICAL_AUDIT.md` | Historical audit of the pre-rebrand state. |
| `docs/audits/CODEX_MIGRATION_INVENTORY.json` | Historical machine-readable inventory. |
| `docs/audits/CODEX_FEATURE_MATRIX.md` | Historical feature matrix. |
| `docs/audits/CODEX_RISK_REGISTER.md` | Historical risk register. |
| `docs/audits/GEMINI_PRODUCT_DESIGN_AUDIT.md` | Historical comparison against the web reference. |
| `docs/audits/INTELLIA_COPY_REFERENCE.md` | Copy migration reference that explicitly contrasts old/new wording. |
| `docs/audits/WEB_TO_FLUTTER_COMPONENT_MAP.md` | Migration map from EduNova mobile to Intellia237 web patterns. |
| `docs/architecture/FIREBASE_ENVIRONMENTS.md` | Production continuity document for `edunova-aabd1` and store IDs. |
| `docs/stabilization/FOUNDATION_STABILIZATION_REPORT.md` | Historical Phase 1 report. |

## README References

`README.md` currently describes an old EDUNOVA backend/microservice model and contains obsolete local paths, environment variable names and deployment examples. It will be rewritten as an INTELLIA237 mobile repository README with current Flutter/Firebase architecture, environment commands, test commands, and explicit non-deployment status for staging.
