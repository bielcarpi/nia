# ADR 0002: Direct WebRTC with server-issued client secrets

- Status: accepted
- Date: 2026-07-16

## Context

Realtime spoken tutoring is sensitive to latency and jitter. Relaying audio
through Nia's API would add another network hop, duplicate media handling, and
increase the amount of sensitive data under Nia's control. Embedding a standard
provider API key in a mobile or web binary is not acceptable.

## Decision

The authenticated client asks the Go API to start a session. The API applies
tutor policy and uses its server-side provider key to mint a short-lived client
secret. The client uses that credential to negotiate WebRTC directly with the
OpenAI Realtime API.

Only final text turns are written back to Nia's API. Provider secrets,
authorization headers, and raw audio are neither logged nor persisted.

## Consequences

- Audio takes the shortest supported path and the API does not become a media
  relay bottleneck.
- The client must implement WebRTC and provider data-channel event handling.
- The API still owns usage controls at session issuance time, but provider-side
  usage reconciliation is needed for precise cost accounting.
- A compromised short-lived secret has a much smaller useful lifetime than a
  standard API key, but clients must still treat it as sensitive memory.
