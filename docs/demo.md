# Five-minute demo

The demo is intentionally credential-free. It proves application behavior and
boundaries with deterministic adapters; it does not claim that a live OpenAI or
Firebase deployment is running.

## Start the stack

```bash
make bootstrap
```

Terminal one:

```bash
make dev-api
```

Terminal two:

```bash
make dev-mobile
```

The web app opens in Chrome. If port `8080` or the selected Flutter development
port is occupied, stop the conflicting process or override the documented local
address.

## Product walkthrough

1. Show that the app is visibly in Demo mode; no real identity or provider call
   should be ambiguous.
2. Choose a target language, level, practice topic, and correction style.
3. Start a conversation and follow the scripted realtime exchange.
4. Point out that the interaction UI receives incremental events while only
   final text turns become durable application records.
5. End the session and review the deterministic strengths, corrections, and
   next steps.
6. Open history, revisit the detail, and delete it.

That flow exercises the same domain and HTTP boundaries production adapters use.
It does not exercise WebRTC networking, Firebase token validation, provider
latency, billing, or Firestore durability; those require the integration setup
in [`development.md`](development.md).

## API walkthrough

The fixed token below is accepted only by the API's explicit local/demo
configuration. It is not a production token and production mode rejects it.

```bash
export NIA_DEMO_AUTH="Authorization: Bearer nia-local-demo"

curl --fail-with-body http://localhost:8080/healthz

SESSION="$(curl --fail-with-body --silent \
  -H "$NIA_DEMO_AUTH" \
  -H 'Content-Type: application/json' \
  --data '{
    "preferences": {
      "target_language": "es",
      "level": "intermediate",
      "topic": "Ordering dinner at a restaurant",
      "correction_style": "summary"
    }
  }' \
  http://localhost:8080/api/v1/realtime/sessions)"

printf '%s\n' "$SESSION" | jq
export CONVERSATION_ID="$(printf '%s' "$SESSION" | jq -r .conversation.id)"
```

In demo mode, `client_secret` is `null` and `realtime.transport` is `demo`. A
production response uses `webrtc` and includes a short-lived secret.

Persist two final turns with stable client IDs:

```bash
curl --fail-with-body \
  -X PUT \
  -H "$NIA_DEMO_AUTH" \
  -H 'Content-Type: application/json' \
  --data '{
    "role": "user",
    "text": "Quiero una mesa para dos, por favor.",
    "occurred_at": "2026-07-16T09:00:00Z"
  }' \
  "http://localhost:8080/api/v1/conversations/${CONVERSATION_ID}/turns/turn_demo_0001"

curl --fail-with-body \
  -X PUT \
  -H "$NIA_DEMO_AUTH" \
  -H 'Content-Type: application/json' \
  --data '{
    "role": "assistant",
    "text": "Claro. ¿A qué hora desean cenar?",
    "occurred_at": "2026-07-16T09:00:02Z"
  }' \
  "http://localhost:8080/api/v1/conversations/${CONVERSATION_ID}/turns/turn_demo_0002"
```

Repeat either `PUT`: the turn is replaced, not duplicated. Then complete, list,
and delete the conversation. Completion requires at least one persisted
learner/user turn; an assistant greeting alone returns `409` and does not spend
feedback-generation quota:

```bash
curl --fail-with-body \
  -X POST \
  -H "$NIA_DEMO_AUTH" \
  "http://localhost:8080/api/v1/conversations/${CONVERSATION_ID}/complete" | jq

curl --fail-with-body \
  -H "$NIA_DEMO_AUTH" \
  'http://localhost:8080/api/v1/conversations?limit=20' | jq

curl --fail-with-body \
  -X DELETE \
  -H "$NIA_DEMO_AUTH" \
  "http://localhost:8080/api/v1/conversations/${CONVERSATION_ID}"
```

## What to inspect in the code

- `apps/api/internal`: domain boundaries, adapters, middleware, and tests;
- `apps/mobile/lib`: injected demo/production services and UI state;
- `contracts/openapi.yaml`: exact public behavior and typed failures;
- `infra/terraform`: least-privilege bootstrap and Cloud Run runtime; and
- `.github/workflows`: reproducible quality and security checks.

Finish with `make check`. A green local run is useful evidence; repository badges
reflect GitHub's own run state only after the changes land on GitHub.
