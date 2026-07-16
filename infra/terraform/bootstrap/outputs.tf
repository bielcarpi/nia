output "api_image_repository" {
  description = "Prefix for API image names. Push a tag, then deploy the resolved sha256 digest."
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.api.repository_id}"
}

output "runtime_service_account_email" {
  description = "Service account to pass to the service stack."
  value       = google_service_account.api.email
}

output "openai_secret_id" {
  description = "Secret ID to pass to the service stack."
  value       = google_secret_manager_secret.openai.secret_id
}
