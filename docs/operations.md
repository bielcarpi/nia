# Operations

Nia is designed to have a small operational surface: one Cloud Run revision,
one Firestore database, Firebase Authentication, one runtime service account,
and one Secret Manager secret.

## Probe semantics

- `GET /healthz` reports process liveness and never calls a dependency. A failed
  liveness probe is a reason to restart an instance.
- `GET /readyz` reports whether the instance can accept application traffic. A
  successful check gates startup and supports deploy smoke tests. The checked-in
  Cloud Run stack does not configure a separate continuous readiness-removal
  mechanism; handlers still fail closed when a required dependency is down.

Cloud Run sends `SIGTERM` before instance termination. The Go server should
stop accepting new requests, allow bounded in-flight requests to finish, and
exit before the platform deadline.

## Service-level objectives

These are starting targets for a real deployment, not measured claims:

| Signal | Initial target | Measurement notes |
| --- | --- | --- |
| API availability | 99.9% successful eligible requests over 28 days | Exclude client `4xx`; include `5xx` and deadline failures |
| Session issuance latency | p95 under 1.5 seconds | From API ingress through provider client-secret response |
| Transcript write latency | p95 under 400 ms | Measured at API handler, including Firestore |
| Feedback completion | 99% within 20 seconds | Track provider timeout and invalid structured output separately |
| Deletion success | 99.9% within 5 seconds | Verify transcript and feedback no longer read back |

Set objectives from observed traffic and product expectations before attaching
an error-budget policy.

## Structured logging

Logs should be JSON on stdout with a stable field allowlist:

- severity, timestamp, service, version, environment;
- request ID, route template, method, status, duration;
- hashed or non-reversible actor correlation where justified;
- conversation ID only when operationally necessary;
- provider name, provider request ID, and provider duration; and
- error code, never a raw provider response or request body.

Do not log authorization headers, Firebase tokens, Realtime client secrets,
standard provider keys, transcript content, audio, or arbitrary model output.

## Dashboards and alerts

The service Terraform installs two deliberately simple starting policies:

- more than five Cloud Run container-level `5xx` responses in five minutes;
- successful-response p95 Cloud Run latency above 10 seconds for five minutes.

Both values are variables, not measured claims. Existing notification channels
are composed in by resource name; an empty list leaves incidents visible in
Cloud Monitoring without pretending that anyone will be paged. Validate the
filters against live time series and tune them after traffic is representative.

Use the native Cloud Run metrics view first. Add a shared dashboard when a real
deployment exists, covering request rate, status by route, latency percentiles,
instance count, cold starts, Firestore latency/errors, provider latency/errors,
session issuance by identity bucket, and feedback outcomes.

Page an operator for user-impacting conditions:

- sustained availability burn across fast and slow windows;
- session issuance or feedback error rate above the error budget;
- no ready Cloud Run instances while traffic is present;
- Firestore permission/quota failures; or
- provider spend or session volume exceeding a configured threshold.

Use tickets rather than pages for dependency update failures, slow capacity
trends, and isolated client validation errors.

## Runbooks

### Session issuance is failing

1. Group `5xx` by API error code and revision.
2. Compare provider failures with Firebase verification and Firestore failures.
3. Correlate a request ID to the provider request ID without inspecting content.
4. Check secret version availability and runtime service-account access.
5. Roll back if the issue began with a revision; otherwise disable session
   creation gracefully and preserve conversation history access.

### Feedback completion is failing

1. Confirm transcript writes still succeed.
2. Separate provider timeout, provider rejection, parse/validation failure, and
   persistence failure metrics.
3. Retry only idempotent completions with backoff; do not loop unboundedly.
4. Keep the conversation recoverable and communicate that feedback is pending.

### Firestore errors are rising

1. Check quota, service health, IAM changes, and missing-index errors.
2. Verify the runtime service account and project IDs on the active revision.
3. Stop session creation if new conversations cannot be stored reliably.
4. Do not fall back to instance memory in production.

### Suspected credential exposure

1. Revoke or rotate the affected credential immediately.
2. Identify access through Secret Manager audit logs and provider usage data.
3. Deploy or restart consumers if they cache the old value.
4. Preserve non-secret evidence, assess impact, and follow the private process in
   [`SECURITY.md`](../SECURITY.md).

## Deploy and rollback

Cloud Run creates immutable revisions. Deploy the new image without sending all
traffic first when risk warrants it, smoke-test its probes and one authenticated
flow, then migrate traffic. Rollback points traffic to the last known-good
revision; it does not roll back Firestore data.

Any data-model change must therefore be backward compatible across the old and
new revisions for the rollout window. Destructive migrations require their own
backup, verification, and rollback plan.
