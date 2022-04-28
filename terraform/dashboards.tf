data "http" "cloudrun_dashboard" {
  url = "https://github.com/GoogleCloudPlatform/monitoring-dashboard-samples/raw/master/dashboards/compute/cloudrun-monitoring.json"

  request_headers = {
    Accept = "application/json"
  }
}

locals {
  enhanced_filter = format("resource.type=\"cloud_run_revision\" AND resource.labels.service_name = \"%s\"", var.service_name)
  dashboard_name  = format("\"[%s] Cloud Run Monitoring\"", var.service_name)
  dashboard_content = replace(
    replace(
      data.http.cloudrun_dashboard.body,
      "resource.type=\"cloud_run_revision\"", local.enhanced_filter
    ),
    "\"Cloud Run Monitoring\"", local.dashboard_name
  )
}

resource "google_monitoring_dashboard" "dashboard" {
  dashboard_json = local.dashboard_content
  lifecycle {
    ignore_changes = [dashboard_json]
  }
}
