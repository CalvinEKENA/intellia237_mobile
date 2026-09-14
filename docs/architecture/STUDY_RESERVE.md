# Study Reserve — architecture, provisioning & policies

Product-safe per-student usage allowance. Public wording is **"Réserve d'étude" /
"Study reserve"** only — never *token*, *tokens*, *XP*, *crédits IA* or similar.
Each child has an independent reserve (no household-shared pool).

## Modules

| File | Role |
| --- | --- |
| `functions/src/services/studyReserveUnits.ts` | Leaf module: thresholds, `sanitizeThreshold`, `safeUnits` (no Firestore, no import cycle). |
| `functions/src/services/studyReserveProvisioning.ts` | `ensureCurrentStudyReserveCycle` — cycle creation/renewal from the real entitlement. |
| `functions/src/services/studyReserve.ts` | Aggregate/ledger model, product-safe view, `getStudyReserve` callable. |
| `functions/src/services/studyReserveConsumption.ts` | Reserve → run → commit/release around model calls, threshold notifications. |
| `functions/src/services/askTutorUseCase.ts` | The single quota-consuming entry point wrapped by the consumption layer. |
| `functions/src/services/notificationDelivery.ts` | Push trigger; understands `deliveryMode: "inbox_only"`. |

Firestore (server-only, Admin SDK; no client writes, no rule weakened):
- `study_reserve/{studentId}` — `allowanceInternal, consumed, cycleId, cycleStart,
  cycleEnd, latestThresholdEmitted, holds{requestId: {units, tsMs}}`.
- `study_reserve/{studentId}/ledger/{cycleId}__{requestId}` — real usage per
  request (idempotency key). Preserved across cycles.
- `study_reserve_plans/{offerId}` — **owner configuration** (see below).

## 1. Entitlement audit & provisioning

### What exists in the product today

- `entitlements/{parentId}_{establishmentId}` — written when a Mobile Money payment
  is approved: `status`, `startsAt`, `endsAt`, `offerId` (= establishmentId).
  Scope is **parent + establishment**, not student. An early renewal **keeps
  `startsAt` and extends `endsAt`**.
- `mobile_money_offers/{establishmentId}` — title, XAF amount, duration.
  **No Study Reserve allowance field.**
- `TUTOR_DAILY_QUESTION_LIMIT` (env, default 20) — a daily *question count*, not
  an allowance per plan.
- The public plan names (Cahier / Atelier / Bibliothèque) have **no server-side
  quota configuration** attached.

**Conclusion: there is no canonical per-plan Study Reserve allowance.** No number
is invented in code.

### Owner decision required

Create one document per offer the reserve should apply to:

```
study_reserve_plans/{offerId}
  allowanceInternal: integer > 0      // required — internal units per cycle
  cycleDays:         integer 1..366   // optional — omit = one cycle per paid window
```

Also confirm that each linked child receives the full allowance derived from the
family entitlement (current implementation: yes, independent per child).

Until that document exists (or if it is malformed), the reserve is
`unavailable`: the gauge shows the unavailable state, the tutor keeps running
under the daily question limit, nothing is deducted.

### `ensureCurrentStudyReserveCycle(studentId)`

Called by **both** `getStudyReserve` and `StudyReserveConsumption.run` (before any
reservation).

1. Resolve the student's establishment (`student_profiles` → `users`), their
   approved `children_links` parents, and each `entitlements/{parentId}_{establishmentId}`.
   Malformed documents (missing/unreadable `endsAt`, missing `startsAt`,
   start after end) are ignored. Active = `status == "active"` and
   `startsAt <= now < endsAt`. Several paying parents → the window ending last.
2. No active entitlement, or no valid plan config → return the stored aggregate
   unchanged (never grant, never reset).
3. Current cycle: whole paid window (`cycleDays` absent) or the `cycleDays` slice
   containing `now`, capped at `endsAt`.
   `cycleId = {offerId}_{windowStartMs}[_{sliceIndex}]`.
4. Same `cycleId` → **never reset** consumption. If the configured allowance
   changed, only `allowanceInternal` is updated (transaction, cycle-checked).
5. Missing aggregate, expired cycle, new window or different offer → transactional
   new cycle: `allowanceInternal` from config, `consumed = 0`, new
   `cycleId/cycleStart/cycleEnd`, `latestThresholdEmitted = null`, `holds = {}`.
   A concurrent call that already opened the same cycle wins (no double reset).
   The ledger is kept.

