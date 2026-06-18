# Foundation Stabilization Report

Date: 2026-06-18  
Branch: `fix/foundation-stabilization`  
Starting commit: `a90cab4 docs: add Intellia product design audit files`

## Summary

Phase 1 restored the Flutter quality gate, removed credential-fragment logging from the LLM client, standardized the Functions runtime target to Node 20, reduced npm critical/high vulnerabilities to zero without `--force`, added Firebase Rules tests, created CI, and documented production/staging/local environments.

No Firebase deployment was run. No Gemini call was executed. No Android application ID or iOS bundle identifier was changed. No rebranding, tutor replacement, payment feature, Mobile Money integration, Firebase data migration, signing change, certificate change, or store release work was performed.

## Files Modified Or Created

Major areas:

- `.github/workflows/foundation-quality.yml`
- `.firebaserc`
- `.nvmrc`
- `.node-version`
- `lib/app/theme/app_theme.dart`
- `lib/bootstrap.dart`
- `pubspec.lock`
- `test/widget_test.dart`
- `test/app/theme/app_theme_test.dart`
- `functions/package.json`
- `functions/package-lock.json`
- `functions/vitest.config.ts`
- `functions/vitest.rules.config.ts`
- `functions/src/llm/llmClient.ts`
- `functions/src/__tests__/llmClientLogging.test.ts`
- `functions/src/__tests__/rules/firestore.rules.test.ts`
- `functions/src/__tests__/rules/storage.rules.test.ts`
- `docs/architecture/FIREBASE_ENVIRONMENTS.md`
- `docs/stabilization/BASELINE_REPORT.md`
- `docs/stabilization/DEVELOPMENT_ENVIRONMENT.md`
- `docs/stabilization/NPM_SECURITY_TRIAGE.md`
- `docs/stabilization/FOUNDATION_STABILIZATION_REPORT.md`

## Compilation Fix

The Flutter compile failure came from `CupertinoPageTransitionsBuilder` in `lib/app/theme/app_theme.dart`. The fix imports Cupertino explicitly while keeping the existing Material 3 theme and Cupertino transitions for iOS/macOS.

Result:

- `flutter analyze`: success.
- `flutter test`: success.

## Firebase Bootstrap

`lib/bootstrap.dart` now initializes Firebase explicitly with:

```dart
Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
)
```

Firebase initialization is no longer silently ignored. A startup failure logs only the error type and stack trace, then aborts startup. No Firebase project ID or generated platform config file was changed.

## Flutter Formatting And Tests

The 71 Dart files identified by the audit were formatted in an isolated mechanical commit.

Additional Flutter tests:

- theme instantiation for light/dark `ThemeData`;
- `PageTransitionsTheme` builder checks;
- minimal `MaterialApp` smoke test;
- app shell widget test with fake auth repository and Riverpod overrides.

Final Flutter validation:

| Command | Result |
| --- | --- |
| `dart format --output=none --set-exit-if-changed .` | Success |
| `flutter pub get` | Success |
| `flutter analyze` | Success |
| `flutter test` | Success, 3 tests passed |

## LLM Secret Logging

`functions/src/llm/llmClient.ts` no longer logs:

- key length;
- key prefix;
- key suffix;
- Authorization header;
- provider response body that could echo sensitive data.

The client now logs only non-sensitive metadata such as:

- operation name;
- `providerConfigured`;
- `modelConfigured`;
- duration;
- status;
- error type.

Added automated test:

- `functions/src/__tests__/llmClientLogging.test.ts`

It verifies that a fake key is not present in logs or thrown errors, even when the mocked provider response echoes that key.

## Node 20 Standardization

Node 20 is now documented and declared through:

- `.nvmrc`
- `.node-version`
- `functions/package.json` engines
- CI Node setup
- `docs/stabilization/DEVELOPMENT_ENVIRONMENT.md`

The local machine used for this run still reported Node `22.15.1`, so npm emitted `EBADENGINE` warnings locally. CI uses Node 20.

## npm Audit

Initial baseline:

- Critical: 2
- High: 12
- Moderate: 67
- Low: 2

Final result:

- Critical: 0
- High: 0
- Moderate: 8
- Low: 0

Actions taken:

- removed unused Genkit/OpenAI dependencies;
- aligned Node typings to Node 20;
- applied `npm audit fix` without `--force`;
- added a targeted `esbuild` override.

Remaining vulnerabilities are moderate and require a Firebase Admin major-version remediation path. That change was deferred because it is breaking and requires a dedicated compatibility/staging pass.

## Firestore Rules Tests

Added:

- `functions/src/__tests__/rules/firestore.rules.test.ts`
- script `npm run test:rules:firestore`

Final result:

- 10 active tests passed.
- 1 target-behavior test skipped with explicit justification.

The tests cover unauthenticated access, student access, parent links, teacher establishment scope, admin versus super-admin actions, generated content write denial, notifications, and recommendations.

Documented current weaknesses:

- students can still write their own quiz attempts and XP-bearing profile fields;
- teachers can currently update their own `users/{uid}.role` field because owner updates are broad.

These are Phase 2 trust-boundary fixes.

## Storage Rules Tests

Added:

- `functions/src/__tests__/rules/storage.rules.test.ts`
- script `npm run test:rules:storage`

Final result:

- 7 tests passed.

The tests cover unauthenticated reads, authenticated avatar reads, owner avatar writes, cross-user avatar write denial, course image write denial, and current absence of avatar size/MIME constraints.

## CI

Created `.github/workflows/foundation-quality.yml`.

Triggers:

- pull requests to `main`;
- pushes to `fix/**`;
- pushes to `feature/**`.

Jobs:

- Flutter quality: Java 17, Flutter 3.44.2, `flutter pub get`, format check, analyze, tests.
- Functions quality: Node 20, `npm ci`, unit tests, build, `npm audit --audit-level=high`.
- Firebase rules: Node 20, Java 17, Firebase CLI 15.16.0, Firestore and Storage rules tests.

The workflow does not deploy, does not include secrets, does not call an LLM, and does not contact production Firebase.

## Final Validation Results

| Command | Result |
| --- | --- |
| `git diff --check` | Success |
| `dart format --output=none --set-exit-if-changed .` | Success |
| `flutter pub get` | Success |
| `flutter analyze` | Success |
| `flutter test` | Success |
| `npm ci` in `functions/` | Success with local Node engine warning |
| `npm test` in `functions/` | Success, 6 tests passed |
| `npm run build` in `functions/` | Success |
| `npm audit` in `functions/` | Fails on 8 moderate residual vulnerabilities |
| `npm run test:rules` in `functions/` | Success: Firestore 10 passed/1 skipped, Storage 7 passed |

## Changes Explicitly Excluded

- No rebranding from EDUNOVA to INTELLIA237.
- No Android `applicationId` change.
- No iOS bundle identifier change.
- No Firebase production data migration.
- No Firebase deploy or Functions deploy.
- No Gemini integration or real Gemini call.
- No payment, Orange Money, MTN Mobile Money, Pass, or Intellia Flow implementation.
- No tutor replacement or visual redesign.

## Phase 2 Recommendations

1. Make `users/{uid}.role` immutable for ordinary users and move role assignment to trusted backend/admin flows.
2. Move quiz attempt validation, XP, streaks, badges, and authoritative progress writes to Cloud Functions.
3. Add avatar upload size/type constraints or server-side image processing.
4. Plan and test the Firebase Admin major upgrade path to remove residual moderate npm vulnerabilities.
5. Add emulator-backed integration tests for auth registration, role onboarding, quiz attempt flows, and progress writes.
