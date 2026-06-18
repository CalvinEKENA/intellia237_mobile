# Quiz Attempt Integrity

## Callable Contract

`submitQuizAttempt` is an authenticated callable Cloud Function in `europe-west1`.

Client payload:

- `quizId`: Firestore quiz document id.
- `clientAttemptId`: client-generated idempotency key matching `^[A-Za-z0-9_-]+$`, 8 to 80 characters.
- `answersByQuestion`: map of question id to raw answer string.
- `startedAt`: optional client timestamp for diagnostics only.
- `durationSeconds`: optional client duration for diagnostics only.

Server response:

- `attemptId`
- `quizId`
- `quizTitle`
- `subjectId`
- `subjectLabel`
- `score`
- `maxScore`
- `xpAwarded`
- `corrections`
- `submittedAt`
- `idempotentReplay`
- `traceId`

## Integrity Controls

- The function uses `request.auth.uid` as the student id. Any client-supplied user id is ignored.
- Zod rejects unknown fields, including client-supplied `xpAwarded`.
- The quiz is loaded from Firestore inside the transaction and must have `status = published`.
- Every answer id must match a server-side question id from the quiz.
- The server computes score, corrections, max score, and XP from stored quiz data.
- Firestore rules deny all client create/update/delete on `quiz_attempts`.
- Reward writes to `users`, `student_profiles`, `progress`, and `streaks` happen through Admin SDK transaction writes only.

## Idempotency

The attempt document id is derived from `(studentId, clientAttemptId)`.

- Same key and same request hash: return the stored result with `idempotentReplay = true`.
- Same key and different request hash: reject with `already-exists`.
- New key: compute and persist a new immutable attempt.

## XP Policy

The initial policy is implemented in `functions/src/services/xpPolicy.ts`.

- Correct answers earn the server-defined `question.xpReward`.
- Missing or invalid `xpReward` values fall back to the bounded default policy.
- Client-side XP is never read.

## Known Follow-Ups

- Add abuse throttling once App Check telemetry is available.
- Add a review workflow for quiz content quality before increasing XP stakes.
- Add rank/league recalculation as a separate server-owned job, not a client write.