Because Mobile Money early renewal keeps `startsAt`, a whole-window cycle only
refills when a *new* window starts. Owners who want a monthly refill inside a long
paid window must set `cycleDays`.

## 2. Concurrency & overspend policy

- **Reserve**: in a transaction, `remaining = allowance − consumed − active holds`
  (holds expire after 5 min). The request is accepted only if
  `remaining >= estimateUnits` (tutor default estimate: 1000). Otherwise
  `resource-exhausted` with `details.reason = "study_reserve_exhausted"`, and the
  model is **never called**.
  - remaining 300, estimate 1000 → rejected.
  - remaining 1500, A and B each 1000 → A holds 1000, B sees 500 → rejected.
- **Commit**: ledger + aggregate in one transaction, idempotent on `requestId`;
  the hold is removed and the **actual** provider usage is charged.
  - actual < estimate → only actual is charged; the rest is released.
  - actual > estimate → actual is charged truthfully (ledger stays exact); the
    aggregate floors at 0 % and blocks every further reservation. Overshoot is
    bounded by the requests already in flight that each passed the
    `remaining >= estimate` check — never unbounded.
- **Failure**: provider error → hold released, nothing charged.
- **Retry**: same `requestId` → ledger hit, no second charge.

The client maps `study_reserve_exhausted` to its own state (localized
"reserve depleted" copy), distinct from the daily question limit which shares the
`resource-exhausted` code.

At 0 % only the AI tutor is blocked; lessons, quizzes and readings stay available.

## 3. Threshold policy

Thresholds 75 / 50 / 25 / 5 / 0, watermark `latestThresholdEmitted` per cycle.

- A commit that drops the percentage past several thresholds emits **only the
  most severe** one newly reached (e.g. 100 % → 20 % emits 25).
- The watermark records that 75 and 50 were passed: they are **never sent later**
  or out of order. Subsequent drops only emit thresholds below the watermark
  (20 % → 10 % emits nothing; 10 % → 3 % emits 5).
- A new cycle resets the watermark.

## 4. Notification policy

One document per recipient (student + each approved parent), id
`study_reserve_{cycleId}_{threshold}_{recipientId}` → a threshold can never be
duplicated for a recipient, even on retries.

Fields: `userId, type: "study_reserve_threshold", data{threshold, studentId,
audience}, route: "/notifications", sourceId, createdAt, deliveryMode`.

- Recipient language known (`student_profiles.preferences.interfaceLanguage`,
  `interfaceLanguage`, `users.interfaceLanguage`, `users.language`; `fr*` → FR,
  `en*`/`angl*` → EN) → `deliveryMode: "push"` with server-localized FR or EN
  title/body.
- Language unknown → `deliveryMode: "inbox_only"`, empty title/body. The push
  trigger records `deliveryState: "inbox_only"` — no push is sent, the document
  is not flagged invalid. No French-only fallback push.
- In-app, the client re-localizes from `type` + `data` via ARB, so inbox copy
  always follows the device language.
- Ordinary notifications with missing title/body are still classified `invalid`.

## 5. Client

- `StudyReserve` domain model (`unavailable` default), `studyReserveProvider(studentId)`.
- `StudyReserveGauge` / `StudyReserveCard` — student home and per-child parent
  views; bilingual; responsive at 320 px / 2.0× text.
- Notifications screen renders `study_reserve_threshold` from ARB.
- Tutor screen shows the depleted status/help for `studyReserveExhausted`.

## Tests

- `studyReserveProvisioning.test.ts` — entitled student without doc, auto-provision,
  same-cycle no reset, expired/new window renewal, `cycleDays` slicing, plan change,
  mid-cycle allowance change, inactive / missing entitlement, missing config,
  malformed legacy entitlements, invalid plan config.
- `studyReserveConsumption.test.ts` — real usage, idempotent retry, estimate >
  remaining, two concurrent reservations, actual < / > hold, release on failure,
  zero reserve, not configured, independent children, threshold once, large drop,
  bilingual copy, exhaustion reason.
- `studyReserveNotifications.test.ts` — FR push, EN push, inbox-only fallback,
  ordinary invalid, inbox-only without user, stable id, locale normalization.
- `studyReserve.test.ts` — view/status, ledger idempotency, callable authorization.

The Firestore transaction code is exercised through in-memory doubles that mirror
the same rules; no emulator test covers the transactions themselves.

## Deployment (not done)

Functions affected: `getStudyReserve` (new), `askTutor` (modified),
`deliverNotificationPush` (modified). Then create `study_reserve_plans/{offerId}`
documents once the owner fixes allowance and cadence.
