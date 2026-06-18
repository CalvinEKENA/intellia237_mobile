# Firebase Environments

Date: 2026-06-18  
Scope: documentation only. No deployment, billing link, `flutterfire configure`, data copy, or Firebase credential generation was performed.

## Production

| Item | Value |
| --- | --- |
| Project ID | `edunova-aabd1` |
| Role | Current production Firebase project for the published EDUNOVA mobile app. |
| Policy | Do not modify directly during development. Use production only after local and staging validation. |

The existing Android application ID and iOS bundle identifier must remain unchanged for store updates:

- Android: `com.edunova.app`
- iOS: `com.edunova.app`

## Staging

| Item | Value |
| --- | --- |
| Project ID | `intellia237-staging` |
| Billing | Spark mode at the time of this phase. Do not link billing in this phase. |
| Role | Future validation environment for fake data, Cloud Functions deployment tests, Gemini tests, and Mobile Money workflow tests. |

No staging client config file was generated or committed in this phase:

- No new `google-services.json`.
- No new `GoogleService-Info.plist`.
- No `flutterfire configure`.
- No production data copy.

## Local

Local development and tests should use Firebase Emulator Suite.

Configured emulator ports from `firebase.json`:

| Emulator | Port |
| --- | ---: |
| Auth | `9100` |
| Firestore | `8085` |
| Functions | `5005` |
| Storage | `9200` |
| Emulator UI | `4005` |

Rules tests run through:

```bash
cd functions
npm run test:rules
```

## Promotion Strategy

Use this sequence for future work:

1. Local emulator validation.
2. Staging deployment and fake-data validation.
3. Production release after explicit approval.

Production remains the default Firebase project in `.firebaserc`. The added `staging` alias is only a named reference and was not used for deployment.
