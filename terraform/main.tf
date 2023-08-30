terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

provider "yandex" {
#  service_account_key_file = var.service_account_key_file
  token                    = var.yc_token
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone
}

locals {
  cluster_service_account_name      = "${var.cluster_name}-cluster"
  cluster_node_service_account_name = "${var.cluster_name}-node"

  cluster_node_group_configs = {
    service = {
      name = "service"
      cpu = 2
      memory = 16
      disk = {
        size = 32
        type = "network-ssd"
      }
    }
#    service2 = {
#      name = "service"
#      cpu = 2
#      memory = 8
#      disk = {
#        size = 32
#        type = "network-ssd"
#      }
#    }
  }

  node_selectors = {
    for key, id in module.cluster.node_group_ids:
      key => {
        "yandex.cloud/node-group-id" = id
      }
  }

  cluster_node_groups = {
    for key, config in local.cluster_node_group_configs:
      key => merge(config, {
        fixed_scale = lookup(var.node_groups_scale[key], "fixed_scale", false) != false ? [var.node_groups_scale[key].fixed_scale] : []
        auto_scale = lookup(var.node_groups_scale[key], "auto_scale", false) != false ? [var.node_groups_scale[key].auto_scale] : []
      })
  }
}

module "vpc" {
  source = "./modules/vpc"
  name = var.cluster_name
}

module "iam" {
  source = "./modules/iam"

  cluster_folder_id = var.folder_id
  cluster_service_account_name = local.cluster_service_account_name
  cluster_node_service_account_name = local.cluster_node_service_account_name
}


module "cluster" {
  source = "./modules/cluster"

  name = var.cluster_name
  public = true
  kube_version = var.cluster_version
  release_channel = var.cluster_release_channel
  vpc_id = module.vpc.vpc_id
  location_subnets = module.vpc.location_subnets
  cluster_service_account_id = module.iam.cluster_service_account_id
  node_service_account_id = module.iam.cluster_node_service_account_id
  cluster_node_groups = local.cluster_node_groups
#  ssh_keys = module.admins.ssh_keys
  dep = [
    module.iam.req
  ]
}

provider "helm" {
  kubernetes {
    host = module.cluster.external_v4_endpoint
    cluster_ca_certificate = module.cluster.ca_certificate
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["k8s", "create-token"]
      command     = "yc"
    }
  }
}

provider "kubernetes" {

  host = module.cluster.external_v4_endpoint
  cluster_ca_certificate = module.cluster.ca_certificate
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["k8s", "create-token"]
    command     = "yc"
  }
}

module "nginx-ingress" {
  source = "./modules/nginx-ingress"

  node_selector = local.node_selectors["service"]
  external_v4_endpoint = module.cluster.external_v4_endpoint
  depends_on = [module.cluster]
}

module "kube" {
  source = "./modules/kube-prometheus"
  kube-version = "36.2.0"
  namespace = "monitoring"
  depends_on = [module.nginx-ingress]
}

module "mongo" {
  source = "./modules/mongo"
  depends_on = [module.nginx-ingress]
}

module "rabbit" {
  source = "./modules/rabbit"
  depends_on = [module.mongo]
  rmq_username = var.rmq_username
  rmq_password = var.rmq_password
}

#module "app" {
#  source = "./modules/app"
#  depends_on = [module.rabbit]
#  basic_auth_pass = var.basic_auth_pass
#}

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

module "kube-sm" {
  source = "./modules/kube-sm"
  name = "test-sm"
  namespace = "monitoring"
  port = "crawler-engine-metrics"
  namespace_selector = "default"
  label_key = "app"
  label_value = "crawler-engine"
  depends_on = [module.crawler-engine,module.kube]
}

resource "kubernetes_persistent_volume" "pv-loki" {
    metadata {
        name = "pv-loki"
    }
    spec {
        capacity = {
            storage = "10Gi"
        }
        storage_class_name = "yc-network-ssd"
        access_modes = ["ReadWriteOnce"]
        persistent_volume_source {
            vsphere_volume {
                volume_path = "/volume"
            }
        }
    }
}

resource "helm_release" "loki3" {
  name = "loki3"

  repository       = "https://grafana.github.io/helm-charts"
  chart            = "loki-stack"
  version          = "2.8.4"
  namespace        = "logs2"
  create_namespace = true

  values = [
    templatefile("./templates/loki-values.yml", {
      STORAGE_LOCAL_PATH = "/data/loki/chunks"
    })
  ]

  depends_on = [
    module.cluster
  ]
}


