# Deploy to Google Cloud

This guide deploys the Go API to Cloud Run with Firebase Authentication,
Firestore, Artifact Registry, and Secret Manager. Releases are manual because
the repository does not contain a Google Cloud project or GitHub-to-Google trust
configuration.

The Terraform is split into `bootstrap` and `service` states. Bootstrap creates
long-lived project resources; service deploys replaceable Cloud Run revisions.

## Prerequisites

- a Google Cloud project with billing enabled, registered as a Firebase project,
  and Authentication configured;
- `gcloud`, Docker with BuildKit, Firebase CLI, and Terraform;
- permission to enable APIs, administer the listed resources and IAM bindings,
  push to Artifact Registry, and deploy Cloud Run; and
- a standard OpenAI server API key with appropriate project limits.

Choose the deployment project and region:

```bash
export PROJECT_ID="replace-with-gcp-project-id"
export FIREBASE_PROJECT_ID="$PROJECT_ID"
export REGION="europe-west1"
export TF_STATE_BUCKET="${PROJECT_ID}-nia-tfstate"
gcloud config set project "$PROJECT_ID"
```

Do not copy the example IDs unchanged.

## 1. Create remote state

Create the state bucket once, enable object versioning, and restrict access to
the infrastructure operators. Terraform state contains infrastructure metadata
and must not be public.

```bash
gcloud storage buckets create "gs://${TF_STATE_BUCKET}" \
  --location=EU \
  --uniform-bucket-level-access
gcloud storage buckets update "gs://${TF_STATE_BUCKET}" --versioning
```

Organization policy may require a different location, retention policy, CMEK,
or access boundary. Decide that before the first state write.

## 2. Apply bootstrap infrastructure

```bash
cp infra/terraform/bootstrap/terraform.tfvars.example \
  infra/terraform/bootstrap/terraform.tfvars
```

Set `project_id`, region, and the immutable Firestore location in that local
file. It is gitignored. For an existing Firebase project, leave
`manage_firestore_database = false`. For a brand-new project, Terraform can
create the default database once; an existing database must be imported rather
than recreated. The managed new-database path enables point-in-time recovery,
pessimistic transactions, deletion protection, and abandon-on-stack-removal.

```bash
terraform -chdir=infra/terraform/bootstrap init \
  -backend-config="bucket=${TF_STATE_BUCKET}" \
  -backend-config="prefix=nia/bootstrap"
terraform -chdir=infra/terraform/bootstrap plan -out=tfplan
terraform -chdir=infra/terraform/bootstrap apply tfplan
```

Review the plan. Bootstrap should create required APIs, one Docker repository,
one dedicated runtime service account, its Firestore user role, one empty
Secret Manager secret, and a secret-level accessor grant. It does not create a
secret version and does not grant project-wide Editor or Owner. The secret
container has Terraform `prevent_destroy`; removing it requires an explicit,
reviewed lifecycle change rather than a routine stack destroy. Artifact
Registry itself is protected from Terraform deletion. Its age-and-count cleanup
policies begin in dry-run mode so their candidates can be reviewed before any
artifact is removed.

## 3. Add the provider key safely

Read the key without echoing it or placing it in shell history, then add it as a
Secret Manager version:

```bash
read -r -s -p "OpenAI API key: " OPENAI_API_KEY_VALUE
printf '%s' "$OPENAI_API_KEY_VALUE" | \
  gcloud secrets versions add nia-openai-api-key --data-file=-
unset OPENAI_API_KEY_VALUE

export OPENAI_SECRET_VERSION="$(gcloud secrets versions list \
  nia-openai-api-key \
  --filter='state=ENABLED' \
  --sort-by='~createTime' \
  --limit=1 \
  --format='value(name.basename())')"
printf 'Enabled OpenAI secret version: %s\n' "$OPENAI_SECRET_VERSION"
```

Terraform never receives this value. Confirm the secret has an enabled version,
but do not print its payload. The service stack requires the explicit numeric
version, not the mutable `latest` alias, so every Cloud Run revision and rollback
keeps the credential version it was reviewed with.

## 4. Build, push, and resolve the API image

Authenticate Docker, derive a Git-based tag, then build the same non-root image
CI scans:

```bash
export IMAGE_REPOSITORY="$(terraform -chdir=infra/terraform/bootstrap output -raw api_image_repository)"
export IMAGE_TAGGED="${IMAGE_REPOSITORY}/api:$(git rev-parse --short=12 HEAD)"
gcloud auth configure-docker "${REGION}-docker.pkg.dev"
docker build \
  --platform linux/amd64 \
  --pull \
  --build-arg "VERSION=$(git rev-parse --short=12 HEAD)" \
  -t "$IMAGE_TAGGED" \
  apps/api
docker push "$IMAGE_TAGGED"

export IMAGE_DIGEST="$(gcloud artifacts docker images describe \
  "$IMAGE_TAGGED" \
  --format='value(image_summary.digest)')"
test -n "$IMAGE_DIGEST"
export IMAGE="${IMAGE_REPOSITORY}/api@${IMAGE_DIGEST}"
```

