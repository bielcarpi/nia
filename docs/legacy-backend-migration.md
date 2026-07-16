# Retire the historical backend safely

The monorepo is the intended canonical product repository, but deleting or
archiving the historical backend is a release operation—not a source-tree
cleanup. Complete these gates in order.

## 1. Contain credentials

- Revoke or rotate every provider and cloud credential that has ever appeared
  in backend source, generated deployment files, CI logs, artifacts, or Git
  history.
- Verify replacement credentials are scoped to the intended project and held in
  Secret Manager.
- Inspect provider usage and cloud audit logs for unexplained access.

Deleting a repository does not revoke a credential and is not a substitute for
history remediation.

## 2. Preserve provenance without importing unsafe history

- Keep the Flutter repository history and its contributor attribution intact.
- Credit historical backend contributors in release notes or repository docs.
- Do not merge backend history containing sensitive material into the monorepo.
- Preserve any legally or operationally required private evidence before
  history rewriting or repository deletion.

## 3. Prove replacement behavior

- Deploy the new API to a non-production environment.
- Run authentication, cross-user authorization, Realtime issuance, transcript
  idempotency, completion, history, and deletion checks.
- Build each supported Flutter target against the new base URL.
- Confirm logs and provider traces use request correlation without content.
- Observe the replacement under representative load and provider failure.

## 4. Migrate consumers and operations

- Ship a client release pointing to the monorepo API.
- Drain or invalidate clients that still depend on the old endpoint.
- Move dashboards, alerts, budgets, runbooks, domains, and ownership.
- Decide whether historical user data must be migrated, exported, or deleted and
  verify the chosen result.

## 5. Redirect, then archive

Update the historical repository README to point to
<https://github.com/bielcarpi/nia>, disable obsolete automation and deployments,
and archive the repository once traffic and data checks stay clean.

Archiving is preferable to immediate deletion because it preserves contributor
provenance and old links while making the canonical repository unambiguous.
Delete only after retention, ownership, and legal requirements are understood.

## Final gate

The retirement is complete only when no client calls the old endpoint, no old
credential remains valid, the new service has passed end-to-end verification,
and the historical repository clearly redirects to this monorepo.
