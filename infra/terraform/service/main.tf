locals {
  runtime_environment = {
    NIA_ENV                     = "production"
    NIA_AUTH_MODE               = "firebase"
    NIA_STORE_MODE              = "firestore"
    NIA_PROVIDER_MODE           = "openai"
    NIA_FIREBASE_PROJECT_ID     = var.firebase_project_id
    NIA_REQUIRE_APP_CHECK       = "true"
    NIA_ALLOWED_ORIGINS         = join(",", sort(tolist(var.allowed_origins)))
    NIA_OPENAI_BASE_URL         = "https://api.openai.com/v1"
    NIA_REALTIME_MODEL          = var.realtime_model
    NIA_REALTIME_VOICE          = var.realtime_voice
    NIA_TRANSCRIPTION_MODEL     = "gpt-4o-mini-transcribe"
    NIA_FEEDBACK_MODEL          = var.feedback_model
    NIA_REALTIME_SDP_ENDPOINT   = "https://api.openai.com/v1/realtime/calls"
    NIA_REALTIME_TTL            = "10m"
    NIA_PROVIDER_TIMEOUT        = "15s"
    NIA_REQUEST_TIMEOUT         = "30s"
    NIA_MAX_REQUEST_BODY_BYTES  = "65536"
    NIA_MAX_CONCURRENT_REQUESTS = "64"
    NIA_SESSION_LIMIT_PER_HOUR  = "12"
    NIA_FEEDBACK_LIMIT_PER_HOUR = "12"
    NIA_LOG_LEVEL               = "info"
  }
}

resource "google_cloud_run_v2_service" "api" {
  project             = var.project_id
  name                = var.service_name
  location            = var.region
  ingress             = "INGRESS_TRAFFIC_ALL"
  deletion_protection = var.deletion_protection
  labels              = var.labels

  template {
    service_account                  = var.runtime_service_account_email
    execution_environment            = "EXECUTION_ENVIRONMENT_GEN2"
    timeout                          = "${var.request_timeout_seconds}s"
    max_instance_request_concurrency = var.container_concurrency

    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }

    containers {
      name  = "api"
      image = var.image

      ports {
        name           = "http1"
        container_port = 8080
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
        cpu_idle          = true
        startup_cpu_boost = true
      }

      dynamic "env" {
        for_each = local.runtime_environment
        content {
          name  = env.key
          value = env.value
        }
      }

      env {
        name = "OPENAI_API_KEY"
        value_source {
          secret_key_ref {
            secret  = var.openai_secret_id
            version = var.openai_secret_version
          }
        }
      }

      startup_probe {
        initial_delay_seconds = 0
        timeout_seconds       = 1
        period_seconds        = 3
        failure_threshold     = 10

        http_get {
          path = "/readyz"
          port = 8080
        }
      }

      liveness_probe {
        initial_delay_seconds = 5
        timeout_seconds       = 1
        period_seconds        = 10
        failure_threshold     = 3

        http_get {
          path = "/healthz"
          port = 8080
        }
      }
    }
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }

  lifecycle {
    precondition {
      condition     = var.min_instances <= var.max_instances
      error_message = "min_instances must not exceed max_instances."
    }
  }
}

resource "google_cloud_run_v2_service_iam_member" "public_invoker" {
  project  = var.project_id
  location = google_cloud_run_v2_service.api.location
  name     = google_cloud_run_v2_service.api.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
