# ADR 0003: Run one stateless API on Cloud Run

- Status: accepted
- Date: 2026-07-16

## Workload

The backend handles short authenticated HTTP requests: verify identity, create a
provider session, write final text turns, generate feedback, list history, and
delete a conversation. Audio is not part of this service, and there is no
long-running background job today.

## Choice

Deploy one Go service on Cloud Run and store preferences, conversation text, and
feedback in Firestore. Firebase Authentication supplies identity. A dedicated
runtime service account can access Firestore and one Secret Manager secret.

The service stays stateless: durable data crosses the store interface in
[`domain/model.go`](../../apps/api/internal/domain/model.go), and the production
shape is captured in [`infra/terraform`](../../infra/terraform).

## Why not the larger options

- Kubernetes would introduce a cluster and scheduler for one HTTP container.
- Separate session, transcript, and feedback services would add network and
  deployment boundaries without independent scaling evidence.
- Direct client access to Firestore would duplicate authorization rules outside
  the Go API and expose product query shapes to every client release.

## Operational consequences

- Cloud Run can scale to zero; cold-start latency must be measured before paying
  for minimum instances.
- Firestore indexes follow actual query shapes and remain deployment artifacts.
- Old and new Cloud Run revisions share data, so schema changes must remain
  backward compatible through the rollback window.
- A future asynchronous workload may justify a queue or worker, but no such
  deployment unit exists until that workload appears.
