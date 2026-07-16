<p align="center">
  <img src="apps/mobile/assets/images/logo/nia-mark.png" alt="Nia" width="132">
</p>

<h1 align="center">Nia</h1>

<p align="center">
  Practice a language out loud, then get a clear review of what went well and what to try next.
</p>

<p align="center">
  <a href="https://github.com/bielcarpi/nia/actions/workflows/ci.yml"><img alt="CI" src="https://github.com/bielcarpi/nia/actions/workflows/ci.yml/badge.svg"></a>
  <a href="https://github.com/bielcarpi/nia/actions/workflows/codeql.yml"><img alt="CodeQL" src="https://github.com/bielcarpi/nia/actions/workflows/codeql.yml/badge.svg"></a>
  <a href="LICENSE"><img alt="BSD 3-Clause License" src="https://img.shields.io/badge/license-BSD%203--Clause-blue.svg"></a>
  <img alt="Flutter" src="https://img.shields.io/badge/client-Flutter-02569B?logo=flutter&logoColor=white">
  <img alt="Go" src="https://img.shields.io/badge/API-Go-00ADD8?logo=go&logoColor=white">
  <img alt="Cloud Run" src="https://img.shields.io/badge/runtime-Cloud%20Run-4285F4?logo=googlecloud&logoColor=white">
</p>

Nia is a Flutter app backed by a Go API. A learner chooses a language, level,
topic, and correction style; the tutor holds a spoken practice session; Nia
saves the final text turns and generates strengths, corrections, and next
steps. History is private to the learner and can be deleted from the app.

<p align="center">
  <img src="docs/assets/product-session.png" alt="A Spanish practice session in Nia" width="49%">
  <img src="docs/assets/product-feedback.png" alt="Nia's post-session feedback and corrections" width="49%">
</p>

<p align="center"><sub>Spanish practice session (left) and post-session review (right).</sub></p>

## Run the demo

The default demo needs Flutter and Go, but no Firebase project, OpenAI key, or
cloud account.

```bash
git clone https://github.com/bielcarpi/nia.git
cd nia
make bootstrap
```

Start the API:

```bash
make dev-api
```

Then start the Flutter web app in a second terminal:

```bash
make dev-mobile
```

The app opens at `http://localhost:3000`. Its practice exchange is scripted,
while preferences, transcript turns, feedback, history, and deletion go through
the local Go API. [`docs/demo.md`](docs/demo.md) includes a short product tour
and a complete `curl` walkthrough.

## How it works

```mermaid
flowchart LR
    App["Flutter app"] -->|"ID token + App Check"| API["Go API · Cloud Run"]
    API --> Auth["Firebase Auth"]
    API --> DB["Firestore"]
    API -->|"mint short-lived secret"| RT["OpenAI Realtime"]
    App <-->|"WebRTC audio + events"| RT
    API -->|"post-session review"| Responses["OpenAI Responses"]
```

The Go API handles authentication, session setup, transcript storage, and
feedback. Audio travels directly between the app and OpenAI over WebRTC and is
never stored by Nia. See [`ADR-0002`](docs/adr/0002-direct-webrtc.md) for the
WebRTC decision.

Key decisions:

- **Monorepo.** Client, API, contract, tests, and deployment configuration
  change together.
- **Separate demo and production configuration.** The demo is deterministic
  and credential-free; production requires Firebase, Firestore, and OpenAI.
- **Single Go API.** Authentication, storage, session issuance, feedback, and
  HTTP behavior stay in one service.

See [`docs/architecture.md`](docs/architecture.md) for the request flows and
component boundaries.

## API and repository

The API covers preferences, realtime session creation, idempotent transcript
writes, feedback completion, cursor-paginated history, detail, and deletion.
[`contracts/openapi.yaml`](contracts/openapi.yaml) contains the OpenAPI 3.1
contract and concrete request/response examples.

```text
apps/
  api/                  Go API and Firebase/OpenAI adapters
  mobile/               Flutter app for iOS, Android, and Web
contracts/
  openapi.yaml          Public HTTP contract
docs/
  adr/                   Decisions and alternatives considered
  architecture.md       Boundaries and request flows
  demo.md               Five-minute product and API walkthrough
  development.md        Local and emulator development
  deployment.md         Google Cloud deployment and rollback
  operations.md         First-deploy signals and diagnostics
  security.md           Threat model and production checklist
infra/
  firebase/             Firestore client rules and emulator config
  terraform/            Bootstrap and Cloud Run service stacks
```

Common checks:

```bash
make format
make check
make openapi-lint
make terraform-check
```

CI runs Go formatting, vet, Staticcheck, race-enabled tests, `govulncheck`,
Flutter analysis/tests/web build, OpenAPI linting, Terraform validation, CodeQL,
and repository and container scans. Third-party Actions are pinned to commit
SHAs and tracked by Dependabot.

## Deploy

Terraform is split by lifecycle:

1. `infra/terraform/bootstrap` enables APIs and creates Artifact Registry, the
   runtime service account, Firestore IAM, and an empty Secret Manager secret.
2. `infra/terraform/service` deploys a digest-pinned Cloud Run revision with
   probes, scaling limits, explicit secret versioning, and two starter alerts.

Secret values never pass through Terraform. The manual release path, Firebase
setup, smoke test, rollback, and key rotation are documented in
[`docs/deployment.md`](docs/deployment.md).

There is no hosted demo yet. Run Nia locally with the steps above, or follow
[`docs/deployment.md`](docs/deployment.md) to deploy your own instance.

## Credits

Nia was started by [Biel Carpi](https://github.com/bielcarpi), with early
contributions from [Alex Cano Gallego](https://github.com/AlexCanoGallego),
[Marc Geremias](https://github.com/marcgeremias), and Guillem.

## License

Nia is licensed under the [BSD 3-Clause License](LICENSE).
