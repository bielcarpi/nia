locals {
  required_services = toset([
    "artifactregistry.googleapis.com",
    "firebaseappcheck.googleapis.com",
    "firestore.googleapis.com",
    "identitytoolkit.googleapis.com",
    "monitoring.googleapis.com",
    "run.googleapis.com",
    "secretmanager.googleapis.com",
  ])
}

resource "google_project_service" "required" {
  for_each = local.required_services

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_artifact_registry_repository" "api" {
  project       = var.project_id
  location      = var.region
  repository_id = var.artifact_repository_id
  description   = "Nia application container images"
  format        = "DOCKER"
  mode          = "STANDARD_REPOSITORY"
  labels        = var.labels

  # Start in dry-run, inspect the audit-log candidates, then explicitly opt in
  # to deletion. Digest-pinned Cloud Run revisions remain deployable even if a
  # human-readable tag is later removed.
  cleanup_policy_dry_run = var.artifact_cleanup_dry_run

  cleanup_policies {
    id     = "delete-old-images"
    action = "DELETE"

    condition {
      tag_state  = "ANY"
      older_than = "${var.artifact_retention_days}d"
    }
  }

  cleanup_policies {
    id     = "keep-recent-images"
    action = "KEEP"

    most_recent_versions {
      keep_count = var.artifact_keep_count
    }
  }

  deletion_policy = "PREVENT"

  depends_on = [google_project_service.required]
}

resource "google_service_account" "api" {
  project      = var.project_id
  account_id   = var.runtime_service_account_id
  display_name = "Nia API runtime"
  description  = "Least-privilege identity used only by the Nia Cloud Run API"
}

resource "google_project_iam_member" "api_firestore" {
  project = var.project_id
  role    = "roles/datastore.user"
  member  = "serviceAccount:${google_service_account.api.email}"
}

resource "google_secret_manager_secret" "openai" {
  project   = var.project_id
  secret_id = var.openai_secret_id
  labels    = var.labels

  replication {
    auto {}
  }

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [google_project_service.required]
}

resource "google_secret_manager_secret_iam_member" "api_openai" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.openai.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.api.email}"
}

resource "google_firestore_database" "default" {
  count = var.manage_firestore_database ? 1 : 0

  project                           = var.project_id
  name                              = "(default)"
  location_id                       = var.firestore_location
  type                              = "FIRESTORE_NATIVE"
  concurrency_mode                  = "PESSIMISTIC"
  app_engine_integration_mode       = "DISABLED"
  point_in_time_recovery_enablement = "POINT_IN_TIME_RECOVERY_ENABLED"
  deletion_policy                   = "ABANDON"
  delete_protection_state           = "DELETE_PROTECTION_ENABLED"

  depends_on = [google_project_service.required]
}
