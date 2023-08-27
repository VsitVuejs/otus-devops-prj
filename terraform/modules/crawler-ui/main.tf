locals {
    service_name = "crawler-ui"
    path_to_src = "../src/search_engine_ui"
    image_tag = "${var.docker_username}/${local.service_name}:${var.app_version}"
}

module "docker" {
  source = "../docker"
  image_tag = local.image_tag
  username = var.docker_username
  password = var.docker_password
  path_to_src = local.path_to_src
}


resource "kubernetes_deployment" "service_deployment" {

    depends_on = [ module.docker ]

    metadata {
        name = local.service_name

    labels = {
            pod = local.service_name
        }
    }

    spec {
        replicas = 1

        selector {
            match_labels = {
                pod = local.service_name
            }
        }

        template {
            metadata {
                labels = {
                    pod = local.service_name
                }
            }

            spec {
                container {
                    image = local.image_tag
                    name  = local.service_name

                    env {
                        name = "PORT"
                        value = "8000"
                    }

                    env {
                        name = "MONGO"
                        value = "mongodb"
                    }

                    env {
                        name = "MONGO_PORT"
                        value = "27017"
                    }

                }

                image_pull_secrets {
                    name = var.docker_cred
                }
            }
        }
    }
}

resource "kubernetes_service" "service" {
    metadata {
        name = local.service_name
    }

    spec {
        selector = {
            pod = kubernetes_deployment.service_deployment.metadata[0].labels.pod
        }

        port {
            port = 8000
        }

    }
}


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
              name = local.service_name
              port {
                number = 8000
              }
            }
          }

          path = "/"
        }

      }
    }

  }
}