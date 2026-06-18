# Codex Technical Audit - Intellia237 Mobile

Date: 2026-06-18  
Repository: `CalvinEKENA/intellia237_mobile`  
Local path: `C:\projets\FlutterProjects\Intellia237`  
Audit mode: read-only functional audit. No app code, Firebase config, package identifier, signing asset, key, certificate, deployment, or generated credential was changed.

## Executive Verdict

The repository is a substantial Flutter/Firebase application shell, but it is not production-ready in its current state. The first blocking issue is a compile-time Flutter error in `lib/app/theme/app_theme.dart` around `CupertinoPageTransitionsBuilder`, which makes `flutter analyze` fail and prevents `flutter test` from loading the widget test.

The second major finding is architectural drift: the codebase still carries Edunova identifiers, package names, assets, prompts, and tutors, while the requested Intellia237/Kira/Leo/Gemini target is not implemented. The deployed backend shape in code is Firebase Callable Functions backed by a GLM/Z.ai-compatible chat completions client. The README describes a Gemini/FastAPI microservice architecture, but the tracked repository does not contain an `llm-service/` directory.

The third major finding is trust-boundary weakness. Some sensitive educational records and reward state are written from the Flutter client. In particular, quiz attempts are client-authored and the client increments XP from `attempt.xpAwarded`, while Firestore rules allow students to create and update their own quiz attempts. This is a launch-blocking integrity risk for rankings, badges, progression, and any future monetization or certification.

## Verified Scope

Only files already present in the repository were audited. Secrets, API keys, service-account values, Firebase web keys, and signing material were not copied into this report. Where such files or fields exist, they are described as present or redacted.

Primary reviewed areas:

- Flutter app: `lib/`, `pubspec.yaml`, `android/`, `ios/`, `web/`, `assets/`.
- Firebase: `.firebaserc`, `firebase.json`, `firestore.rules`, `firestore.indexes.json`, `storage.rules`, `lib/firebase_options.dart`, platform Firebase config files.
- Cloud Functions: `functions/package.json`, `functions/src/**`, `functions/scripts/**`.
- Tests and CI: `test/`, `functions/src/__tests__/`, `.github`.
- Python utilities: `scripts/*.py`. No tracked Python microservice directory was found.

## Command Results

| Command | Result | Notes |
| --- | --- | --- |
| `flutter doctor -v` | Passed | Flutter stable `3.44.2`, Dart `3.12.2`, Android SDK `36.0.0`, Java 17, Chrome, Windows desktop, network resources OK. |
| `flutter pub get` | Passed with local lockfile change | Resolved dependencies. It reported 58 newer packages incompatible with current constraints. It changed `pubspec.lock`; the change was restored to keep audit-only scope. |
| `dart format --output=none --set-exit-if-changed .` | Failed | 170 Dart files checked, 71 would be reformatted. No source file was written because `--output=none` was used. |
| `flutter analyze` | Failed | 5 compile/analyzer errors in `lib/app/theme/app_theme.dart:97-98`, `CupertinoPageTransitionsBuilder` not resolved. |
| `flutter test` | Failed | Test loading fails on the same `CupertinoPageTransitionsBuilder` compile error. |
| `npm install` in `functions/` | Passed with warnings | Package install is up to date, but local Node is `v22.15.1` while package requires Node 20. `npm audit` reports 83 vulnerabilities: 2 low, 67 moderate, 12 high, 2 critical. |
| `npm test` in `functions/` | Passed | Vitest: 2 files, 5 tests passed. |
| `npm run build` in `functions/` | Passed | TypeScript build `tsc -p tsconfig.json` succeeded. |
| Python microservice checks | Not executable | No tracked `llm-service/` or equivalent Python microservice was present. Only utility scripts exist under `scripts/`. |

## Architecture Observed

### Flutter Application

The app uses Flutter with Riverpod and GoRouter:

- `lib/main.dart` boots `ProviderScope`.
- `lib/bootstrap.dart` initializes bindings, Google Fonts, onboarding preferences, and Firebase.
- `lib/app/app.dart` renders `MaterialApp.router`.
- `lib/app/router/app_router.dart` defines route guards and role-based redirects.
- `lib/app/router/app_routes.dart` contains routes for onboarding, auth, student, learn, quiz, AI companion, parent, teacher, admin, and tutor selection.

The UI is Material 3 based through `lib/app/theme/app_theme.dart`, but that file currently blocks static analysis and tests.

### Firebase Integration

Firebase is configured for project `edunova-aabd1`:

- `.firebaserc` uses `edunova-aabd1`.
- `firebase.json` configures Functions, Firestore rules/indexes, Storage rules, and emulators.
- `lib/firebase_options.dart` includes generated Firebase options for web, Android, and iOS. API key values are present in the file and intentionally redacted from this audit.
- `android/app/google-services.json` is present and contains Firebase client config for package names including `com.edunova.app`. Values are intentionally redacted here.

Important technical note: `lib/bootstrap.dart` calls `Firebase.initializeApp()` without passing `DefaultFirebaseOptions.currentPlatform`, although `lib/firebase_options.dart` documents that usage. This can work on native platforms with generated platform config, but is fragile for web and nonstandard targets.

### Cloud Functions And AI

Tracked callable Functions:

- `generateQuiz` in `functions/src/index.ts`.
- `generateSummary` in `functions/src/index.ts`.
- `askTutor` in `functions/src/index.ts`.

Flutter calls them from:

- `lib/features/tutor/data/structured_ai_functions_service.dart`.
- `lib/features/ai_companion/data/cloud_ai_repository.dart`.

