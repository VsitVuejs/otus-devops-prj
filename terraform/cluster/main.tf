terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

provider "yandex" {
  token                    = var.yc_token
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone
}

locals {
  cluster_service_account_name      = "${var.cluster_name}-cluster"
  cluster_node_service_account_name = "${var.cluster_name}-node"

  cluster_node_group_configs = {
    node-crawler = {
      name = "node-crawler"
      cpu = 2
      memory = 16
      disk = {
        size = 32
        type = "network-ssd"
      }
    }
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

module "bucket" {
  source = "./modules/bucket"
  folder_id = var.folder_id
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

  node_selector = local.node_selectors["node-crawler"]
  external_v4_endpoint = module.cluster.external_v4_endpoint
  depends_on = [module.cluster]
}

module "kube-prometheus" {
  source = "./modules/kube-prometheus"
  kube-version = "36.2.0"
  namespace = "monitoring"
  depends_on = [module.cluster]
}

module "loki" {
  source = "./modules/loki"
  loki_storage_size = var.loki_storage_size
  loki_storage_type = var.loki_storage_type
  loki_version = var.loki_version
  depends_on = [module.cluster]
}

#module "test-app" {
#  source = "./modules/test-app"
#  depends_on = [module.cluster]
#  basic_auth_pass = var.basic_auth_pass
#}
