# App Check Rollout Plan

App Check enforcement is intentionally not enabled in Phase 2A. The server-authoritative rules and callables are safe without relying on attestation, and enforcement should wait for client coverage telemetry.

## Rollout Stages

1. Register app platforms in Firebase App Check for Android, iOS, and Web if needed.
2. Ship client SDK initialization in monitor mode.
3. Observe callable, Firestore, and Storage request coverage for at least one release window.
4. Fix unsupported platform or debug-token gaps.
5. Enforce App Check on callable Functions first.
6. Enforce App Check on Firestore and Storage after no critical clients are missing attestation.

## Phase 2A Non-Goals

- No production enforcement.
- No Firebase project setting changes.
- No deploy.
- No debug token committed to source control.

## Readiness Checks

- Valid attestation rate by platform.
- Error rate after monitor-mode release.
- Rollback plan for enforcement toggles.
- Support path for testers and CI emulator flows.
