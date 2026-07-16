# Operations

Nia's deployed surface is one Cloud Run service, one Firestore database, one
runtime service account, Firebase Authentication, and one provider secret.

## Probes

- `GET /healthz` reports process liveness and does not call a dependency.
- `GET /readyz` performs a cheap persistence-readiness check. In production it
  reads Firestore. Terraform uses it as the Cloud Run startup probe; the
  authenticated deployment smoke flow separately proves Firebase verification,
  App Check, and OpenAI access.

The server handles `SIGTERM`, stops accepting new requests, and gives in-flight
requests a bounded drain window before exit.

## Signals already emitted

The API writes JSON logs to stdout. Every record includes `service`,
`environment`, and `version`. HTTP access records add `request_id`, method,
route template, status, and `duration_ms`. Failed requests also carry a public
error code, a coarse error class, and whether the client may retry. OpenAI
request records add operation, provider status, provider request ID, outcome,
and duration. Request bodies, internal error causes, tokens, transcript text,
audio, and model output are excluded.

The service Terraform defines two Cloud Run metric alerts:

- an absolute five-minute `5xx` burst, initially greater than five responses;
- successful-request p95 latency above 10 seconds for five minutes.

These are starting thresholds, not SLOs. Adjust
`server_error_alert_threshold_count` and `latency_alert_threshold_ms` after
observing real traffic.

`notification_channel_ids` is empty by default. The policies can open incidents
in Cloud Monitoring, but nobody is paged until an operator supplies existing
channel resource names.

## First deployment: establish the baseline

1. Deploy to a non-production project and run the authenticated smoke flow in
   [deployment.md](deployment.md).
2. Exercise session creation, several transcript writes, feedback completion,
   history, and deletion. Include one rejected token and one invalid request.
3. Confirm the access logs contain route templates rather than raw URLs and that
   provider logs contain identifiers and timing but no request content.
4. Open Metrics Explorer for the deployed Cloud Run service and confirm the
   `request_count` and `request_latencies` filters used in
   [`observability.tf`](../infra/terraform/service/observability.tf) return data.
5. Run enough representative sessions to see normal and slow provider calls.
   Tune the alert thresholds, attach a test notification channel, and trigger a
   controlled non-production incident before enabling real paging.

Do not set an availability target from this repository alone. Choose it after
observing traffic, provider behavior, and the support expectations for the
actual release.

Useful first SLIs are:

| Signal | Source | Question to answer from the baseline |
| --- | --- | --- |
| Eligible request success | Cloud Run request count; exclude expected client `4xx` | Which failures are user-impacting and under Nia's control? |
| API latency by operation | Access logs grouped by route template | Which endpoints need separate latency expectations? |
| Provider reliability | Provider outcome, status, request ID, and duration logs | How often do session issuance and feedback fail independently? |
| Transcript durability | Authenticated write followed by history/detail read | Does a successful write remain readable across revisions? |
| Deletion | Delete followed by an owned detail read | How quickly does application data become unavailable? |

## Concrete diagnostics

Set the deployed values once:

```bash
export PROJECT_ID="replace-with-gcp-project-id"
export REGION="europe-west1"
export SERVICE="nia-api"
```

Read recent server errors:

```bash
gcloud logging read \
  "resource.type=\"cloud_run_revision\" AND \
   resource.labels.service_name=\"${SERVICE}\" AND \
   jsonPayload.msg=\"http request\" AND jsonPayload.status>=500" \
  --project="$PROJECT_ID" \
  --limit=100 \
  --format=json
```

Trace one API request after copying its `X-Request-ID` response header:

```bash
export REQUEST_ID="replace-with-request-id"
gcloud logging read \
  "resource.type=\"cloud_run_revision\" AND \
   resource.labels.service_name=\"${SERVICE}\" AND \
   jsonPayload.request_id=\"${REQUEST_ID}\"" \
  --project="$PROJECT_ID" \
  --limit=50 \
  --format=json
```

Inspect failed provider calls without reading learner content:

```bash
gcloud logging read \
  "resource.type=\"cloud_run_revision\" AND \
   resource.labels.service_name=\"${SERVICE}\" AND \
   jsonPayload.msg=\"provider request\" AND \
   jsonPayload.outcome=\"error\"" \
  --project="$PROJECT_ID" \
  --limit=50 \
  --format='table(timestamp,jsonPayload.operation,jsonPayload.provider_status,jsonPayload.provider_request_id,jsonPayload.duration_ms)'
```

Use these signals when troubleshooting:

| Observation | Next action |
| --- | --- |
| Errors begin on one revision | Compare its configuration and image digest, smoke-test the previous revision, then follow the rollback procedure. |
| Provider failures rise while transcript writes remain healthy | Keep stored conversations recoverable, inspect provider status/request IDs, and avoid unbounded completion retries. |
| Readiness logs report a dependency failure | Check runtime Firestore IAM, Firestore service health, and the configured project and database before changing probes. |
| Firestore returns permission or index errors | Reconcile runtime IAM or the checked-in index definition; never fall back to instance memory in production. |
| A credential may have leaked | Rotate it immediately and follow [`SECURITY.md`](../SECURITY.md). |

## Rollout and data compatibility

Cloud Run revisions are immutable, but Firestore data is shared. Keep data-model
changes backward compatible across every revision in the rollback window.
Rolling traffic back does not reverse writes; destructive migrations need their
own export, verification, and recovery procedure.
