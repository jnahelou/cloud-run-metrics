variable "notification_channels" {
  default = null
}

variable "golden_signals" {
  type = map(
    map(
      object({
        condition_threshold = object({
          filter          = string
          duration        = string
          threshold_value = number
          comparison      = string
          aggregations = map(object({
            alignment_period     = string
            per_series_aligner   = string
            cross_series_reducer = optional(string)
            group_by_fields      = optional(list(string))
          }))
          # Denominator are only used by metric ratio
          denominator_filter = optional(string)
          denominator_aggregations = optional(map(object({
            alignment_period     = string
            per_series_aligner   = string
            cross_series_reducer = optional(string)
            group_by_fields      = optional(list(string))
          })))
        })
      })
  ))
  default = {
    "[%s] Anomalous traffic alert" = {
      "AVG per-second requests alert over 5min" = {
        condition_threshold = {
          filter          = "resource.type = \"cloud_run_revision\" AND resource.labels.service_name = \"%s\" AND metric.type = \"run.googleapis.com/request_count\""
          duration        = "0s"
          threshold_value = 10
          comparison      = "COMPARISON_GT"
          aggregations = {
            0 = {
              alignment_period     = "60s"
              per_series_aligner   = "ALIGN_RATE"
              cross_series_reducer = "REDUCE_SUM"
              group_by_fields      = ["resource.labels.service_name"]
            }
          }
        }
      }

      "AVG max active instance over 5min" = {
        condition_threshold = {
          filter          = "resource.type = \"cloud_run_revision\" AND resource.labels.service_name = \"%s\" AND metric.type = \"run.googleapis.com/container/instance_count\" AND metric.labels.state = \"active\""
          duration        = "0s"
          threshold_value = 10
          comparison      = "COMPARISON_GT"
          aggregations = {
            0 = {
              alignment_period     = "60s"
              per_series_aligner   = "ALIGN_SUM"
              cross_series_reducer = "REDUCE_SUM"
              group_by_fields      = ["resource.labels.service_name"]
            }
          }
        }
      }
    },
    "[%s] Anomalous latency alert" = {
      "Latency 95th exceeded" = {
        condition_threshold = {
          filter          = "resource.type = \"cloud_run_revision\" AND resource.labels.service_name = \"%s\" AND metric.type = \"run.googleapis.com/request_latencies\""
          duration        = "0s"
          threshold_value = 2000
          comparison      = "COMPARISON_GT"
          aggregations = {
            0 = {
              alignment_period     = "60s"
              per_series_aligner   = "ALIGN_PERCENTILE_95"
              cross_series_reducer = "REDUCE_MAX"
              group_by_fields      = ["resource.labels.service_name"]
            }
          }
        }
      }
    }
    "[%s] Anomalous saturation alert" = {
      # Get usage over 60s interval and fire if during 3min
      "Container CPU Utilization 99th percentile" = {
        condition_threshold = {
          filter          = "resource.type = \"cloud_run_revision\" AND resource.labels.service_name = \"%s\" AND metric.type = \"run.googleapis.com/container/cpu/utilizations\""
          duration        = "180s"
          threshold_value = 0.75
          comparison      = "COMPARISON_GT"
          aggregations = {
            0 = {
              alignment_period     = "60s"
              per_series_aligner   = "ALIGN_PERCENTILE_99"
              cross_series_reducer = "REDUCE_MAX"
              group_by_fields      = ["resource.labels.service_name"]
            }
          }
        }
      }
      "Container Memory Utilization 99th percentile" = {
        condition_threshold = {
          filter          = "resource.type = \"cloud_run_revision\" AND resource.labels.service_name = \"%s\" AND metric.type = \"run.googleapis.com/container/memory/utilizations\""
          duration        = "180s"
          threshold_value = 0.75
          comparison      = "COMPARISON_GT"
          aggregations = {
            0 = {
              alignment_period     = "60s"
              per_series_aligner   = "ALIGN_PERCENTILE_99"
              cross_series_reducer = "REDUCE_MAX"
              group_by_fields      = ["resource.labels.service_name"]
            }
          }
        }
      }
    }
    "[%s] Anomalous errors alert" = {
      "Request error rate" = {
        condition_threshold = {
          filter          = "resource.type = \"cloud_run_revision\" AND resource.labels.service_name = \"%s\" AND metric.type = \"run.googleapis.com/request_count\" AND metric.labels.response_code_class != \"2xx\""
          duration        = "0s"
          threshold_value = 0.2
          comparison      = "COMPARISON_GT"
          aggregations = {
            0 = {
              alignment_period     = "60s"
              per_series_aligner   = "ALIGN_SUM"
              cross_series_reducer = "REDUCE_SUM"
              group_by_fields      = ["resource.labels.service_name"]
            }
          }
          denominator_filter = "resource.type = \"cloud_run_revision\" AND resource.labels.service_name = \"%s\" AND metric.type = \"run.googleapis.com/request_count\""
          denominator_aggregations = {
            0 = {
              alignment_period     = "60s"
              per_series_aligner   = "ALIGN_SUM"
              cross_series_reducer = "REDUCE_SUM"
              group_by_fields      = ["resource.labels.service_name"]
            }
          }
        }
      }
      "Request status 5xx" = {
        condition_threshold = {
          filter          = "resource.type = \"cloud_run_revision\" AND resource.labels.service_name = \"%s\" AND metric.type = \"run.googleapis.com/request_count\" AND metric.labels.response_code_class = \"5xx\""
          duration        = "0s"
          threshold_value = 1
          comparison      = "COMPARISON_GT"
          aggregations = {
            0 = {
              alignment_period     = "60s"
              per_series_aligner   = "ALIGN_SUM"
              cross_series_reducer = "REDUCE_SUM"
              group_by_fields      = ["resource.labels.service_name"]
            }
          }
        }
      }
      "Request status 3xx or 4xx" = {
        condition_threshold = {
          filter          = "resource.type = \"cloud_run_revision\" AND resource.labels.service_name = \"%s\" AND metric.type = \"run.googleapis.com/request_count\" AND (metric.labels.response_code_class != \"2xx\" AND metric.labels.response_code_class != \"5xx\")"
          duration        = "0s"
          threshold_value = 10
          comparison      = "COMPARISON_GT"
          aggregations = {
            0 = {
              alignment_period     = "60s"
              per_series_aligner   = "ALIGN_SUM"
              cross_series_reducer = "REDUCE_SUM"
              group_by_fields      = ["resource.labels.service_name"]
            }
          }
        }
      }
    }
  }
}

