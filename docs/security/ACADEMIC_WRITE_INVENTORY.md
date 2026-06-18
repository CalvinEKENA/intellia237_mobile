# Academic Write Inventory

This inventory records every client or server write path found before the Phase 2A server-authority changes. It is intentionally scoped to academic state, role security, and avatar storage.

## Sensitive Client Writes

| Area | File | Current write | Risk | Target owner |
| --- | --- | --- | --- | --- |
| Quiz attempts | `lib/features/quiz/data/firestore_quiz_attempt_service.dart` | Creates `quiz_attempts/{autoId}` from client-computed answers, score, corrections, and `xpAwarded`. | A client can forge score, XP, answer details, quiz id, and student id. | Cloud Function `submitQuizAttempt`. |
| User XP | `lib/features/quiz/data/firestore_quiz_attempt_service.dart` | Merges `users/{uid}.xp += attempt.xpAwarded`. | A client controls the increment amount and can inflate XP. | Cloud Function transaction. |
| Student profile XP | `lib/features/quiz/data/firestore_quiz_attempt_service.dart` | Merges `student_profiles/{uid}.xp += attempt.xpAwarded`. | A client controls academic progression fields. | Cloud Function transaction. |
| Lesson progress | `lib/features/learn/data/firestore_learn_repository.dart` | Writes `student_profiles/{uid}/lessonProgress/{subjectId}_{chapterId}_{lessonId}.progress`. | A client can set arbitrary completion and timestamps. | Cloud Function `recordLessonProgress`. |
| Lesson favorites | `lib/features/learn/data/firestore_learn_repository.dart` | Writes `isFavorite` in the same `lessonProgress` document. | Low academic impact, but shares a document with protected progress. | Keep client-writable only for `isFavorite`, or route through the same callable. |
| Tour guide | `lib/features/tour_guide/data/firestore_tour_guide_repository.dart` | Writes `users/{uid}.tourGuideSeen`. | Low academic impact. Must remain isolated from protected user fields. | Client update whitelist. |
| Avatar URL | `lib/features/profile/services/profile_image_service.dart` | Uploads `avatars/{uid}/profile.jpg` and updates `users/{uid}.photoUrl`. | Storage lacks MIME/size constraints; Firestore update must not allow role/XP edits. | Client upload with strict Storage rules plus user update whitelist. |
| Student registration | `lib/features/student_registration/data/firebase_student_registration_repository.dart` | Creates `users/{uid}` and `student_profiles/{uid}` with role `student`, academic context, and initial XP/level. | Initial profile creation includes sensitive fields; allowed only at zero-value bootstrap. | Client create for student bootstrap only, then server-owned academic fields. |
| Parent registration | `lib/features/role_registration/data/firebase_role_registration_repository.dart` | Creates `users/{uid}` role `parent` and `parent_profiles/{uid}`. | Acceptable public role if role is immutable after create. | Client create with parent bootstrap constraints. |
| Teacher registration | `lib/features/role_registration/data/firebase_role_registration_repository.dart` | Creates `users/{uid}` role `teacher` and `teacher_profiles/{uid}`. | Public sign-up currently grants teacher role immediately. | Block direct teacher role grant; use future pending/review server flow. |
| Admin registration | `lib/features/role_registration/data/firebase_role_registration_repository.dart` | Creates `users/{uid}` role `admin` and `admin_profiles/{uid}`. | Public sign-up can request privileged role and profile. | Block client admin creation; superAdmin/server-only provisioning. |

## Existing Server Writes

| Area | File | Write | Boundary |
| --- | --- | --- | --- |
| Generated quizzes | `functions/src/repositories/generatedContentRepository.ts` | Writes `courses/{courseId}/generated_quizzes/{quizId}`. | Already server-only by Firestore rules. |
| Generated summaries | `functions/src/repositories/generatedContentRepository.ts` | Writes `courses/{courseId}/generated_summaries/{summaryId}`. | Already server-only by Firestore rules. |

## Rule Gaps To Close

- `quiz_attempts` currently allows student create/update. Phase 2A must allow reads only and deny all client create/update/delete.
- `progress` currently allows student create/update. Phase 2A must make academic progress server-owned.
- `student_profiles/{uid}` currently allows owner updates, including `xp`, `level`, `streak`, and other academic fields.
- `student_profiles/{uid}/lessonProgress/{progressId}` currently allows owner read/write. Phase 2A must block client writes to `progress` and server timestamps, while preserving read access.
- `streaks/{uid}` currently allows owner create/update. Phase 2A must make streaks server-owned.
- `users/{uid}` currently allows owner updates, including `role`, `xp`, and establishment fields.
- `teacher_profiles/{uid}` currently allows owner create/update. Phase 2A must not let public users self-approve teacher capabilities.
- `admin_profiles/{uid}` creation is already superAdmin-only, but `users/{uid}.role = admin` is not constrained enough in the shared role registration flow.
- `avatars/{uid}/...` currently permits any file size and MIME type for the owner.

## Allowed Client-Owned Fields After Phase 2A

- `users/{uid}`: display fields such as `firstName`, `lastName`, `avatarId`, `photoUrl`, `profileCompleted`, `tourGuideSeen`, `updatedAt`.
- `student_profiles/{uid}`: non-authoritative preferences and consents only. Initial creation may set `xp = 0`, `level = 1`, and empty/default streak values, but later client updates cannot change academic metrics.
- `parent_profiles/{uid}`: parent preferences and pending child identifiers; approved child links remain separate and privileged.
- `student_profiles/{uid}/lessonProgress/{progressId}`: read by owner, linked parent, and staff; writes through `recordLessonProgress`.
- `quiz_attempts/{attemptId}`: read by owner, linked parent, and staff; writes through `submitQuizAttempt`.
- `avatars/{uid}/...`: owner upload/delete only, with image MIME and 5 MB maximum.
