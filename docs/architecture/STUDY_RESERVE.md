# Study Reserve — architecture & integration (section C)

Product-safe per-student usage allowance. Public wording is **"Réserve d'étude" /
"Study reserve"** only — never *token*, *tokens*, *XP*, *crédits IA* or similar.

## Server-authoritative core (implemented + tested)

`functions/src/services/studyReserve.ts`:
- **Usage ledger** (idempotent): `study_reserve/{studentId}/ledger/{cycleId}__{requestId}`
  stores `studentId, cycleId, requestId, provider, model, inputUnits, outputUnits,
  billableUnits, createdAt`. A repeated `requestId` is a no-op (retry never
  double-charges).
- **Aggregate**: `study_reserve/{studentId}` stores `allowanceInternal, consumed,
  cycleId, cycleStart, cycleEnd, latestThresholdEmitted`.
- **Thresholds** 75/50/25/5/0 — each emitted **once per cycle** (lowest newly
  reached wins), recorded in `latestThresholdEmitted`.
- **Product-safe view** (`StudyReserveView`): `percentRemaining, status, cycleStart,
  cycleEnd, latestThresholdEmitted` — raw model accounting is never returned.
- **Authorization**: `getStudyReserve` callable returns the caller's own reserve,
  or a **linked child's** reserve for a parent (checks approved `children_links`);
  any other student is `permission-denied`.

Tests (`functions/src/__tests__/studyReserve.test.ts`, 11): remaining%/status,
threshold-once, normal consumption, idempotency, independent children, threshold
crossing, no duplicate alert, zero reserve, renewal/reset, unauthenticated,
own-vs-linked-vs-stranger visibility.

The ledger/aggregate collections are server-only (Admin SDK). No client writes;
no Firestore rule weakened. `getStudyReserve` inherits the global App Check
enforcement.

## Client (implemented + tested)

- `StudyReserve` domain model + `StudyReserveStatus` (product-safe).
- `StudyReserveService` / `studyReserveProvider(studentId)` — reads the callable;
  `null` = self, a child UID = a linked child (parent). Each child is independent.
- `StudyReserveGauge` — 100→0% gauge, remaining %, status text, renewal date,
  friendly depleted help. Bilingual FR/EN, product-safe (a test asserts no
  token/XP/credit wording ever appears).

## Remaining integration (follow-up, tracked here)

1. **Deduction wiring** — the audited quota-consuming entry point is
   `functions/src/services/askTutorUseCase.ts` (backed by `tutorDailyQuota.ts`).
   Centralize accounting there: before the model call assert the reserve is > 0
   (block only quota-consuming companion/model ops at 0%, never static learning
   content); after a successful call, `recordUsage(...)` with the request's
   idempotency key and the provider `usageMetadata` (input/output/billable) already
   captured by `llmClient.ts`. Allowance/cycle seeding belongs to the subscription
   plan (Studio "Study Reserve administration").
2. **UI placement** — mount `StudyReserveGauge` in the student profile/home area
   and on each parent child card/detail (one gauge per child).
3. **Threshold notifications** — on a `thresholdEvent`, notify the child and the
   linked parent(s) in-app (a document the client reads); push only where the
   existing notification architecture safely supports it.

At 0%: only the AI tutor / model operations are blocked; lessons, quizzes and
readings stay fully available (enforced at the deduction site, per point 1).
