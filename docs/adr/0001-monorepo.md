# ADR 0001: One product monorepo

- Status: accepted
- Date: 2026-07-16

## Context

The mobile client and backend previously lived in separate repositories even
though they form one product, share one API contract, and must evolve together.
That split made the public story harder to evaluate and allowed documentation
and integration assumptions to drift.

## Decision

Keep the Flutter app in `apps/mobile`, the Go API in `apps/api`, the API contract
in `contracts`, and deployment configuration in `infra`. Run both application
checks from one CI workflow.

The historical backend repository is not merged into this Git history. Its
contributors remain credited, while the new API starts from a clean,
security-reviewed implementation.

## Consequences

- A single pull request can change contract, server, client, tests, and docs
  atomically.
- GitHub presents one coherent product and one quality signal.
- CI needs path-aware caches and jobs for two language ecosystems.
- Repository permissions apply to both applications; CODEOWNERS or finer
  review rules can be introduced if the team grows.
