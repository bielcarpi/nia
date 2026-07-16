# ADR 0001: Keep the product in one repository

- Status: accepted
- Date: 2026-07-16

## Problem

The Flutter client and backend were separate repositories, but a session change
usually crosses both: the HTTP contract, server behavior, client parsing, and
deployment configuration must agree. Reviewing half of that change at a time
made drift easy and made the working product harder to evaluate.

## Options considered

1. **Keep the repositories split.** Each repository stays smaller, but contract
   changes require coordinated branches and two CI results.
2. **Import the historical backend Git history into the Flutter repository.**
   This preserves every commit in one graph, but makes the monorepo migration
   depend on a complete credential and history audit.
3. **Keep the Flutter history and add the rebuilt API as a new application.**
   This puts the current product in one review surface without importing
   potentially sensitive backend history.

## Decision

Use option 3. The client lives in `apps/mobile`, the API in `apps/api`, the
contract in `contracts`, and deployment code in `infra`. One CI workflow checks
both applications and the shared contract.

The historical backend remains separate during migration. Its contributors are
credited, and its retirement has explicit gates in
[`legacy-backend-migration.md`](../legacy-backend-migration.md).

## Cost of the choice

- A pull request can update a feature end to end.
- Go and Flutter now share repository permissions and release coordination.
- CI downloads two language toolchains even when a change touches only one.
- If the team or build volume grows, path-filtered jobs or separate ownership
  rules may become useful; they are not needed for the current team.
