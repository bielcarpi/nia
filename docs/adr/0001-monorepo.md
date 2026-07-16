# ADR 0001: Keep the product in one repository

- Status: accepted
- Date: 2026-07-16

## Problem

The Flutter client and backend were separate repositories, but a session change
usually crosses both: the HTTP contract, server behavior, client parsing, and
deployment configuration must agree. Coordinating the same change across two
repositories made drift easy.

## Options considered

1. **Keep the repositories split.** Each repository stays smaller, but contract
   changes require coordinated branches and two CI results.
2. **Merge the backend repository history.** This preserves every commit in one
   graph, but also carries over files and decisions that the new API replaces.
3. **Add the rebuilt API as a new application.** This keeps the client history
   and starts the new API with a clean structure.

## Decision

Use option 3. The client lives in `apps/mobile`, the API in `apps/api`, the
contract in `contracts`, and deployment code in `infra`. One CI workflow checks
both applications and the shared contract.

## Cost of the choice

- A pull request can update a feature end to end.
- Go and Flutter now share repository permissions and release coordination.
- CI downloads two language toolchains even when a change touches only one.
- If the team or build volume grows, path-filtered jobs or separate ownership
  rules may become useful; they are not needed for the current team.
