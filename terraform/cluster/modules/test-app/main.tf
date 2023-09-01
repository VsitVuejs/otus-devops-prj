
resource "kubernetes_pod_v1" "app1" {
  metadata {
    name = "my-app1"
    labels = {
      "app" = "app1"
    }
  }

  spec {
    container {
      image = "hashicorp/http-echo"
      name  = "my-app1"
      args  = ["-text=Hello from app 1"]
    }
  }
}

resource "kubernetes_service_v1" "app1_service" {
  metadata {
    name = "my-app1-service"
  }
  spec {
    selector = {
      app = kubernetes_pod_v1.app1.metadata.0.labels.app
    }
    port {
      port = 5678
    }
  }
}

#resource "random_password" "ingress_auth" {
#  length           = 32
#  special          = false
#  override_special = "$@,.-_!"
#}

resource "kubernetes_secret" "basic_auth" {
  type = "Opaque"
  metadata {
    name = "basic-auth"
  }
  data = {
    "auth" : "user:${bcrypt(var.basic_auth_pass)}"
  }
}

resource "kubernetes_ingress_v1" "ingress" {
  wait_for_load_balancer = true
  metadata {
    name = "simple-fanout-ingress"
    annotations = {
      "nginx.ingress.kubernetes.io/auth-type"        = "basic",
      "nginx.ingress.kubernetes.io/auth-secret" = kubernetes_secret.basic_auth.metadata.0.name,
#      "nginx.ingress.kubernetes.io/auth-secret"      = "${var.cluster_name}/${kubernetes_secret.ingress_auth.metadata.0.name}"
      "nginx.ingress.kubernetes.io/auth-realm"       = "Authentication Required - foo"
    }
  }

  spec {
    ingress_class_name = "nginx"

    rule {
      http {
        path {
          backend {
            service {
              name = "my-app1-service"
              port {
                number = 5678
              }
            }
          }

          path = "/"
        }

      }
    }

  }
}