Put `IMAGE` in the service variables. The stack accepts only a `sha256` digest,
so moving or reusing the build tag cannot change a deployed revision.

## 5. Configure Firebase

1. Enable only the sign-in providers the app actually exposes.
2. Register the iOS, Android, and Web app IDs and provide their public Firebase
   client configuration to the Flutter build.
3. Register App Check providers for each platform and enforce attestation for
   the production API session-issuance path.
4. Deploy the deny-by-default Firestore client rules and checked-in indexes:

```bash
firebase deploy \
  --project "$FIREBASE_PROJECT_ID" \
  --config firebase.json \
  --only firestore:rules,firestore:indexes
```

The Cloud Run Admin SDK uses IAM and bypasses client rules. Do not weaken the
rules to make a client query work; product data should cross the Go API boundary.

## 6. Deploy the Cloud Run service

```bash
cp infra/terraform/service/terraform.tfvars.example \
  infra/terraform/service/terraform.tfvars
```

Set the project ID, immutable image reference, bootstrap service-account email,
secret ID, numeric `openai_secret_version`, and exact HTTPS browser origins. The
validation rejects every image tag, wildcard origins, and HTTP production
origins. If notification channels already exist, add their full resource names
to `notification_channel_ids`; the stack never embeds email addresses or other
contact details.

```bash
terraform -chdir=infra/terraform/service init \
  -backend-config="bucket=${TF_STATE_BUCKET}" \
  -backend-config="prefix=nia/service"
terraform -chdir=infra/terraform/service plan -out=tfplan
terraform -chdir=infra/terraform/service apply tfplan
export API_URL="$(terraform -chdir=infra/terraform/service output -raw service_uri)"
```

The service is publicly invokable at the Cloud Run edge because Firebase and
App Check authentication happen in the application. That IAM setting does not
make protected API routes anonymous.

The checked-in service stack routes 100% of traffic to the latest managed
revision. For a high-risk change, deploy the image first to a separate staging
service or extend the stack with an explicit reviewed revision split before
using it for production canaries.

The stack also creates initial Cloud Monitoring policies for a five-minute 5xx
burst and sustained successful-request p95 latency. With no notification-channel
IDs they still create console-visible incidents, but they do not page anyone.
Tune the thresholds from measured traffic and connect reviewed channels before
relying on the policies for paging.

## Artifact cleanup activation

Leave `artifact_cleanup_dry_run = true` through at least one Artifact Registry
cleanup evaluation cycle. Review its Data Access audit-log deletion candidates,
confirm the keep count preserves the rollback window, then set the variable to
`false` and apply bootstrap again. Cleanup runs asynchronously. A keep policy
protects the most recent versions even when they also match the age policy;
Cloud Run references digests rather than tags.

## 7. Smoke test and configure the client

Public probes should succeed without a token:

```bash
curl --fail-with-body "${API_URL}/healthz"
curl --fail-with-body "${API_URL}/readyz"
```

Then verify a real Firebase-authenticated session through a non-production test
account and confirm:

- a request ID is returned and appears in structured logs;
- the client receives a short-lived secret, never the standard API key;
- WebRTC connects and final transcript turns persist;
- completion produces typed feedback;
- a different account cannot read the conversation; and
- deletion reads back as not found.

Build the Flutter app with `NIA_DEMO_MODE=false`, the returned `API_URL`, and the
documented Firebase build defines in `apps/mobile/README.md`. Never put the
standard OpenAI key in a Dart define, Firebase client file, mobile secret, or
web bundle.

## Rollback

List revisions and send traffic back to a known-good one:

```bash
gcloud run revisions list --service nia-api --region "$REGION"
gcloud run services update-traffic nia-api \
  --region "$REGION" \
  --to-revisions="KNOWN_GOOD_REVISION=100"
```

Reconcile the Terraform service state and image variable after an emergency
rollback so the next plan does not silently undo it. Cloud Run rollback does not
reverse Firestore writes; data changes must remain backward compatible during a
revision rollout or have their own restore plan.

## Rotate the OpenAI key

Add a new Secret Manager version using the no-echo flow above, update
`openai_secret_version` in the ignored service tfvars, and apply a new Cloud Run
revision. Verify session issuance and provider correlation on that revision
before moving on. Keep the previous version enabled through the agreed rollback
window because the previous Cloud Run revision references it explicitly; then
disable it and document that older revisions can no longer serve provider calls.
Destroy a version only after retention and incident-response requirements permit.

## Future CI/CD

When a real project and release policy exist, add a protected GitHub environment
and Google Workload Identity Federation. Grant the deploy principal only the
roles required to push the image, impersonate the runtime identity during
deployment, and update this service. Do not store a long-lived service-account
JSON key in GitHub Secrets.
