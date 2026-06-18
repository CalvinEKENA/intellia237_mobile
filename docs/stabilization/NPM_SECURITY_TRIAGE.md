# npm Security Triage

Date: 2026-06-18  
Package scope: `functions/`

## Summary

| Metric | Before | After |
| --- | ---: | ---: |
| Critical vulnerabilities | 2 | 0 |
| High vulnerabilities | 12 | 0 |
| Moderate vulnerabilities | 67 | 8 |
| Low vulnerabilities | 2 | 0 |
| Total vulnerabilities | 83 | 8 |

## Actions Taken

- Removed unused production dependencies: `@genkit-ai/ai`, `@genkit-ai/core`, `@genkit-ai/dotprompt`, `@genkit-ai/flow`, `genkit-ai`, and `openai`.
- Updated compatible packages through `npm audit fix` without `--force`.
- Aligned Node typings with Node 20 using `@types/node@20`.
- Added an `esbuild` override to `0.28.1`, removing the low-severity dev-server file-read advisory.
- Kept `firebase-admin` on the current major version because npm recommends a breaking remediation path for the remaining moderate vulnerabilities.

## Critical And High Findings

No critical or high vulnerabilities remain after remediation.

Initial critical/high paths included:

| Package | Initial Severity | Path | Production or Dev | Action |
| --- | --- | --- | --- | --- |
| `protobufjs` | Critical | Transitive through removed Genkit/OpenTelemetry-related dependencies and Google packages | Production/transitive | Removed unused Genkit packages and applied compatible audit fixes. |
| `vitest` | Critical | Dev dependency | Development | Updated by compatible `npm audit fix`. |
| `axios` | High | Direct production dependency | Production | Updated by compatible `npm audit fix`. |
| `@grpc/grpc-js` | High | Transitive dependency | Production/transitive | Updated by compatible `npm audit fix`. |
| `@opentelemetry/auto-instrumentations-node` | High | Genkit-related transitive dependency | Production/transitive, unused by code | Removed unused Genkit packages. |
| `fast-uri`, `fast-xml-builder`, `form-data`, `vite`, `ws` | High | Transitive dependencies | Mixed production/dev | Updated or removed through dependency cleanup and compatible audit fix. |

## Residual Moderate Vulnerabilities

The remaining findings are all moderate and centered on `uuid <11.1.1` through Firebase Admin transitive paths:

| Package | Chain | Production or Dev | Risk Assessment | Action Taken | Reason Deferred |
| --- | --- | --- | --- | --- | --- |
| `uuid` | `firebase-admin` -> `@google-cloud/firestore` -> `google-gax` -> `uuid` | Production/transitive | Moderate. Affects v3/v5/v6 buffer usage paths in transitive Google SDK dependencies. | Compatible fixes applied where possible. | npm recommends a breaking `firebase-admin` major change. |
| `uuid` | `firebase-admin` -> `@google-cloud/storage` -> `teeny-request` -> `uuid` | Production/transitive | Moderate. Same transitive SDK family. | Compatible fixes applied where possible. | Requires major Firebase Admin remediation path according to npm. |
| `retry-request` / `teeny-request` | `firebase-admin` -> `@google-cloud/storage` | Production/transitive | Moderate, inherited through Google Cloud Storage SDK. | No forced update. | Requires Firebase Admin major upgrade validation. |
| `google-gax` / `gaxios` | `firebase-admin` -> `@google-cloud/firestore` | Production/transitive | Moderate, inherited through Firestore SDK. | No forced update. | Requires Firebase Admin major upgrade validation. |

## Deferred Decision

Do not run `npm audit fix --force` in this phase. The remaining remediation requires a Firebase Admin major-version decision and should be handled in a follow-up with:

- changelog review for `firebase-admin` and `firebase-functions` compatibility;
- emulator-backed regression tests;
- deployment dry-run review;
- staging Functions validation before production.
