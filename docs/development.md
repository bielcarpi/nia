# Development

Nia is built so the default reviewer path has no cloud dependency while the
same domain logic can run against production adapters explicitly.

## Tooling

Required for the complete local check:

- Go version declared by `apps/api/go.mod`;
- current stable Flutter and Dart SDKs;
- Node.js 24+ for the pinned Redocly CLI invocation;
- Terraform 1.9+; and
- `jq` for contract/demo commands.

Firebase CLI and Docker are optional unless you run emulators or build the API
image. `make doctor` checks the core toolchain, `make doctor-full` checks every
repository tool, and `make bootstrap` resolves Go and Flutter dependencies.

## Credential-free demo mode

```bash
make bootstrap
make dev-api
```

In a second terminal:

```bash
make dev-mobile
```

`make dev-api` sources `.env.example`, then an optional ignored `.env`. The
checked-in values explicitly select:

- demo authentication with fixed local bearer `nia-local-demo`;
- in-memory storage; and
- deterministic session and feedback providers.

No missing credential silently triggers demo behavior. Production mode has its
own validation and must not start without its required project and provider
configuration.

The Flutter demo is selected at compile time with:

```text
--dart-define=NIA_DEMO_MODE=true
--dart-define=NIA_LOCAL_STACK=true
--dart-define=NIA_API_BASE_URL=http://localhost:8080
```

The local-stack flag sends preferences, turns, history, feedback completion,
and deletion through the Go API while retaining deterministic realtime events.
Omit `NIA_LOCAL_STACK` (or run `flutter run -d chrome` directly in
`apps/mobile`) for the fully offline in-memory product tour.

See [demo.md](demo.md) for a product and API walkthrough.

## Configuration

Copy the template only for local overrides:

```bash
cp .env.example .env
```

| Variable | Local demo | Production purpose |
| --- | --- | --- |
| `NIA_ENV` | `local` | Selects environment-specific validation and logging metadata |
| `PORT` | `8080` | HTTP port; Cloud Run supplies the production value |
| `NIA_AUTH_MODE` | `demo` | `firebase` verifies Firebase ID tokens |
| `NIA_STORE_MODE` | `memory` | `firestore` persists product records |
| `NIA_PROVIDER_MODE` | `demo` | `openai` enables Realtime and feedback provider calls |
| `NIA_FIREBASE_PROJECT_ID` | `demo-nia` | Expected Firebase token audience and Firestore project |
| `NIA_REQUIRE_APP_CHECK` | `false` | Must be true for public production issuance |
| `NIA_ALLOWED_ORIGINS` | local exact origins | Exact browser origins, comma-separated |
| `OPENAI_API_KEY` | empty | Standard server-only provider credential |
| `NIA_REALTIME_MODEL` | current checked-in default | Server-owned Realtime model policy |
| `NIA_REALTIME_VOICE` | `marin` | Server-owned voice policy |
| `NIA_FEEDBACK_MODEL` | current checked-in default | Structured feedback model |
| timeout/limit settings | conservative defaults | Bound requests, shutdown, body size, and per-user usage |

The model names are defaults reviewed on the date of the relevant commit, not a
promise that a provider alias will remain available forever. Keep them
configurable, validate provider changes in staging, and update docs and tests
together.

Never place `OPENAI_API_KEY` in a Flutter Dart define. Dart defines are compiled
into client artifacts and are not secrets.

## Firebase emulator development

Start isolated Auth and Firestore emulators:

```bash
make firebase-emulators
```

The make target forces synthetic project `demo-nia`; it does not target a remote
Firebase project. To run cloud adapters locally against the emulators, override
the API environment in `.env`:

```dotenv
NIA_AUTH_MODE=firebase
NIA_STORE_MODE=firestore
NIA_FIREBASE_PROJECT_ID=demo-nia
NIA_REQUIRE_APP_CHECK=false
FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099
FIRESTORE_EMULATOR_HOST=127.0.0.1:8088
GOOGLE_CLOUD_PROJECT=demo-nia
```

Disabling App Check here is an emulator-only compromise. A public deployment
must use valid platform attestation or a controlled App Check debug-token flow.
The production client sends that token in `X-Firebase-AppCheck` alongside the
Firebase ID token in the standard `Authorization: Bearer ...` header.

The checked-in Firestore client rules deny all reads and writes. Admin SDK
requests use IAM and bypass those rules, including against production; keep
authorization tests at the API boundary.

## Mixed adapter testing

Adapters can be combined intentionally during development. For example, demo
identity + memory store + live OpenAI helps inspect provider integration without
writing Firebase data:

```dotenv
NIA_ENV=local
NIA_AUTH_MODE=demo
NIA_STORE_MODE=memory
NIA_PROVIDER_MODE=openai
OPENAI_API_KEY=replace-locally
```

That is not production-equivalent because every caller with the local demo
token becomes the same synthetic identity. Do not expose it beyond loopback.

For a full production-like integration, use Firebase Auth, App Check, Firestore,
and OpenAI together in a non-production cloud project. Exercise cross-account
authorization and deletion, not only successful tutoring.

## Test and quality commands

```bash
make format          # write format changes
make format-check    # formatting without writes
make lint-go         # go vet + pinned Staticcheck
make test-go         # race detector + coverage
make vuln-go         # reachable Go vulnerability analysis
make mobile-check    # analyze, test, and release-build the web demo
make openapi-lint    # Redocly contract checks
make terraform-check # fmt + init without backend + validate
make check           # all of the above read-only checks
```

The API and mobile directories also document component-focused commands.
GitHub CI builds and scans the runtime image in addition to the local suite.

## Contract workflow

Treat `contracts/openapi.yaml` as part of the product boundary:

1. describe the request, response, failure, and auth change;
2. update API handler and domain tests;
3. update the mobile client/fixtures;
4. run Redocly and both application suites; and
5. document rollout or compatibility impact.

Additive response fields still matter because strict clients may reject them.
Breaking paths, field semantics, enums, or auth behavior require a versioning
decision rather than an undocumented deploy.

## Troubleshooting

### The API refuses to start

Read the typed configuration error. Check the selected modes first: a Firebase,
Firestore, or OpenAI mode deliberately requires its own settings. Do not bypass
the check by adding fallback credentials or weakening production validation.

### The mobile app cannot reach localhost

`localhost` means the device itself. A physical device needs the development
machine's reachable LAN address and local firewall access. Android Emulator may
use `10.0.2.2`; iOS Simulator can usually reach the Mac loopback address.

### A browser request fails CORS

Add the exact development origin to `NIA_ALLOWED_ORIGINS`. Do not use `*` with
authenticated requests and do not treat CORS as authorization.

### Terraform init asks for a backend

Local validation uses `-backend=false`. Real deployment requires the protected
GCS state setup in [deployment.md](deployment.md).
