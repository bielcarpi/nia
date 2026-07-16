# Nia API

The Nia API is the product's control plane. It authenticates learners, owns the
tutor policy, mints short-lived Realtime credentials, stores final text turns,
and generates a structured session review. It never proxies or stores raw audio.

## Package boundaries

```text
cmd/api                 process lifecycle and graceful shutdown
internal/app            dependency composition
internal/auth           demo and Firebase ID token/App Check verification
internal/config         typed, fail-closed environment configuration
internal/domain         data contracts and the three external ports
internal/httpapi        REST handlers and HTTP policy
internal/provider       deterministic and OpenAI adapters
internal/service        use cases and per-user guardrails
internal/store          memory and Firestore adapters
```

The domain exposes only three infrastructure interfaces:
`ConversationStore`, `RealtimeSessionIssuer`, and `FeedbackGenerator`. The
concrete Firebase, Firestore, and OpenAI types stay at the application edge.

## Local demo

From the repository root:

```bash
make dev-api
```

The local demo accepts the exact bearer token `nia-local-demo`. That verifier is
only constructible in the explicit local/demo configuration; production config
requires Firebase authentication, App Check, Firestore, OpenAI, HTTPS browser
origins, and the official OpenAI API base URL.

Run the backend quality gates with:

```bash
make lint-go test-go vuln-go
```

The full HTTP contract is in [`../../contracts/openapi.yaml`](../../contracts/openapi.yaml).
