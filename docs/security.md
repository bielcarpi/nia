# Security model

This document describes the intended production boundary and the remaining
deployment responsibilities. Demo mode is for local review only and is not an
authentication substitute.

## Trust boundaries

1. The Flutter binary and browser are untrusted clients. UI state, identifiers,
   transcript payloads, and preferences are validated by the API.
2. Firebase Authentication proves identity. The API verifies issuer, audience,
   signature, and expiry before using the Firebase UID as an authorization key.
   Production requests also present an App Check token in
   `X-Firebase-AppCheck`; the two checks serve different purposes.
3. The Go API is the product trust boundary. It decides conversation ownership,
   applies limits, constructs provider policy, and controls persistence.
4. OpenAI and Google Cloud are external processors. Send only the data required
   for the tutoring interaction and configure their retention and regional
   settings for the deployment's obligations.
5. GitHub Actions is a build system, not a production secret store by default.
   A future deploy workflow should use short-lived Workload Identity Federation
   instead of a service-account key.

## Threats and controls

| Threat | Primary controls | Residual responsibility |
| --- | --- | --- |
| Stolen Firebase ID token | TLS, short token lifetime, server verification, least-privilege API | Protect device/session and configure Firebase account protections |
| Cross-user record access | Derive a hashed storage owner key from the verified UID; never trust an owner field; return `404` for non-owned IDs | Authorization regression tests and Firestore data review |
| Standard OpenAI key extracted from app | Key exists only in Secret Manager and Cloud Run memory; client receives an ephemeral secret | Rotate keys and audit secret access |
| Realtime session abuse or cost spike | Authenticated issuance, per-instance user windows, bounded concurrency and session policy | Shared quotas when strict enforcement is needed, provider budgets, alerts, edge controls |
| Prompt manipulation | Server-owned tutor instructions and bounded preference fields | Treat all model output as untrusted content |
| Replay/duplicate writes | Client turn ID plus idempotent `PUT`; owned conversation lookup | Preserve idempotency semantics across store adapters |
| Sensitive content in logs | Structured metadata allowlist; no bodies, transcripts, secrets, or auth headers | Review sinks, sampling, access, and retention |
| Direct Firestore access | Production Firestore rules deny client reads and writes; API uses its service identity | Deploy and test rules with the intended Firebase project |
| Malicious dependency or image | Locked dependencies, Dependabot, CodeQL, `govulncheck`, Trivy filesystem and image scans | Review updates and maintain patch cadence |
| Accidental public demo configuration | Explicit runtime mode; production validation fails closed | Set and verify deployment variables before traffic migration |

## Secret lifecycle

- Secret Manager owns the standard OpenAI API key. Terraform creates the secret
  container but deliberately does not place secret material in state.
- Add secret versions through an input method that avoids shell history. Never
  use `-var openai_api_key=...`, commit a `.tfvars` secret, or put credentials in
  a Docker build argument.
- The Cloud Run runtime service account receives
  `roles/secretmanager.secretAccessor` only on that secret.
- Realtime client secrets are returned only to the authenticated caller,
  marked sensitive in the API contract, never persisted, and never logged.
- Rotation is an operational procedure, not a source-code change. Add a new
  numeric secret version, update the service stack to reference it, deploy and
  verify, then disable the old version after the rollback window.

## Data minimization and deletion

Nia's application data is text preferences, transcript turns, and generated
feedback. Raw audio is outside the Nia API data path. The API exposes an owned
conversation deletion endpoint that removes its transcript and feedback.

A production operator must still define and publish:

- a privacy notice and lawful basis appropriate to its users and regions;
- Firestore, Cloud Logging, Firebase Authentication, and provider retention;
- account-level export and deletion behavior;
- age restrictions and parental-consent rules, if applicable; and
- incident notification and processor agreements.

This repository is an engineering reference, not evidence that those product
and legal obligations have been completed.

## HTTP and platform hardening

- Terminate TLS at Cloud Run and do not expose an HTTP production endpoint.
- Allow only exact production origins. CORS is a browser control, not
  authentication; native apps do not enforce it.
- Bound request-body size, header size, server timeouts, and provider deadlines.
- Return typed, non-sensitive errors with a request ID. Do not forward provider
  response bodies to clients.
- Keep the API image minimal and non-root. Do not ship a shell, package manager,
  source tree, or build credentials in the runtime layer.
- Use a dedicated runtime service account and avoid project Editor/Owner roles.

## Before public production traffic

- Enable Firebase App Check verification or place an equivalent attestation
  control in front of expensive session issuance.
- Configure provider/project budgets and alerts.
- Run authorization tests against the Firebase/Firestore emulator suite.
- Confirm Cloud Logging sinks, retention, and access controls.
- Establish restore/export and account-erasure tests.
- Configure a custom domain, exact CORS origins, and abuse controls.
- Perform an independent threat-model and privacy review.
