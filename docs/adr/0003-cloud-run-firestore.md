# ADR 0003: One stateless Cloud Run API with Firestore

- Status: accepted
- Date: 2026-07-16

## Context

Nia needs authenticated HTTP endpoints, short provider calls, durable
conversation text, and automatic scale-to-zero behavior. It does not need a
cluster scheduler or a fleet of independently deployed services.

## Decision

Deploy one stateless Go HTTP service on Cloud Run and store user preferences,
conversation text, and feedback in Firestore. Use Firebase Authentication as
the user identity source. Keep provider and store boundaries as Go interfaces
so tests do not depend on cloud services.

Provision the production runtime with Terraform. Store the OpenAI key in Secret
Manager and grant the Cloud Run service account access to that secret only.

## Consequences

- Operations stay small: one image, one service, one database, one secret, and
  one identity provider.
- Horizontal scaling is natural because no request depends on instance memory.
- Firestore query shapes must be designed and indexed explicitly.
- Cloud Run cold starts exist; minimum instances can be raised after latency and
  cost measurements justify it.
- A future long-running or asynchronous workload may need a queue, but that
  decision is deferred until the workload exists.
