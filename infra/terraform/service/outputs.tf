output "service_uri" {
  description = "Cloud Run URL used as NIA_API_BASE_URL by the client."
  value       = google_cloud_run_v2_service.api.uri
}

output "service_name" {
  description = "Deployed Cloud Run service name."
  value       = google_cloud_run_v2_service.api.name
}

output "alert_policy_names" {
  description = "Cloud Monitoring policy resource names. Attach channels through notification_channel_ids."
  value = {
    latency      = google_monitoring_alert_policy.successful_request_latency.name
    server_error = google_monitoring_alert_policy.server_error_burst.name
  }
}
