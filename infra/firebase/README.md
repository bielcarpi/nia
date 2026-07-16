# Firebase configuration

This directory keeps the Firebase emulator and Firestore client-access policy
reviewable beside the application code.

The rules intentionally deny every direct mobile/web Firestore read and write.
The Go API is the authorization boundary and reaches Firestore through its
Cloud Run service account. Admin SDK requests are authorized by IAM and do not
use Firebase client rules.

Start the Auth and Firestore emulators from the repository root:

```bash
make firebase-emulators
```

The command always uses the synthetic project `demo-nia`; it cannot modify a
remote project. Emulator data is ephemeral unless you explicitly pass import
and export directories.

Deploy rules and indexes only after selecting the intended project explicitly:

```bash
firebase deploy \
  --project replace-with-firebase-project-id \
  --config firebase.json \
  --only firestore:rules,firestore:indexes
```

The explicit `--project` prevents a stale local alias from selecting the target.
Do not commit `.firebaserc` if it would make accidental production targeting
easier. `.firebaserc.example` documents the optional local shape only.

`firestore.indexes.json` starts empty because the current owner-scoped store
queries rely on single-field indexes. Add a reviewed composite index here when
an API query actually requires one; do not create console-only drift.
