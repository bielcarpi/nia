# Contributing

Thanks for helping improve Nia. Small, reviewable changes with tests and an
explicit user outcome are easiest to evaluate.

> **Licensing note:** this repository does not currently declare an open-source
> license because rights across the historical contributors still need to be
> confirmed. Opening a pull request does not grant the public broader reuse
> rights. Maintainers should resolve contribution and project licensing terms
> before accepting external code.

## Development workflow

1. Create a focused branch from the latest `main`.
2. Run `make bootstrap` once, then `make check` before requesting review.
3. Change [`contracts/openapi.yaml`](contracts/openapi.yaml) with any public API
   behavior and update both application sides in the same pull request.
4. Add or update tests for behavior, authorization, validation, and failure
   cases—not only the happy path.
5. Document new environment variables in `.env.example` and deployment-facing
   changes in `docs/`.

Use conventional-style commit subjects when practical, for example:

```text
feat(api): add idempotent transcript writes
fix(mobile): stop reconnecting after session completion
docs(infra): explain Cloud Run rollback
```

## Quality expectations

- Go code is formatted with `gofmt`, passes `go vet`, `staticcheck`, race-enabled
  tests, and `govulncheck`.
- Dart code is formatted, passes `flutter analyze --fatal-infos`, and has
  deterministic widget or unit tests.
- The OpenAPI description passes Redocly linting.
- Terraform is formatted and validates without credentials.
- Logs and test fixtures contain no credentials, authorization headers, raw
  audio, or real learner text.

CI repeats these checks and scans the repository and API image for high and
critical known vulnerabilities.

## Architecture guardrails

Keep the system proportional to its workload. The current boundary is one
Flutter client, one stateless Go API, Firebase Authentication, Firestore, and
OpenAI. New services or infrastructure should be justified by an independently
scaling workload, a security boundary, or measured reliability needs.

Read [`docs/architecture.md`](docs/architecture.md) and add an ADR for decisions
that change a major trust boundary, data path, deployment unit, or durable data
model.

## Pull requests

A useful pull request explains:

- the user or operator problem;
- the chosen behavior and meaningful trade-offs;
- how it was verified; and
- any deployment, migration, rollback, or security impact.

Do not commit generated build directories, `.env` files, Terraform state,
service-account JSON, or provider credentials.
