# Development Environment

Date: 2026-06-18

## Verified Local Baseline

| Tool | Version |
| --- | --- |
| Flutter | `3.44.2` stable |
| Dart | `3.12.2` |
| Java | Temurin OpenJDK `17.0.16+8` |
| Android SDK | `36.0.0` |
| Firebase CLI | `15.16.0` |
| Local Node observed during baseline | `22.15.1` |
| Required Functions Node runtime | `20` |

## Required Node Version

Cloud Functions must use Node 20. The repository now includes:

- `.nvmrc`
- `.node-version`
- `functions/package.json` with `"engines": { "node": "20" }`

Recommended local setup:

```bash
nvm use
node --version
cd functions
npm ci
```

The expected major version is Node `20`.

## Verification Commands

From repository root:

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

From `functions/`:

```bash
npm ci
npm test
npm run build
npm audit
npm run test:rules
```

`npm audit` currently reports moderate residual vulnerabilities through Firebase Admin transitive dependencies. CI gates high and critical vulnerabilities with `npm audit --audit-level=high`.

## Firebase Emulator Suite

Firebase Rules tests require Firebase CLI and Java. They do not contact production Firestore or Storage.

```bash
cd functions
npm run test:rules:firestore
npm run test:rules:storage
```

Do not run Firebase deploy commands during foundation stabilization.
