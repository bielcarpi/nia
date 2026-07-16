# Contributing

Thanks for contributing. Please keep changes focused and include tests where
they add value. By submitting a contribution, you agree that it may be
distributed under the [BSD 3-Clause License](LICENSE).

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

Nia currently uses one Flutter client and one Go API. Before adding another
service, explain the workload or ownership boundary that requires it. Add an ADR
for changes to deployment units, data flow, or persistence.

## Pull requests

A useful pull request explains:

- the problem it solves;
- the chosen behavior and meaningful trade-offs;
- how it was verified; and
- any deployment, migration, rollback, or security impact.

Do not commit generated build directories, `.env` files, Terraform state,
service-account JSON, or provider credentials.
