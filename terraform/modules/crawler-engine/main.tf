locals {
    service_name = "crawler-engine"
    path_to_src = "../src/search_engine_crawler"
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
                        name = "MONGO"
                        value = "mongodb"
                    }
                    env {
                        name = "MONGO_PORT"
                        value = "27017"
                    }
                    env {
                        name = "RMQ_HOST"
                        value = "rabbit"
                    }
                    env {
                        name = "RMQ_QUEUE"
                        value = "crawler_queue"
                    }
                    env {
                        name = "RMQ_USERNAME"
                        value = var.rmq_username
                    }
                    env {
                        name = "RMQ_PASSWORD"
                        value = var.rmq_password
                    }
                    env {
                        name = "CHECK_INTERVAL"
                        value = "10"
                    }
                    env {
                        name = "EXCLUDE_URLS"
                        value = ".*github.com"
                    }

                }

                image_pull_secrets {
                    name = "docker-credentials"
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
