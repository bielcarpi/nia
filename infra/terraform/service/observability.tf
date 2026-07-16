locals {
  cloud_run_metric_scope = join(" AND ", [
    "resource.type = \"cloud_run_revision\"",
    "resource.labels.service_name = \"${google_cloud_run_v2_service.api.name}\"",
    "resource.labels.location = \"${google_cloud_run_v2_service.api.location}\"",
  ])
}

resource "google_monitoring_alert_policy" "server_error_burst" {
  project               = var.project_id
  display_name          = "${var.service_name}: Cloud Run 5xx burst"
  combiner              = "OR"
  enabled               = true
  severity              = "ERROR"
  notification_channels = sort(tolist(var.notification_channel_ids))

  documentation {
    mime_type = "text/markdown"
    subject   = "Nia API is returning a burst of server errors"
    content   = "More than ${var.server_error_alert_threshold_count} container-level 5xx responses occurred in five minutes. Group structured logs by revision, route template, error code, and request ID; then follow the service runbooks."
  }

  conditions {
    display_name = "5xx count exceeds ${var.server_error_alert_threshold_count} in five minutes"

    condition_threshold {
      filter          = "${local.cloud_run_metric_scope} AND metric.type = \"run.googleapis.com/request_count\" AND metric.labels.response_code_class = \"5xx\""
      comparison      = "COMPARISON_GT"
      threshold_value = var.server_error_alert_threshold_count
      duration        = "0s"

      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_SUM"
        cross_series_reducer = "REDUCE_SUM"
      }

      trigger {
        count = 1
      }
    }
  }

  user_labels = {
    application = "nia"
    component   = "api"
    signal      = "server-errors"
  }
}

resource "google_monitoring_alert_policy" "successful_request_latency" {
  project               = var.project_id
  display_name          = "${var.service_name}: sustained p95 latency"
  combiner              = "OR"
  enabled               = true
  severity              = "WARNING"
  notification_channels = sort(tolist(var.notification_channel_ids))

  documentation {
    mime_type = "text/markdown"
    subject   = "Nia API successful-request latency is elevated"
    content   = "Cloud Run p95 latency for successful responses stayed above ${var.latency_alert_threshold_ms} ms for five minutes. Compare revisions and provider-duration fields before changing capacity or rolling back."
  }

  conditions {
    display_name = "Successful-request p95 exceeds ${var.latency_alert_threshold_ms} ms"

    condition_threshold {
      filter          = "${local.cloud_run_metric_scope} AND metric.type = \"run.googleapis.com/request_latencies\" AND metric.labels.response_code_class = \"2xx\""
      comparison      = "COMPARISON_GT"
      threshold_value = var.latency_alert_threshold_ms
      duration        = "300s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_PERCENTILE_95"
      }

      trigger {
        count = 1
      }
    }
  }

  user_labels = {
    application = "nia"
    component   = "api"
    signal      = "latency"
  }
}
