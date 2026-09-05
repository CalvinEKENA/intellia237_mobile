# PR #10 — Gemini / Vertex AI update section

The following section is ready to paste into the PR description after explicit
authorization to edit the PR.

## Gemini 3.8 Flash / Vertex AI migration

- Migrated the server-side tutor, quiz and summary generation paths to Gemini
  3.8 Flash through Google Vertex AI at the `global` location.
- Authentication uses Application Default Credentials from the Cloud Functions
  runtime. No Gemini, GLM or Z.ai API key is embedded in Flutter or committed.
- Project resolution supports `VERTEX_AI_PROJECT_ID`, then
  `GOOGLE_CLOUD_PROJECT`, then `GCLOUD_PROJECT`.
- Tutor generation uses `LOW` thinking; structured quiz/summary generation uses
  `MEDIUM` thinking and validates returned JSON with Zod.
- Added privacy-safe structured telemetry for operation, model, latency,
  outcome, HTTP category, timeout, parsing failure, quota rejection, token
  usage and correlation ID. Prompts, course content, answers and credentials are
  excluded from logs.
- Added client-side Firebase App Check initialization: Play Integrity for
  production Android releases and debug providers for development/staging.
  Enforcement remains disabled pending coverage monitoring.
- Functions and Flutter automated validation cover endpoint construction,
  project fallback, thinking levels, secret-safe errors, malformed responses,
  environment isolation and App Check provider selection.

### Validation status

- Foundation Quality CI: required after this change.
- Local Functions and Flutter gates: required after this change.
- Staging Firebase/Vertex runtime validation: **pending**.
- Physical Android device validation, including Play Integrity: **pending**.
- Production deployment: **not performed**.

This supersedes the historical statement that the PR contains no Firebase or
Functions changes.
