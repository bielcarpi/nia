variable "project_id" {
  description = "Google Cloud project created by the bootstrap stack."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be a valid Google Cloud project ID."
  }
}

variable "firebase_project_id" {
  description = "Firebase project whose ID tokens the API accepts."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.firebase_project_id))
    error_message = "firebase_project_id must be a valid Firebase project ID."
  }
}

variable "region" {
  description = "Cloud Run region."
  type        = string
  default     = "europe-west1"
}

variable "service_name" {
  description = "Cloud Run service name."
  type        = string
  default     = "nia-api"
}

variable "image" {
  description = "Immutable Artifact Registry image digest deployed to Cloud Run."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9.-]+-docker\\.pkg\\.dev/[a-z0-9.-]+/[a-z0-9._-]+/[a-z0-9._/-]+@sha256:[a-f0-9]{64}$", var.image))
    error_message = "image must be an Artifact Registry sha256 digest reference, not a mutable tag."
  }
}

variable "runtime_service_account_email" {
  description = "Least-privilege service account from the bootstrap stack."
  type        = string
}

variable "openai_secret_id" {
  description = "Secret Manager secret ID from the bootstrap stack."
  type        = string
  default     = "nia-openai-api-key"
}

variable "openai_secret_version" {
  description = "Enabled numeric Secret Manager version injected into this immutable Cloud Run revision."
  type        = string

  validation {
    condition     = can(regex("^[1-9][0-9]*$", var.openai_secret_version))
    error_message = "openai_secret_version must be an explicit positive numeric version, never latest."
  }
}

variable "allowed_origins" {
  description = "Exact browser origins allowed by API CORS handling. Wildcards are rejected."
  type        = set(string)

  validation {
    condition     = length(var.allowed_origins) > 0 && alltrue([for origin in var.allowed_origins : startswith(origin, "https://") && !strcontains(origin, "*")])
    error_message = "allowed_origins must contain at least one exact HTTPS origin and no wildcards."
  }
}

variable "notification_channel_ids" {
  description = "Existing Cloud Monitoring notification-channel resource names. Empty creates visible incidents without external notifications."
  type        = set(string)
  default     = []

  validation {
    condition     = alltrue([for channel in var.notification_channel_ids : can(regex("^projects/[^/]+/notificationChannels/[^/]+$", channel))])
    error_message = "Each notification channel must use projects/PROJECT/notificationChannels/CHANNEL format."
  }
}

variable "server_error_alert_threshold_count" {
  description = "Five-minute Cloud Run 5xx count that must be exceeded to open an incident."
  type        = number
  default     = 5

  validation {
    condition     = var.server_error_alert_threshold_count >= 1 && floor(var.server_error_alert_threshold_count) == var.server_error_alert_threshold_count
    error_message = "server_error_alert_threshold_count must be a positive integer."
  }
}

variable "latency_alert_threshold_ms" {
  description = "Successful-request p95 latency threshold sustained for five minutes. Tune from observed traffic."
  type        = number
  default     = 10000

  validation {
    condition     = var.latency_alert_threshold_ms >= 100 && var.latency_alert_threshold_ms <= 60000
    error_message = "latency_alert_threshold_ms must be between 100 and 60000 milliseconds."
  }
}

variable "realtime_model" {
  description = "OpenAI Realtime model selected by server policy."
  type        = string
  default     = "gpt-realtime-2.1"
}

variable "realtime_voice" {
  description = "OpenAI Realtime voice selected by server policy."
  type        = string
  default     = "marin"
}

variable "feedback_model" {
  description = "OpenAI model used for post-session feedback."
  type        = string
  default     = "gpt-5.6-terra"
}

variable "min_instances" {
  description = "Minimum warm instance count. Zero is suitable before latency measurements justify spend."
  type        = number
  default     = 0

  validation {
    condition     = var.min_instances >= 0 && floor(var.min_instances) == var.min_instances
    error_message = "min_instances must be a non-negative integer."
  }
}

variable "max_instances" {
  description = "Hard autoscaling ceiling used as a cost and downstream-pressure guardrail."
  type        = number
  default     = 10

  validation {
    condition     = var.max_instances >= 1 && floor(var.max_instances) == var.max_instances
    error_message = "max_instances must be a positive integer."
  }
}

variable "container_concurrency" {
  description = "Maximum concurrent HTTP requests per instance."
  type        = number
  default     = 80

  validation {
    condition     = var.container_concurrency >= 1 && var.container_concurrency <= 1000 && floor(var.container_concurrency) == var.container_concurrency
    error_message = "container_concurrency must be an integer between 1 and 1000."
  }
}

variable "request_timeout_seconds" {
  description = "Cloud Run request timeout. Provider calls use shorter application deadlines."
  type        = number
  default     = 60

  validation {
    condition     = var.request_timeout_seconds >= 1 && var.request_timeout_seconds <= 300 && floor(var.request_timeout_seconds) == var.request_timeout_seconds
    error_message = "request_timeout_seconds must be an integer between 1 and 300."
  }
}

variable "deletion_protection" {
  description = "Protect the production service from accidental Terraform deletion."
  type        = bool
  default     = true
}

variable "labels" {
  description = "Labels applied to the Cloud Run service."
  type        = map(string)
  default = {
    application = "nia"
    component   = "api"
    managed-by  = "terraform"
  }
}
