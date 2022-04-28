variable "slos_config" {
  type = map(object({
    good_total_ratio = optional(object({
      good_service_filter  = string,
      total_service_filter = string,
    }))
    distribution_cut = optional(object({
      distribution_filter = string,
      range               = object({ min = number, max = number })
    }))
    goal = number,
  }))

  default = {
    "[ERROR] Cloud Run Serving Errors" = {
      good_total_ratio = {
        good_service_filter  = "metric.type=\"run.googleapis.com/request_count\" resource.type=\"cloud_run_revision\" metric.labels.response_code=monitoring.regex.full_match(\"^([2-3][0-9]{2}|4[0-1][0-9])$\") resource.labels.service_name=\"%s\""
        total_service_filter = "metric.type=\"run.googleapis.com/request_count\" resource.type=\"cloud_run_revision\" resource.labels.service_name=\"%s\""
      },
      goal = 0.75
    },
    "[LATENCY] Request latencies under 2 seconds" = {
      distribution_cut = {
        distribution_filter = "metric.type=\"run.googleapis.com/request_latencies\" resource.type=\"cloud_run_revision\" resource.labels.service_name=\"%s\""
        range = {
          min = 0,
          max = 2000
        }
      }
      goal = 0.75
    }
  }
}

resource "google_monitoring_custom_service" "cloud-run" {
  service_id   = format("gcrun-%s-slos", var.service_name)
  display_name = format("Cloud Run %s SLOs", var.service_name)
}

resource "google_monitoring_slo" "slo" {
  for_each = var.slos_config

  service      = google_monitoring_custom_service.cloud-run.service_id
  display_name = each.key

  goal            = each.value.goal
  calendar_period = "DAY"

  request_based_sli {
    dynamic "good_total_ratio" {
      for_each = toset(each.value.good_total_ratio == null ? [] : ["enable"])
      content {
        good_service_filter  = format(each.value.good_total_ratio.good_service_filter, var.service_name)
        total_service_filter = format(each.value.good_total_ratio.total_service_filter, var.service_name)
      }
    }

    dynamic "distribution_cut" {
      for_each = toset(each.value.distribution_cut == null ? [] : ["enable"])
      content {
        distribution_filter = format(each.value.distribution_cut.distribution_filter, var.service_name)
        range {
          min = each.value.distribution_cut.range.min
          max = each.value.distribution_cut.range.max
        }
      }
    }
  }
}
