# INTELLIA PASS — family identity and OTP boundary

## Family graph

The canonical learner record is keyed by `learnerUid`. A normalized
`GuardianLearnerLink` joins a generic `guardianUid` to that learner. Labels such
as mother, father, guardian, or other describe the real-world relationship; they
never grant authority. Authority requires a server-verified, non-revoked link
and an explicit permission. A second guardian therefore adds another link to
the same learner and must never create a second academic profile.

Secure invites, temporary codes, and QR linking are only transport mechanisms.
Their payloads must resolve to a short-lived, single-use server record. The
client cannot create a verified link or assign its own permissions.

Device trust is a separate record. A learner can use multiple authorised family
devices, and a device can expose multiple authorised learner selectors. Course
progress remains keyed to learner identity, never to a device identifier.

## Cameroon phone identity and OTP

Ordinary parent identity is phone-first (`+237…` E.164); email is optional for
recovery, receipts, and administration. Flutter calls only INTELLIA backend
endpoints. The backend selects an SMS or WhatsApp adapter from configuration,
generates a cryptographically secure OTP, and applies this contract:

- five-minute target TTL and one-time consumption;
- HMAC or slow-hash verifier only; no raw OTP in Firestore;
- bounded attempts, resend cooldown, and invalidation of the previous code;
- per-phone and per-device limits plus IP/risk throttling where available;
- App Check, idempotent send keys, and non-enumerating responses;
- no OTP or provider secret in logs, analytics, Flutter, or source control;
- sensitive-free audit events for successful and failed verification.

Provider names and Sender ID approval are operational configuration. The UI
shows only SMS/WhatsApp channels and always retains SMS fallback. No production
provider adapter or credential is included in this change.

After successful verification, Firebase Admin maps the verified phone identity
to one canonical guardian UID, creates a short-lived custom token, and Flutter
uses `signInWithCustomToken`. Firebase then remains the normal session and
authorization system. OTP is reserved for registration, untrusted devices, and
recovery—not daily app opening.

## Learner sessions on shared devices

Existing academic callables derive the student identity from
`request.auth.uid`. A parent Firebase session therefore cannot safely send a raw
`learnerId` and pretend to be that learner. This is a current integration risk.

The recommended future design is a server-issued, short-lived learner custom
token (or a separately reviewed secondary Firebase Auth context) created only
after checking the guardian link, permission, device trust, revocation, and
parental gate. Delegated guardian authorization could instead be added to every
callable, but that is wider and easier to implement inconsistently. No auth
context or callable contract is changed in this mission.

## Study Mode

Study Mode selects a learner and a duration after parental authorization. On
Android it may guide app pinning or use lock-task only on properly managed
devices; on iOS it may guide the parent to Guided Access. An ordinary app cannot
silently force kiosk mode on an unmanaged personal device.

At timeout, the state becomes `sessionComplete` and stays inside INTELLIA237.
The parent reclaims the device through the parental gate; the app does not exit
to the phone home screen automatically.
