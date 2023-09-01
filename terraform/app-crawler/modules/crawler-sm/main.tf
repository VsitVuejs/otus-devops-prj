resource "kubernetes_manifest" "service_monitor" {
  manifest = {
    "apiVersion" = "monitoring.coreos.com/v1"
    "kind"       = "ServiceMonitor"
    "metadata" = {
      "labels" = {
        "release" = "kube-prometheus-stackr"
      }
      "name"      = var.name
      "namespace" = var.namespace
    }
    "spec" = {
      "endpoints" = [
        {
          "port" = var.port
        },
      ]
      "namespaceSelector" = {
        "matchNames" = [
          "${var.namespace_selector}",
        ]
      }
      "selector" = {
        "matchLabels" = {
          "${var.label_key}" = "${var.label_value}"
        }
      }
    }
  }
}