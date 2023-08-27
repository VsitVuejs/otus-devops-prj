locals {
    service_name = "crawler-ui"
    path_to_src = "../src/search_engine_ui"
    username = var.docker_username
    password = var.docker_password
    image_tag = "${var.docker_username}/${local.service_name}:${var.app_version}"
}

resource "null_resource" "docker_build" {

    triggers = {
        always_run = timestamp()
    }

    provisioner "local-exec" {
        command = "docker build -t ${local.image_tag} --file ${local.path_to_src}/Dockerfile ${local.path_to_src}"
    }
}

resource "null_resource" "docker_login" {

    depends_on = [ null_resource.docker_build ]

    triggers = {
        always_run = timestamp()
    }

    provisioner "local-exec" {
        command = "docker login --username ${local.username} --password ${local.password}"
    }
}

resource "null_resource" "docker_push" {

    depends_on = [ null_resource.docker_login ]

    triggers = {
        always_run = timestamp()
    }

    provisioner "local-exec" {
        command = "docker push ${local.image_tag}"
    }
}

locals {
    dockercreds = {
        auths = {
            "hub.docker.com" = {
                auth = base64encode("${local.username}:${local.password}")
            }
        }
    }
}

resource "kubernetes_secret" "docker_credentials" {
    metadata {
        name = "docker-credentials"
    }

    data = {
        ".dockerconfigjson" = jsonencode(local.dockercreds)
    }

    type = "kubernetes.io/dockerconfigjson"
}

resource "kubernetes_deployment" "service_deployment" {

    depends_on = [ null_resource.docker_push ]

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
                    name = kubernetes_secret.docker_credentials.metadata[0].name
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