# Server Authority Report

## Implemented

- Added authenticated callable `submitQuizAttempt`.
- Added authenticated callable `recordLessonProgress`.
- Moved Flutter quiz submission to `submitQuizAttempt`.
- Moved Flutter lesson progress writes to `recordLessonProgress`.
- Kept lesson favorites client-owned but restricted rules to `isFavorite` only.
- Denied client writes to `quiz_attempts`, `progress`, and `streaks`.
- Protected role, XP, level, establishment, and academic profile fields with Firestore rule whitelists.
- Blocked public teacher/admin role creation.
- Constrained avatar uploads to owner-only image files up to 5 MB.
- Added unit tests for quiz scoring, idempotency, conflict handling, invalid payloads, transaction failures, and lesson progress monotonicity.
- Updated Firestore and Storage emulator tests for the new policy.

## Final Validation

- `git diff --check`: passed.
- `dart format --output=none --set-exit-if-changed .`: passed.
- `flutter pub get`: passed.
- `flutter analyze`: passed.
- `flutter test`: passed.
- `npm ci`: passed with local Node 22 engine warning against target Node 20 and moderate audit findings.
- `npm test`: passed, 16 tests.
- `npm run build`: passed.
- `npm audit --audit-level=high`: passed; local audit output reports moderate findings only.
- `npm run test:rules`: passed, 14 Firestore rules tests and 8 Storage rules tests.

## Deliberate Non-Goals

- No production deploy.
- No production data migration.
- No App Check enforcement.
- No Gemini/LLM changes.
- No payment or entitlement implementation.
- No INTELLIA237 rebranding.

## Residual Work

- Build a staff request and approval workflow for teacher/admin provisioning.
- Add App Check monitor-mode client rollout.
- Implement server-owned badges, rank, league, and avatar moderation workflows.
- Recompute or classify legacy academic data before production enforcement.
