provider "yandex" {
  token                    = var.yc_token
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone
}

terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }

  backend "s3" {
    endpoint   = "storage.yandexcloud.net"
    bucket     = "my-bucket-state-s3"
    region     = "ru-central1-a"
    key        = "state.tfstate"
    access_key = var.access_key
    secret_key = var.secret_key

    skip_region_validation      = true
    skip_credentials_validation = true
  }
}

#data "local_file" "cluster_id" {
#  filename = "../cluster/yc_cluster_id.txt"
#}

data "yandex_kubernetes_cluster" "cluster" {
#  cluster_id = data.local_file.cluster_id.content
  cluster_id = var.cluster_id
}


provider "helm" {
  kubernetes {
    host = data.yandex_kubernetes_cluster.cluster.master[0].external_v4_endpoint
    cluster_ca_certificate = data.yandex_kubernetes_cluster.cluster.master[0].cluster_ca_certificate
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["k8s", "create-token"]
      command     = "yc"
    }
  }
}

provider "kubernetes" {

  host = data.yandex_kubernetes_cluster.cluster.master[0].external_v4_endpoint
  cluster_ca_certificate = data.yandex_kubernetes_cluster.cluster.master[0].cluster_ca_certificate
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["k8s", "create-token"]
    command     = "yc"
  }
}

module "mongo" {
  source = "./modules/mongo"
}

module "rabbit" {
  source = "./modules/rabbit"
  rmq_username = var.rmq_username
  rmq_password = var.rmq_password
}


locals {
    dockercreds = {
        auths = {
            "hub.docker.com" = {
                auth = base64encode("${var.docker_username}:${var.docker_password}")
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

module "crawler-ui" {
  source = "./modules/crawler-ui"
  depends_on = [module.rabbit,kubernetes_secret.docker_credentials]
  docker_username = var.docker_username
  docker_password = var.docker_password
  basic_auth_pass = var.basic_auth_pass
  docker_cred = kubernetes_secret.docker_credentials.metadata[0].name
}

module "crawler-engine" {
  source = "./modules/crawler-engine"
  depends_on = [module.crawler-ui]
  docker_username = var.docker_username
  docker_password = var.docker_password
  rmq_username = var.rmq_username
  rmq_password = var.rmq_password
  docker_cred = kubernetes_secret.docker_credentials.metadata[0].name
}

module "crawler-sm" {
  source = "./modules/crawler-sm"
  name = "test-sm"
  namespace = "monitoring"
  port = "crawler-engine-metrics"
  namespace_selector = "default"
  label_key = "app"
  label_value = "crawler-engine"
  depends_on = [module.crawler-engine]
}



