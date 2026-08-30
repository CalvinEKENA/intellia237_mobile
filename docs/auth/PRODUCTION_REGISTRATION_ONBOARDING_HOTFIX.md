# Production registration and onboarding hotfix

Date: 2026-08-30
Canonical Firebase/GCP project: `edunova-aabd1`
Android package kept unchanged: `com.edunova.app`

No remote Firebase project was modified. No deploy, push or merge was run.

## DATA-PERM-101 root cause

The former repository always sent the two complete creation maps through a
batch with `SetOptions(merge: true)`. That operation is a create only while the
document is absent. On a retry, it becomes an update and replays immutable
initialisation fields such as `createdAt`, `role`, `classLevel`, `series`,
`points` and `level`. The owner update rules deliberately reject those fields.
The complete batch is atomic, so one rejected update surfaces as
`permission-denied` / `DATA-PERM-101` and neither document advances.

The emulator test named
`reproduces DATA-PERM-101 when the legacy exact merged batch is retried`
executes the complete production-shaped `users` and `student_profiles` maps:
the first batch succeeds and the second is rejected.

A second deterministic failure affected historical documents: owner update
rules dereferenced `establishmentId`, `classLevel` and `series` even when an old
document did not contain one of those keys. A missing key causes a Rules
evaluation error. These redundant comparisons were removed; the strict update
allowlists already make all those fields immutable.

## Idempotent correction

- Firebase Auth is reused when the matching user is already current.
- If account creation returns `email-already-in-use`, the repository signs in
  with the credentials just entered and resumes registration.
- Auth accounts are no longer deleted after a recoverable Firestore/network
  failure. An Auth-only partial state is now a supported retry state.
- `users/{uid}` and `student_profiles/{uid}` are handled independently in
  transactions. An absent document receives the exact complete create map; an
  existing document receives an explicit owner-safe update map.
- Retry maps never contain `role`, `points`, `level`, `establishmentId`,
  `createdAt`, `classLevel` or `series`.
- Auth display name and email verification remain best-effort metadata work and
  cannot invalidate an already persisted registration.

The client cannot create a public teacher/admin role, promote itself, alter
points or level, or write an authoritative establishment link. The Rules still
have no broad authenticated-write grant.

## Neutral diagnostics

The registration path no longer depends on `isStaging`, `_logStaging` or a
staging-only decorated message. Non-sensitive diagnostics expose only:

- `registrationOperation`: `AUTH_CREATE`, `USER_DOC_CREATE`,
  `USER_DOC_UPDATE`, `PROFILE_CREATE`, `PROFILE_UPDATE`, `APP_CHECK`, `NETWORK`
  or `UNKNOWN`;
- `normalizedErrorCode`;
- `diagnosticId`.

No email, password, token or personal payload is logged.

## Onboarding and INTELLIA PASS

- Replaced the opening copy with a human learning-experience formulation in
  French and English.
- Removed the visible skip control completely.
- Replaced the yellow/cosmic activation light and particle texture with a soft
  white/ivory light treatment.
- Added four distinct secondary-wide micro-challenges for Mathematics,
  French, English and Sciences. The model already accepts `subject`,
  `academicLevel` and `subsystem` context.
- Every submitted answer now shows feedback and a separate “Appuie pour
  continuer” / “Tap to continue” control. Its arrow animates only when motion
  is allowed.
- Simplified the reversible-companion copy and added a touch-completable,
  Reduced-Motion-safe typewriter description.
- Propagated the Kira/Léo Journey State into the later portal scene.
- Added a subtle slow camera zoom/pan to `assets/branding/affiche.jpg`; Reduced
  Motion keeps the poster stable.
- Added a reusable text wordmark with restrained green/red/yellow treatment on
  digits 2/3/7.
- Replaced the legacy `assets/branding/icon-192.png` reference with the official
  application icon and added a regression test that scans product Dart.
- Reworked INTELLIA PASS/auth surfaces to white, ivory and light surfaces with
  explicit text, border, inactive-choice and search-placeholder colours.
- Replaced the technical academic-passport sentence with learner/parent copy.
- Removed cliché AI iconography from the audited onboarding/auth/registration
  surfaces.

## Phone/OTP direction and temporary email

The target product identity is now stated in the UI as phone + OTP. The current
student Firebase flow still needs a technical email and password; the hotfix
labels and explains that dependency rather than pretending that OTP is already
available or silently inventing an email migration.

Before integrating MboaSMS or ETECH, the following remains necessary:

1. select the provider and sign the delivery/availability/data-processing
   contract;
2. keep provider credentials only in server-side secret storage;
3. implement a callable that normalises Cameroon E.164 numbers, rate-limits
   sends and verifies short-lived, one-time codes;
4. authenticate provider callbacks and protect the callable with App Check,
   abuse monitoring and replay protection;
5. define phone uniqueness, recovery, SIM-change and number-reassignment rules;
6. migrate/link existing email accounts without creating duplicate guardians;
7. make the guardian graph server-authoritative before child-profile creation;
8. specify encrypted local PIN/biometric recovery on recognised devices;
9. update consent, privacy and support procedures; and
10. run an explicitly authorised production rollout against `edunova-aabd1`.

## Production-only configuration audit

`.firebaserc` now resolves its `default` alias to `edunova-aabd1`. The production
entry point and package remain unchanged. No staging build, staging Firebase
emulator target or staging deployment was used for this mission; the full test
suite still contains historical configuration unit tests pending cleanup.

Historical staging infrastructure was deliberately not deleted blindly. A
future cleanup can remove, after a dedicated dependency review:

- `lib/main_staging.dart`, `AppConfig.staging` and staging Firebase options;
- Android staging flavor resources and client configuration;
- staging branches in Functions environment validation;
- tests that only validate the historical staging identity; and
- obsolete staging procedures in architecture, auth, release, security and
  design documents.

## Real-device limitation

ADB was unavailable, as stated in the mission. Reproduction and validation are
therefore automated through Dart repository fakes, Firebase Rules emulators,
widget tests and the production APK build. Installation and final interaction
on a physical device remain the only outstanding device-specific checks.
