# Security model

This document describes the production trust boundary and the controls that a
deployment must supply. Demo authentication is local-only.

## Trust boundaries

1. The Flutter binary and browser are untrusted clients. UI state, identifiers,
   transcript payloads, and preferences are validated by the API.
2. Firebase Authentication proves identity. The API verifies issuer, audience,
   signature, and expiry before using the Firebase UID as an authorization key.
   Production requests also present an App Check token in
   `X-Firebase-AppCheck`; the two checks serve different purposes.
3. The Go API is the product trust boundary for identity, conversation
   ownership, issuance, transcript bounds, and persistence. It supplies initial
   Realtime settings but cannot make them immutable on a client-owned direct
   provider connection.
4. OpenAI and Google Cloud are external processors. Send only the data required
   for the tutoring interaction and configure their retention and regional
   settings for the deployment's obligations.
5. Releases are currently manual. Any automated deployment must use short-lived
   Workload Identity Federation instead of a service-account key.

## Threats and controls

| Threat | Primary controls | Residual responsibility |
| --- | --- | --- |
| Stolen Firebase ID token | TLS, short token lifetime, server verification, least-privilege API | Protect device/session and configure Firebase account protections |
| Cross-user record access | Derive a hashed storage owner key from the verified UID; never trust an owner field; return `404` for non-owned IDs | Authorization regression tests and Firestore data review |
| Standard OpenAI key extracted from app | Key exists only in Secret Manager and Cloud Run memory; client receives an ephemeral secret | Rotate keys and audit secret access |
| Realtime session abuse or cost spike | Authenticated issuance, atomic 200-turn and two-hour conversation bounds, per-instance user windows, bounded concurrency | Shared quotas when strict enforcement is needed, provider budgets, alerts, edge controls |
| Prompt or session manipulation | Bounded preferences and server-supplied initial instructions | A valid direct client can update its provider session; immutable policy requires mediation; treat model output as untrusted |
| Replay/duplicate writes | Client turn ID plus idempotent `PUT`; atomic completion and deletion leases | Preserve idempotency and lease semantics across store adapters |
| Sensitive content in logs | Structured metadata allowlist; no bodies, transcripts, secrets, or auth headers | Review sinks, sampling, access, and retention |
| Direct Firestore access | Production Firestore rules deny client reads and writes; API uses its service identity | Deploy and test rules with the intended Firebase project |
| Malicious dependency or image | Locked dependencies, Dependabot, CodeQL, `govulncheck`, Trivy filesystem and image scans | Review updates and maintain patch cadence |
| Accidental public demo configuration | Explicit runtime mode; production validation fails closed | Set and verify deployment variables before traffic migration |

## Secret lifecycle

- Secret Manager owns the standard OpenAI API key. Terraform creates the secret
  container without placing secret material in state.
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
conversation deletion endpoint that hides the record as soon as deletion starts
and removes its transcript and feedback. A durable marker keeps partial cleanup
private and retryable.

Before launch, publish a privacy policy and define data retention and deletion,
age requirements, and incident response.

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
