#data "helm_repository" "stable" {
#  name = "stable"
#  url = "https://kubernetes-charts.storage.googleapis.com/"
#}

resource "kubernetes_namespace" "nginx-ingress" {
  metadata {
    name = "nginx-ingress"
  }
}

#locals {
#  values = {
#    controller = {
#      kind = "DaemonSet"
#      nodeSelector = var.node_selector
#    }
#    defaultBackend = {
#      nodeSelector = var.node_selector
#    }
#  }
#}

resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  namespace  = kubernetes_namespace.nginx-ingress.metadata[0].name
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "nginx-ingress-controller"

  set {
    name  = "service.type"
    value = "LoadBalancer"
  }
#  set {
#    name  = "controller.service.loadBalancerIP"
#    value = var.external_v4_endpoint
#  }
}

data "kubernetes_service" "nginx-ingress" {
  depends_on = [helm_release.nginx_ingress]
  metadata {
    name = "${helm_release.nginx_ingress.name}-controller"
    namespace = kubernetes_namespace.nginx-ingress.metadata[0].name
  }
}