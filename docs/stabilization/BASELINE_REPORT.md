# Baseline Report - Foundation Stabilization

Date: 2026-06-18  
Branch: `fix/foundation-stabilization`  
Starting commit: `a90cab4 docs: add Intellia product design audit files`  
Remote: `https://github.com/CalvinEKENA/intellia237_mobile`

## Environment

| Tool | Version observed |
| --- | --- |
| Flutter | `3.44.2` stable, framework `c9a6c48423`, engine `77e2e94772` |
| Dart | `3.12.2` |
| Node.js | `v22.15.1` locally during baseline |
| npm | `11.2.0` |
| Java | Temurin OpenJDK `17.0.16+8`, configured through Flutter |
| Android SDK | `36.0.0` |
| OS | Windows 11 Professionnel 64 bits, 21H2 |

## Commands Executed

| Command | Result | Notes |
| --- | --- | --- |
| `git status` | Passed | Clean worktree on `fix/foundation-stabilization`. |
| `git log --oneline -10` | Passed | Recent commits: `a90cab4`, `edba7d6`, `c58a3fe`. |
| `flutter --version` | Passed | Flutter `3.44.2`, Dart `3.12.2`. |
| `dart --version` | Passed | Dart SDK `3.12.2`. |
| `flutter doctor -v` | Passed | No issues found. |
| `flutter pub get` | Passed with lockfile refresh | Updated 5 transitive packages in `pubspec.lock` under Flutter `3.44.2`; 58 packages have newer versions incompatible with constraints. |
| `dart format --output=none --set-exit-if-changed .` | Failed | 170 files scanned, 71 Dart files would be reformatted. No file was written by this command. |
| `flutter analyze` | Failed | 5 analyzer/compile errors in `lib/app/theme/app_theme.dart`. |
| `flutter test` | Failed | Test loading fails because `lib/app/theme/app_theme.dart` does not compile. |
| `node --version` | Passed | Local baseline Node is `v22.15.1`; Functions require Node `20`. |
| `npm --version` | Passed | npm `11.2.0`. |
| `npm ci` in `functions/` | Passed with warnings | Installed 588 packages; warns that package engine requires Node `20` but local Node is `22.15.1`; reports 83 vulnerabilities. |
| `npm test` in `functions/` | Passed | Vitest: 2 files passed, 5 tests passed. |
| `npm run build` in `functions/` | Passed | TypeScript build succeeded. |
| `npm audit` in `functions/` | Failed | 83 vulnerabilities: 2 low, 67 moderate, 12 high, 2 critical. |

## Initial Flutter Failures

`flutter analyze` reports these blocking errors:

- `lib/app/theme/app_theme.dart:97:31` - invalid constant value.
- `lib/app/theme/app_theme.dart:97:31` - `CupertinoPageTransitionsBuilder` is not defined for `AppTheme`.
- `lib/app/theme/app_theme.dart:97:31` - non-constant map value in a const map literal.
- `lib/app/theme/app_theme.dart:98:33` - `CupertinoPageTransitionsBuilder` is not defined for `AppTheme`.
- `lib/app/theme/app_theme.dart:98:33` - non-constant map value in a const map literal.

`flutter test` fails before executing assertions because `test/widget_test.dart` cannot load while `lib/app/theme/app_theme.dart` fails to compile.

## Initial Formatting Failure

The formatter check reports 71 Dart files that require mechanical formatting. Representative areas include:

- `lib/app/theme/**`
- `lib/core/widgets/**`
- `lib/features/admin/**`
- `lib/features/ai_companion/**`
- `lib/features/auth/**`
- `lib/features/learn/**`
- `lib/features/quiz/**`
- `lib/features/student_home/**`
- `lib/features/student_registration/**`
- `lib/features/teacher/**`
- `lib/features/tutor/**`
- `lib/firebase_options.dart`

## Initial Functions Status

Functions quality gates pass at baseline:

- `npm test`: passed, 5 tests.
- `npm run build`: passed.

The Functions environment is not standardized locally because the package requires Node `20`, while this baseline was executed with Node `22.15.1`.

## Initial npm Audit Summary

`npm audit` exits with failure and reports:

| Severity | Count |
| --- | ---: |
| Critical | 2 |
| High | 12 |
| Moderate | 67 |
| Low | 2 |

High or critical packages called out by npm include:

- `protobufjs`
- `vitest`
- `axios`
- `@grpc/grpc-js`
- `@opentelemetry/auto-instrumentations-node`
- `fast-uri`
- `fast-xml-builder`
- `form-data`
- `vite`
- `ws`

The audit recommends regular `npm audit fix` for several direct/remediable paths and `npm audit fix --force` for Genkit/OpenTelemetry-related breaking changes. Forced remediation is explicitly excluded from this phase.

## Baseline Risk Notes

- Flutter compilation is currently blocked by `CupertinoPageTransitionsBuilder`.
- Firebase initialization still uses `Firebase.initializeApp()` without explicit generated options.
- The LLM client still logs partial credential material before remediation.
- No Firestore or Storage rules test suite exists before this phase.
- No GitHub CI workflow exists before this phase.
- Server-authoritative XP and quiz attempts remain a known Phase 2 risk.

