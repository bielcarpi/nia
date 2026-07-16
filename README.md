<p align="center">
  <img src="apps/mobile/assets/images/logo/nia.png" alt="Nia" width="132">
</p>

<h1 align="center">Nia</h1>

<p align="center">
  A voice-first AI language tutor, rebuilt as a security-conscious Flutter + Go reference application.
</p>

<p align="center">
  <a href="https://github.com/bielcarpi/nia/actions/workflows/ci.yml"><img alt="CI" src="https://github.com/bielcarpi/nia/actions/workflows/ci.yml/badge.svg"></a>
  <a href="https://github.com/bielcarpi/nia/actions/workflows/codeql.yml"><img alt="CodeQL" src="https://github.com/bielcarpi/nia/actions/workflows/codeql.yml/badge.svg"></a>
  <img alt="Flutter" src="https://img.shields.io/badge/client-Flutter-02569B?logo=flutter&logoColor=white">
  <img alt="Go" src="https://img.shields.io/badge/API-Go-00ADD8?logo=go&logoColor=white">
  <img alt="Cloud Run" src="https://img.shields.io/badge/runtime-Cloud%20Run-4285F4?logo=googlecloud&logoColor=white">
</p>

Nia gives a learner a low-latency spoken practice session, keeps tutor policy
and provider credentials on the server, saves final text turns, and produces a
structured review with strengths, corrections, and next steps.

The repository is designed to be useful in two ways:

- **Clone-and-run demo:** review the complete product flow without Firebase,
  OpenAI credentials, or a cloud account.
- **Production-shaped reference:** replace deterministic adapters with Firebase
  Authentication, Firestore, OpenAI Realtime/Responses, and a least-privilege
  Cloud Run deployment.

No public production service is claimed here. Demo responses are clearly marked
and production configuration fails closed when its required security settings
are missing.

## What this showcases

- Direct mobile/web-to-OpenAI WebRTC audio using a short-lived client secret;
  the standard provider key never ships in the app.
- A small, idiomatic Go control plane with typed configuration, narrow provider
  interfaces, graceful shutdown, structured logs, request correlation, bounded
  provider calls, and ownership-first HTTP handlers.
- Idempotent transcript writes, cursor pagination, structured post-session
  feedback, conversation deletion, and no raw-audio persistence.
- Firebase ID-token and App Check verification in production, with a fixed demo
  identity accepted only by explicit local configuration.
- Contract-first HTTP behavior in a linted OpenAPI 3.1 description.
- A non-root multi-stage API image, Cloud Run probes and autoscaling limits,
  server-only Firestore access, and a Secret Manager integration that keeps
  secret material out of Terraform state.
- CI gates for formatting, analysis, race-enabled Go tests, Flutter tests and web
  build, `govulncheck`, CodeQL, Terraform validation, OpenAPI linting, and Trivy
  repository/image scans.

## Architecture

```mermaid
flowchart LR
    App["Flutter app"] -->|"ID token + App Check"| API["Go API · Cloud Run"]
    API --> Auth["Firebase Auth"]
    API --> DB["Firestore"]
    API -->|"mint ephemeral secret"| RT["OpenAI Realtime"]
    App <-->|"WebRTC audio + events"| RT
    API -->|"post-session review"| Responses["OpenAI Responses"]
```

The API is a control plane, not a media relay. Audio takes the shortest
supported path while identity, tutor instructions, limits, transcript storage,
feedback, and deletion stay behind the server authorization boundary.

[Read the architecture and request flows →](docs/architecture.md)

## Try it without credentials

Prerequisites are a current stable Flutter SDK and a Go toolchain compatible
with `apps/api/go.mod`.

```bash
git clone https://github.com/bielcarpi/nia.git
cd nia
make bootstrap
```

Run the API in one terminal:

```bash
make dev-api
```

Run the Flutter web demo in another:

```bash
make dev-mobile
```

