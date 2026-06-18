# Authoritative Academic Data Model

Phase 2A moves reward-bearing academic state from client writes to authenticated callable Cloud Functions. The client may request an academic action, but Firestore state that affects XP, score, progression, streaks, rank, badges, or roles is computed and persisted on the server.

## Ownership Boundaries

| Collection | Client reads | Client writes | Server writes |
| --- | --- | --- | --- |
| `quiz_attempts/{attemptId}` | Student owner, linked parent, staff. | None. | `submitQuizAttempt` creates immutable attempts. |
| `progress/{progressId}` | Student owner, linked parent, staff. | None. | Quiz and lesson functions update summary progress. |
| `student_profiles/{uid}` | Student owner, linked parent, staff in establishment. | Preferences/consents only after bootstrap. | XP, level, score totals, mastery, badges, streak summaries, rank fields. |
| `student_profiles/{uid}/lessonProgress/{progressId}` | Student owner, linked parent, staff. | `isFavorite` only. | `recordLessonProgress` writes progress and timestamps. |
| `streaks/{uid}` | Student owner and linked parent. | None. | Academic functions update server-day streak state. |
| `users/{uid}` | Existing role-scoped access. | Safe display/profile fields only. | Roles, XP mirrors, entitlement/subscription, establishment assignment, approval state. |
| `teacher_profiles/{uid}` | Existing role-scoped access. | No public self-approval fields. | Future staff onboarding workflow. |
| `admin_profiles/{uid}` | Owner and superAdmin. | None for public creation. | SuperAdmin/server provisioning only. |

## Quiz Attempt Flow

1. Flutter sends `quizId`, `clientAttemptId`, and `answersByQuestion` to `submitQuizAttempt`.
2. The function uses `request.auth.uid` as the only student id.
3. Zod validates payload shape and answer limits.
4. The function loads the quiz from Firestore and verifies that it is published.
5. The function computes corrections, `score`, `maxScore`, and XP from stored quiz answers only.
6. A transaction writes the immutable attempt, increments XP on server-owned profile fields, updates progress/streak summaries, and returns the computed result.
7. Idempotency uses `(studentId, clientAttemptId)`. A replay with the same request hash returns the stored result. A reused id with a different payload is rejected.

## Lesson Progress Flow

1. Flutter sends `classLevel`, `subjectId`, `chapterId`, `lessonId`, `progress`, and `clientEventId` to `recordLessonProgress`.
2. The function uses `request.auth.uid`; `userId` in the client payload is ignored if present.
3. Progress is clamped to `[0, 1]`, never decreased below the existing stored progress, and stamped with server time.
4. Replays with the same `(studentId, clientEventId)` return the stored result.
5. Streaks are evaluated from the server date in the documented default timezone, not from phone time.
6. Lesson favorites remain client-owned, but rules allow only `isFavorite` changes on the progress document.

## XP Policy

XP is centralized in Functions. The initial policy is deliberately simple:

- Each correct quiz answer earns that question's server-defined `xpReward`.
- Invalid, missing, or negative `xpReward` values fall back to a bounded default.
- Client-supplied XP is ignored.
- Future badge, league, and rank logic must call the same policy/service layer instead of writing from Flutter.

## Role Security

- `role` is immutable from client updates.
- Public account creation may bootstrap `student` and `parent` documents only.
- `teacher`, `admin`, and `superAdmin` roles require a server/superAdmin provisioning workflow.
- Teacher/admin registration screens may collect requests later, but they must not create privileged user roles directly.

## App Check

App Check enforcement is not enabled in Phase 2A. The rollout is documented separately so enforcement can be introduced after client telemetry confirms valid attestation coverage.
