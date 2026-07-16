variable "project_id" {
  description = "Google Cloud project that owns the Nia runtime."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be a valid Google Cloud project ID."
  }
}

variable "region" {
  description = "Region for Artifact Registry and Cloud Run."
  type        = string
  default     = "europe-west1"
}

variable "artifact_repository_id" {
  description = "Artifact Registry repository for API images."
  type        = string
  default     = "nia"
}

variable "artifact_cleanup_dry_run" {
  description = "Evaluate Artifact Registry cleanup policies without deleting images. Disable only after reviewing dry-run audit logs."
  type        = bool
  default     = true
}

variable "artifact_retention_days" {
  description = "Delete image versions older than this many days once cleanup dry-run is disabled."
  type        = number
  default     = 90

  validation {
    condition     = var.artifact_retention_days >= 30 && var.artifact_retention_days <= 365 && floor(var.artifact_retention_days) == var.artifact_retention_days
    error_message = "artifact_retention_days must be an integer between 30 and 365."
  }
}

variable "artifact_keep_count" {
  description = "Minimum recent image versions retained for each package regardless of age."
  type        = number
  default     = 20

  validation {
    condition     = var.artifact_keep_count >= 2 && var.artifact_keep_count <= 100 && floor(var.artifact_keep_count) == var.artifact_keep_count
    error_message = "artifact_keep_count must be an integer between 2 and 100."
  }
}

variable "runtime_service_account_id" {
  description = "Account ID for the least-privilege Cloud Run identity."
  type        = string
  default     = "nia-api"
}

variable "openai_secret_id" {
  description = "Secret Manager secret container for the OpenAI API key."
  type        = string
  default     = "nia-openai-api-key"
}

variable "manage_firestore_database" {
  description = "Create the default Firestore database. Leave false for an existing Firebase project."
  type        = bool
  default     = false
}

variable "firestore_location" {
  description = "Immutable Firestore database location used only when creating it."
  type        = string
  default     = "eur3"
}

variable "labels" {
  description = "Labels applied to supported resources."
  type        = map(string)
  default = {
    application = "nia"
    managed-by  = "terraform"
  }
}