The API demo accepts `Authorization: Bearer nia-local-demo` only while its
explicit local/demo adapters are active. The Flutter demo uses deterministic
realtime events so a reviewer can exercise the UI without an OpenAI key.

For a five-minute API and product walkthrough, use
[`docs/demo.md`](docs/demo.md). For emulator and production-adapter setup, see
[`docs/development.md`](docs/development.md).

## Repository map

```text
apps/
  api/                  Go control-plane API and production adapters
  mobile/               Flutter app for iOS, Android, and Web
contracts/
  openapi.yaml          Public HTTP contract
docs/
  adr/                   Architecture decision records
  architecture.md       Boundaries, flows, data, and scaling model
  development.md        Local demo and cloud-adapter development
  deployment.md         Two-stage Google Cloud deployment
  operations.md         Probes, SLO candidates, alerts, and runbooks
  security.md           Threat model and production checklist
infra/
  firebase/             Deny-by-default client rules and emulator config
  terraform/bootstrap/  APIs, image registry, runtime identity, secret shell
  terraform/service/    Cloud Run service, probes, limits, secret injection
```

## API surface

| Endpoint | Purpose |
| --- | --- |
| `GET /healthz` / `GET /readyz` | Liveness and dependency readiness |
| `GET/PATCH /api/v1/me/preferences` | Learner defaults |
| `POST /api/v1/realtime/sessions` | Owned conversation + ephemeral WebRTC bootstrap |
| `PUT /api/v1/conversations/{id}/turns/{turn_id}` | Idempotent final text turn |
| `POST /api/v1/conversations/{id}/complete` | Complete and generate structured feedback |
| `GET /api/v1/conversations` | Cursor-paginated history |
| `GET/DELETE /api/v1/conversations/{id}` | Detail and permanent deletion |

[`contracts/openapi.yaml`](contracts/openapi.yaml) is the reviewable source of
truth for payloads, errors, limits, and authentication.

## Quality gates

```bash
make format          # apply Go and Dart formatters
make check           # contract, infra, Go, Flutter, race, and vulnerability checks
make openapi-lint    # lint only the HTTP contract
make terraform-check # format and validate both Terraform stacks
```

GitHub Actions are pinned to immutable commit SHAs. Dependabot tracks Go, Dart,
Docker, Terraform, and Actions dependencies. CI builds the API runtime image and
fails on known high/critical fixed vulnerabilities.

## Deploying

The deployment is intentionally two-stage:

1. Terraform bootstrap enables required APIs, creates Artifact Registry, a
   dedicated runtime identity, and an empty Secret Manager secret container.
2. An operator adds the key as a secret version, builds an immutable image, and
   applies the Cloud Run service stack.

Terraform never receives the secret value. The detailed guide includes remote
state, IAM prerequisites, Firebase configuration, smoke tests, traffic rollout,
and rollback: [`docs/deployment.md`](docs/deployment.md).

## Project status and scope

This is a portfolio-quality reference implementation, not a claim of a
production-operated consumer service. Before public traffic, an operator still
needs to configure a real Firebase project, provider billing and budgets,
privacy/retention policy, App Check enforcement, alerting, custom domains, and
independent security review. Those gates are explicit in
[`docs/security.md`](docs/security.md).

The separate historical backend should be redirected and archived only after
credential rotation, consumer migration, and a final smoke test. The safe
sequence is documented in [`docs/legacy-backend-migration.md`](docs/legacy-backend-migration.md).

## Credits

Nia preserves the original repository history and recognizes the people who
built it, including [Biel Carpi](https://github.com/bielcarpi),
[Alex Cano Gallego](https://github.com/AlexCanoGallego), and
[Marc Geremias](https://github.com/marcgeremias). See the live
[contributors graph](https://github.com/bielcarpi/nia/graphs/contributors) for
the complete record. The backend rewrite does not erase that provenance.

## License

No open-source license is currently included. Rights across the historical
contributors must be confirmed before selecting one; until then, source
visibility does not grant permission to copy, modify, or redistribute the code.
