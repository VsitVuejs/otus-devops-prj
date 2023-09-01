
resource "helm_release" "loki" {
  name = "loki"

  repository       = "https://grafana.github.io/helm-charts"
  chart            = "loki-stack"
  version          = var.loki_version
  namespace        = "loki"
  create_namespace = true

  values = [
    templatefile("${path.module}/templates/loki-values.yml", {
      STORAGE_LOCAL_PATH = "/data/loki/chunks",
      STORAGE_SIZE = var.loki_storage_size
      STORAGE_TYPE = var.loki_storage_type
    })
  ]

}