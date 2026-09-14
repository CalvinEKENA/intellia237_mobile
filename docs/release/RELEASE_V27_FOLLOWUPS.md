# Release v27 — non-blocking technical follow-ups

These are intentionally **out of scope** for the v3.2.1+27 release closure (they
are either potentially breaking or not user-facing) and must be handled as
separate, audited changes.

## 1. Firebase runtime & dependencies (section J)
- **Node.js 20 runtime decommissioning before 2026-10-30.** Cloud Functions must
  be migrated to a supported runtime before that date. Do **not** bundle this
  into v27 — validate separately with a full functions deploy dry-run.
- **`firebase-functions` upgrade** from `^6.0.1`. Potentially breaking; upgrade
  and re-run the full functions + rules suites on its own branch.

Existing remote-only functions **must not be deleted** by any migration:
`chatWithDavid`, `generateExercises`, `gradeAnswer` (us-central1). They are not
in local source and are left untouched.

## 2. INTELLIA Campus wiring
Campus currently uses `DemoCampusRepository` (in-memory demo fixtures) and has no
navigation entry point. Before exposing any Campus entry point, either wire the
`ICampus*Repository` contracts to real Firestore/Functions implementations, or
gate the `/campus` route behind an explicit demo flag so no fabricated data can
be shown as real.

## 3. Parent-linking policy option
Code-based child links are auto-approved (possession of the child's code is the
authorization), per the product decision. The legacy establishment-mediated
`pending → approved` path remains available. If policy later requires code links
to also be admin-approved, switch `linkChildByCode` to create `status: 'pending'`.
