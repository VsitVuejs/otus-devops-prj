
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "kube-prometheus" {
  name       = "kube-prometheus-stackr"
  namespace  = var.namespace
  version    = var.kube-version
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
}