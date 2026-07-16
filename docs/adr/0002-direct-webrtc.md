# ADR 0002: Send realtime audio directly over WebRTC

- Status: accepted
- Date: 2026-07-16

## Constraint

Spoken practice needs low latency, but a standard OpenAI API key cannot be
embedded in a mobile or web build. Nia also should not collect raw audio merely
to forward it to the model provider.

## Alternatives

- **Relay audio through the Go API.** This would centralize transport control,
  but adds a network hop, a media-processing workload, and more sensitive data
  in Nia's infrastructure.
- **Call OpenAI from the app with a standard key.** This is simpler and was
  rejected because a client binary cannot protect a long-lived server key.
- **Issue a short-lived client secret and connect directly.** The API retains
  identity, issuance limits, and persistence while the provider carries the
  media.

## Decision

The authenticated app asks the Go API to start a conversation. The API supplies
the initial tutor settings and returns a short-lived Realtime client secret. The
app then negotiates WebRTC with OpenAI and writes only final text turns back to
Nia.

The [OpenAI WebRTC guide](https://developers.openai.com/api/docs/guides/realtime-webrtc)
allows the connected client to update the session. A modified client holding a
valid ephemeral secret can therefore override the initial provider settings.
Authentication, secret issuance, transcript bounds, ownership, and persistence
remain server-enforced. If tutor instructions must be immutable, the connection
must move behind a mediated or server-controlled path.

The implementation is visible in the Flutter
[`realtime_client.dart`](../../apps/mobile/lib/realtime/realtime_client.dart),
the Go [`openai/client.go`](../../apps/api/internal/provider/openai/client.go),
and the session response in the
[`OpenAPI contract`](../../contracts/openapi.yaml).

## What remains imperfect

- Usage can be limited when a session is issued, but precise cost accounting
  still needs provider-side reconciliation.
- The Flutter app must handle peer connection, data-channel, and reconnect
  behavior across three platforms.
- A short-lived secret is still sensitive while valid and must not be logged or
  persisted.
- Initial tutor configuration is product behavior, not an authorization
  boundary, while the client owns the direct session.

Revisit the relay choice only if product requirements need server-side media
processing, recording with explicit consent, or transport controls the direct
provider connection cannot supply.
