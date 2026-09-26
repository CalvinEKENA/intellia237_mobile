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

- `entitlements/{parentId}_{establishmentId}` — written by
  `FirestoreMobileMoneyStore.reviewPayment` (`functions/src/services/mobileMoneyCallables.ts`)
  when a payment is approved: `status`, `startsAt`, `endsAt`,
  `offerId = paymentRequest.offerId`. The request's `offerId` is written by
  `submitParentPayment` as `offer.id`, the document id of
  `mobile_money_offers/{establishmentId}`, and the callable rejects any
  `input.offerId !== establishmentId` — so **`offerId === establishmentId`**.
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

### Owner decision (V1)

Each child receives an **independent** reserve (no household pool) with:

```
study_reserve_plans/<existing establishmentId used as Mobile Money offerId>
  allowanceInternal: 600000   // INTERNAL ONLY — never shown in any client
  cycleDays: 30
```

The value lives only in this server document (no constant in Functions or
Flutter), so INTELLIA Studio can edit it later. Clients cannot read or write
`study_reserve*` (Firestore rules test).

Until that document exists (or if it is malformed), the reserve is
`unavailable`: the gauge shows the unavailable state, the tutor keeps running
under the daily question limit, nothing is deducted.

### `ensureCurrentStudyReserveCycle(studentId)`

Called by **both** `getStudyReserve` and `StudyReserveConsumption.run` (before any
reservation).

1. Resolve the student's establishment (`users/{studentId}.establishmentId` —
   the same source Mobile Money uses to scope the parent — then
   `student_profiles` as a legacy fallback), their
   approved `children_links` parents, and each `entitlements/{parentId}_{establishmentId}`.
   Malformed documents (missing/unreadable `endsAt`, missing `startsAt`,
   start after end) are ignored. Active = `status == "active"` and
   `startsAt <= now < endsAt`. Several paying parents → the window ending last.
2. No active entitlement, or no valid plan config → `null` → **unavailable**.
   The stored aggregate and ledger are neither modified nor deleted, but an old
   cycle is never shown as a live reserve and never debited.
3. Current cycle: whole paid window (`cycleDays` absent) or the `cycleDays` slice
   containing `now`, capped at `endsAt`.
   `cycleId = {offerId}_{windowStartMs}[_{sliceIndex}]`.
4. Same `cycleId` → **never reset** consumption. If the configured allowance
   changed (e.g. 600000 → 700000 with 300000 consumed → 57 %), or an early
   renewal pushed back the end of a short final slice, only `allowanceInternal`
   / `cycleEnd` are updated (transaction, cycle-checked).
5. Missing aggregate, expired cycle, new window or different offer → transactional
   new cycle: `allowanceInternal` from config, `consumed = 0`, new
   `cycleId/cycleStart/cycleEnd`, `latestThresholdEmitted = null`, `holds = {}`.
   A concurrent call that already opened the same cycle wins (no double reset).
   The ledger is kept.

Because Mobile Money early renewal keeps `startsAt` and extends `endsAt`, a
whole-window cycle would only refill when a *new* window starts; with
`cycleDays: 30` the extended window is sliced into days 0–29, 30–59, … (the last
slice capped at `endsAt`). Boundary: `startsAt + 30 d − 1 ms` is still cycle 0,
`startsAt + 30 d` opens cycle 1.

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
- **Retry**: same `requestId` → ledger hit, no second charge (the provider is
  called again; the response is not cached).
- **Hold writes** always replace the whole `holds` map (`mergeFields`). A
  `merge: true` write merges maps key by key and left committed holds in place
  while another request was in flight (caught by the emulator test).

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
  views; bilingual; responsive 320–600 px, text scale 1.0–2.0.
- Card states: loading frame, call failure ("couldn't load" + retry) and the
  server's legitimate `unavailable` are three distinct, visible states.
- Notifications screen renders `study_reserve_threshold` from ARB.
- Tutor screen shows `companionStudyReserveDepleted` for `studyReserveExhausted`,
  distinct from the daily question limit.
- Student language is stored at registration
  (`student_profiles.preferences.interfaceLanguage`) → FR/EN push. Parent
  profiles store a hard-coded `language: "fr"` that is not a user choice and is
  not read → parents receive inbox-only threshold notifications.

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

- `rules/studyReserve.integration.test.ts` (emulator, production stores) — real
  Mobile Money submit + approval → entitlement → offerId join → plan;
  auto-provisioning via `getStudyReserve` and via `askTutor`; two children of one
  parent (300000 consumed → 50 % vs 100 %); concurrent holds, hold cleanup;
  estimate > remaining without provider call; actual > hold → 0 % then blocked;
  provider failure; mid-cycle 600000 → 700000; malformed config → unavailable;
  early renewal → 30-day cycles, ledger kept, sibling untouched; expiry →
  unavailable. Run with `npm run test:integration:study-reserve`.
- `rules/firestore.rules.test.ts` — `study_reserve`, its ledger and
  `study_reserve_plans` are server-only.

## Deployment (not done)

Functions affected: `getStudyReserve` (new), `askTutor` (modified),
`deliverNotificationPush` (modified). Then create
`study_reserve_plans/<establishmentId>` = `{ allowanceInternal: 600000, cycleDays: 30 }`
for each establishment whose `mobile_money_offers/<establishmentId>` is active.
