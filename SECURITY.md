# Security policy

## Supported versions

Nia is currently a showcase-stage project. Security fixes are made on the
latest `main` revision; no released version line is receiving backports yet.

## Report a vulnerability

Please do not disclose a suspected vulnerability in a public issue, discussion,
or pull request. Use GitHub's **Security** tab to submit a private vulnerability
report for this repository:

<https://github.com/bielcarpi/nia/security/advisories/new>

Include, when possible:

- the affected commit and component;
- a minimal reproduction or proof of concept;
- the security impact and required preconditions;
- whether any credential or personal data may have been exposed; and
- a safe way to contact you for follow-up.

The maintainers will acknowledge a complete report as availability permits,
investigate privately, and coordinate disclosure after a fix. This is not a
bug-bounty program and no payment is promised.

## Credential exposure

If a live credential appears in the repository, logs, build output, or an
artifact, revoke or rotate it first. Removing the string from the current branch
does not invalidate it and does not remove it from Git history. After rotation,
preserve enough non-secret evidence to investigate the exposure safely.

## Security boundaries

The intended production trust model is documented in
[`docs/security.md`](docs/security.md). In particular:

- standard provider keys remain in Secret Manager and server-side memory;
- clients receive only short-lived Realtime client secrets;
- raw audio is not stored by Nia's API;
- Firestore access is server-only; and
- production mode fails closed when required security configuration is absent.
