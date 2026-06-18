# Academic State Migration Plan

Phase 2A changes write authority but does not mutate production data.

## Data To Review Before Production Enforcement

- `quiz_attempts`: identify attempts without server idempotency metadata or request hash.
- `users`: find documents where `xp`, role, entitlement, or establishment fields were client-modifiable before Phase 2A.
- `student_profiles`: find non-zero XP, level, total score, badges, mastery, rank, and streak fields written before server authority.
- `progress`: identify quiz or lesson progress records not written by server functions.
- `streaks`: identify documents with phone-clock-derived dates or impossible streak values.

## Recommended Migration Steps

1. Export or snapshot production data before any cleanup.
2. Classify existing academic fields as trusted, suspicious, or unknown.
3. Recompute quiz-derived XP from trusted quiz attempts where possible.
4. Preserve user-visible history while marking uncertain legacy data with migration metadata.
5. Run server-side scripts in dry-run mode first.
6. Apply writes through Admin SDK with audit logs.
7. Verify reads from student, linked parent, teacher, admin, and superAdmin contexts in the emulator before deploy.

## Rollback

Rules can be reverted independently from Functions because server writes use Admin SDK. If client impact is detected, prefer temporarily re-enabling only non-academic display fields rather than reopening XP, score, role, or progress writes.