The actual LLM runtime is GLM/Z.ai style:

- `functions/src/config/env.ts` defines `GLM_API_KEY`, `GLM_MODEL`, and `GLM_BASE_URL`.
- `functions/src/llm/llmClient.ts` posts to a chat completions endpoint using `env.GLM_MODEL`.
- Generated content metadata uses `engineMode: "glm"`.

This conflicts with the README, which describes Gemini environment variables and a FastAPI microservice. The requested target model `gemini-3.5-flash` is not wired in the tracked Functions code.

### Firestore And Storage Rules

The rules implement role checks for students, parents, teachers, admins, and super admins. Several collections are staff-only or Functions-only, which is positive, especially generated quiz/summary writes under `courses/{courseId}/generated_*`.

However, several records remain client-controlled:

- `quiz_attempts`: students can create and update their own attempts.
- `progress`: students can create and update their own progress.
- `student_profiles/{uid}/lessonProgress`: owner can read/write.
- `streaks/{uid}` and `settings/{uid}`: owner can create/update.
- `ai_conversations`: user can create/update their own conversation documents.

Storage rules allow authenticated users to read avatars and the owner to write under `avatars/{uid}/...`. Course image writes are denied in Storage rules, while Firestore course image metadata is staff controlled.

## Feature Readiness Summary

| Area | Current State | Production Readiness |
| --- | --- | --- |
| Auth and registration | FirebaseAuth + Firestore profile creation for student, parent, teacher, admin flows. | Partial. Needs rules tests, duplicate/rollback hardening, and role assignment policy review. |
| Routing and onboarding | GoRouter guard model and onboarding persistence exist. | Partial. Current compile blocker must be fixed first. |
| Student home | Demo repository is used. | Not production-ready. |
| Learn/course browsing | Firestore repository exists for classes, subjects, chapters, lessons, and lesson progress. | Partial. Needs data model validation, indexes, pagination, and trusted progress writes. |
| Quiz browsing/play/results | Firestore quiz repository and attempt service exist. | Blocked for production by client-authored attempt/XP trust model. |
| AI companion | Callable Function `askTutor` exists and frontend uses it. | Partial. Provider/model mismatch, retrieval quality, prompt/cost controls, and tutor target mismatch remain. |
| Generated quiz/summary | Callable Functions and Firestore generated content storage exist. | Partial. Backend builds/tests pass, but LLM provider target mismatch and cost/security controls remain. |
| Admin content studio | Client-side CRUD for classes/subjects/chapters/lessons/quizzes exists. | Partial. Needs stricter server validation and workflow/audit trail before broad production use. |
| Admin dashboard/moderation | Mock repository is wired. | Demo only. |
| Parent portal | Mock repository is wired. | Demo only. |
| Teacher portal | Mock repository is wired. | Demo only. |
| Tutor selection | Six hard-coded Edunova personas exist. | Not aligned with requested Kira/Leo target. |
| Payments/subscriptions/quotas | No implemented collection/service found. | Missing. |
| CI/CD | No `.github` directory found. | Missing. |

## Key Risks

Critical and elevated risks are detailed in `CODEX_RISK_REGISTER.md`. The most important launch blockers are:

1. Flutter app does not pass analysis or tests due to a compile error.
2. XP and quiz attempts can be influenced by client writes.
3. Current AI implementation is GLM/Z.ai, not the requested Gemini `gemini-3.5-flash` target.
4. Functions log partial API-key material and lack cost/rate controls around LLM calls.
5. Several user-facing areas are still demo/mock-backed.

## Migration Gap Toward Intellia237

Current verified identity:

- App/package identity: Edunova, `com.edunova.app`.
- Firebase project: `edunova-aabd1`.
- Android manifest label: Edunova.
- iOS display name: Edunova.
- Pub package name and description: Edunova.
- Tutors: hard-coded Edunova-style personas, not Kira and Leo.
- AI provider: GLM/Z.ai environment variables and metadata.

Target gaps to decide before any implementation:

- Whether Intellia237 is only a product label change or also a package/application identifier migration.
- Whether Firebase stays on `edunova-aabd1` or a new production/staging project is required.
- Whether to replace GLM with Gemini directly in Functions, add a separate microservice, or keep a provider abstraction.
- Whether Kira and Leo are only persona names or full behavior/safety profiles with different prompts and assets.
- Whether XP/progression must become authoritative backend state before public beta.

## Testing And Quality Gaps

Verified test inventory:

- Flutter: `test/widget_test.dart`.
- Functions: `functions/src/__tests__/llmPayloadFactory.test.ts`, `functions/src/__tests__/validation.test.ts`.

Missing or insufficient:

- No Firestore rules tests.
- No Storage rules tests.
- No integration tests for auth, registration, learn, quiz, progress, and callable Functions.
- No emulator-backed end-to-end CI.
- No golden/widget coverage for large route surfaces.
- No load/cost tests for AI calls.
- No CI workflow in `.github`.

## Five Priority Decisions

1. Decide the production identity strategy: keep `com.edunova.app` and rename only visible branding, or perform a full bundle/package/Firebase migration.
2. Decide the AI target architecture: Gemini in Cloud Functions, a separate Python service, or a provider-agnostic backend with explicit failover.
3. Decide the trust model for XP, attempts, progress, streaks, and recommendations: client-authored versus server-authoritative.
4. Decide which demo-backed portals must become real before beta: student home, parent, teacher, admin dashboard/moderation.
5. Decide the release gate: minimum passing `flutter analyze`, `flutter test`, Functions test/build, Firebase rules tests, and CI before any store or Firebase deploy.

