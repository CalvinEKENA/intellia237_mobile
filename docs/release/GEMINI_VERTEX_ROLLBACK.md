# Gemini Vertex AI rollback procedure

This runbook applies to the server-side migration of `askTutor`, `generateQuiz`
and `generateSummary` from GLM/Z.ai to Gemini 3.8 Flash on Vertex AI.

## Current architecture

- provider: Vertex AI REST `generateContent`;
- model: `gemini-3.8-flash`;
- location: `global`;
- authentication: Application Default Credentials from the Functions runtime;
- tutor thinking: `LOW`;
- quiz and summary thinking: `MEDIUM`;
- no API key is embedded in Flutter or required by the Functions code.

## Record the deployed baseline

Before every deployment, record in the change ticket:

- Git commit SHA and CI run URL;
- Firebase project and function region;
- deployed Cloud Functions update time;
- Cloud Run revision receiving 100% traffic for each affected gen2 function;
- model, location and configured provider timeout.

Useful read-only commands, with placeholders replaced explicitly:

```text
gcloud functions describe FUNCTION --gen2 --region europe-west1 --project PROJECT_ID
gcloud run revisions list --service FUNCTION --region europe-west1 --project PROJECT_ID
gcloud run services describe FUNCTION --region europe-west1 --project PROJECT_ID
```

Never infer the rollback target from “latest”. Record the exact revision name.

## Failure signals

Investigate or roll back when a sustained change appears in structured
`ai_request` logs:

- latency or timeout rate exceeds the release threshold;
- HTTP `4xx` indicates IAM/project/model configuration errors;
- HTTP `5xx` or `unavailable` errors exceed the incident threshold;
- `responseParsingFailure` rises above zero outside isolated malformed outputs;
- token or thinking-token consumption departs materially from the release
  budget;
- quota rejections rise without a matching legitimate-traffic increase;
- callable error rate or user-visible tutor/quiz/summary failures regress.

Logs must be filtered by `operation`, `model`, `correlationId`, success status
and deployed revision. Do not inspect or add complete prompts or Gemini answers.

## Rollback decision

1. Pause further rollouts. Do not change production Firebase data.
2. Confirm whether the defect is code, IAM/ADC, model availability, quota, or
   App Check enforcement.
3. Prefer a configuration correction only when the desired project, location
   and IAM role are already documented and approved.
4. Otherwise roll back only the three affected AI Functions to an explicitly
   recorded known-good revision.

For a gen2 traffic rollback:

```text
gcloud run services update-traffic FUNCTION --to-revisions KNOWN_GOOD_REVISION=100 --region europe-west1 --project PROJECT_ID
```

Apply the command separately to `askTutor`, `generateQuiz` and
`generateSummary`, then verify the traffic split. If Firebase-managed service
configuration prevents a durable traffic rollback, redeploy an audited,
known-good **Vertex-based** Git revision:

```text
git switch --detach KNOWN_GOOD_VERTEX_SHA
npm --prefix functions ci
npm --prefix functions test
npm --prefix functions run build
firebase deploy --only functions:askTutor,functions:generateQuiz,functions:generateSummary --project PROJECT_ALIAS
```

These commands are incident instructions only. This hardening change performs
no deployment.

## Special case: first Vertex production deployment

The revision immediately preceding the first Vertex deployment may contain the
legacy GLM/Z.ai implementation. Do not restore its API key or other legacy
credentials. If traffic must be returned to that revision, verify first that
all GLM/Z.ai credentials remain absent; the AI endpoints may fail closed while
the incident is resolved, but they must not resume contacting the legacy
provider accidentally.

## Verification after rollback

1. Confirm 100% traffic targets the recorded revision.
2. Run authenticated smoke tests for all three AI operations with non-sensitive
   staging fixtures first, then the approved production health check.
3. Confirm quota reservations are consumed on success and released on failure.
4. Confirm structured logs contain the expected revision/provider/model and no
   prompt, course content, Authorization header or token.
5. Monitor latency, failure rate and token usage for the incident window.
6. Record the final revision, timestamps, operator and evidence in the incident
   ticket.

## Never do this

- never restore a GLM/Z.ai secret as a shortcut;
- never commit ADC files, service-account keys or debug tokens;
- never point staging at `edunova-aabd1` to reproduce a failure;
- never disable Firebase security rules to make an AI request pass;
- never force-push or rewrite the release history during an incident;
- never log raw prompts, course content, personal data or Gemini responses.
