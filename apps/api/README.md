# Nia API

The Nia API is the product's control plane. It authenticates learners, supplies
the initial tutor settings, mints short-lived Realtime credentials, stores final
text turns, and generates a structured session review. It never proxies or
stores raw audio. Because the client holds the direct Realtime connection, those
initial provider settings are not an immutable authorization boundary.

## Package boundaries

```text
cmd/api                 process lifecycle and graceful shutdown
internal/app            dependency composition
internal/auth           demo and Firebase ID token/App Check verification
internal/config         typed, fail-closed environment configuration
internal/domain         data contracts and the three external ports
internal/httpapi        REST handlers and HTTP policy
internal/provider       deterministic and OpenAI adapters
internal/service        use cases, rate limits, and feedback orchestration
internal/store          memory and Firestore persistence
```

The domain exposes only three infrastructure interfaces:
`ConversationStore`, `RealtimeSessionIssuer`, and `FeedbackGenerator`. The
concrete Firebase, Firestore, and OpenAI types stay at the application edge.

Firestore uses transactional leases to serialize feedback generation across API
instances. Deletion takes a mutually exclusive marker before removing turns, so
a failed recursive delete cannot reopen an incomplete conversation.
Transcript writes are capped at 200 turns during the first two hours of a
conversation. The service also applies an instance-local per-user write window;
strict fleet-wide spend control still belongs in a shared quota or provider
budget.

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
make lint-go test-go test-go-firestore vuln-go
```

`test-go-firestore` starts the local Firestore emulator and exercises ownership,
pagination, idempotent turn writes, completion/deletion races, and cleanup.

The full HTTP contract is in [`../../contracts/openapi.yaml`](../../contracts/openapi.yaml).