resource "google_monitoring_alert_policy" "alert_policy" {
  for_each = var.golden_signals

  display_name = format(each.key, upper(var.service_name))
  combiner     = "OR"
  dynamic "conditions" {
    for_each = each.value
    content {
      display_name = conditions.key
      dynamic "condition_threshold" {
        for_each = conditions.value == null ? [] : ["enable"]
        content {
          filter          = format(conditions.value.condition_threshold.filter, var.service_name)
          duration        = conditions.value.condition_threshold.duration
          threshold_value = conditions.value.condition_threshold.threshold_value
          comparison      = conditions.value.condition_threshold.comparison
          dynamic "aggregations" {
            for_each = conditions.value.condition_threshold.aggregations
            content {
              alignment_period     = aggregations.value.alignment_period
              per_series_aligner   = aggregations.value.per_series_aligner
              cross_series_reducer = aggregations.value.cross_series_reducer
              group_by_fields      = aggregations.value.group_by_fields
            }
          }
          denominator_filter = try(format(conditions.value.condition_threshold.denominator_filter, var.service_name), null)
          dynamic "denominator_aggregations" {
            for_each = conditions.value.condition_threshold.denominator_aggregations == null ? {} : conditions.value.condition_threshold.denominator_aggregations
            content {
              alignment_period     = denominator_aggregations.value.alignment_period
              per_series_aligner   = denominator_aggregations.value.per_series_aligner
              cross_series_reducer = denominator_aggregations.value.cross_series_reducer
              group_by_fields      = denominator_aggregations.value.group_by_fields
            }
          }
        }
      }
    }
  }

  notification_channels = var.notification_channels
}
