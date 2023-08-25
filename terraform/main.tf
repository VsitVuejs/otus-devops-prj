terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

provider "yandex" {
  service_account_key_file = var.service_account_key_file
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
      memory = 8
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

#resource "yandex_kms_symmetric_key" "key-kuber" {
#  name              = "key-storage"
#  description       = "key-storage"
#  default_algorithm = "AES_128"
#  rotation_period   = "8760h" // 1 год
#}
#
#
#resource "yandex_kubernetes_cluster" "otus-cluster-kuber" {
#  name        = "otus-cluster-kuber"
#  description = "description"
#
#  network_id = var.network_id
#
#  master {
#    version = var.version_id
#    zonal {
#      zone      = var.zone
#      subnet_id = var.subnet_id
#    }
#
#    public_ip = true
#
#  }
#
#  service_account_id      = yandex_iam_service_account.sa-kuber.id
#  node_service_account_id = yandex_iam_service_account.sa-kuber.id
#
#  release_channel = "RAPID"
#  network_policy_provider = "CALICO"
#
#  kms_provider {
#    key_id = yandex_kms_symmetric_key.key-kuber.id
#  }
#}
#
#resource "yandex_kubernetes_node_group" "kuber-node-group" {
#  cluster_id  = yandex_kubernetes_cluster.otus-cluster-kuber.id
#  name        = "kuber-node-group"
#  description = "description"
#  version     = var.version_id
#
#  instance_template {
#    platform_id = "standard-v2"
#
#    network_interface {
#      nat                = true
#      subnet_ids         = [var.subnet_id]
#    }
#
#    resources {
#      memory = 8
#      cores  = 2
#    }
#
#    boot_disk {
#      type = "network-ssd"
#      size = 30
#    }
#
#    scheduling_policy {
#      preemptible = false
#    }
#
#    container_runtime {
#      type = "containerd"
#    }
#  }
#
#  scale_policy {
#    fixed_scale {
#      size = var.count_ci
#    }
#  }
#
#  allocation_policy {
#    location {
#      zone = "ru-central1-a"
#    }
#  }
#}
#
#provider "helm" {
#  kubernetes {
#    host                   = yandex_kubernetes_cluster.otus-cluster-kuber.master[0].external_v4_endpoint
#    cluster_ca_certificate = yandex_kubernetes_cluster.otus-cluster-kuber.master[0].cluster_ca_certificate
#    exec {
#      api_version = "client.authentication.k8s.io/v1beta1"
#      args        = ["k8s", "create-token"]
#      command     = "yc"
#    }
#  }
#}
#
#provider "kubernetes" {
#
#  host = yandex_kubernetes_cluster.otus-cluster-kuber.master[0].external_v4_endpoint
#  cluster_ca_certificate = yandex_kubernetes_cluster.otus-cluster-kuber.master[0].cluster_ca_certificate
#  exec {
#    api_version = "client.authentication.k8s.io/v1beta1"
#    args        = ["k8s", "create-token"]
#    command     = "yc"
#  }
#}
#
#resource "kubernetes_deployment" "database" {
#  metadata {
#    name = "database"
#
#    labels = {
#      pod = "database"
#    }
#  }
#
#  spec {
#    replicas = 1
#
#    selector {
#      match_labels = {
#        pod = "database"
#      }
#    }
#
#    template {
#      metadata {
#        labels = {
#          pod = "database"
#        }
#      }
#
#      spec {
#        container {
#          image = "mongo:4.2.8"
#          name  = "database"
#
#          port {
#            container_port = 27017
#          }
#        }
#      }
#    }
#  }
#}
#
#resource "kubernetes_service" "database" {
#    metadata {
#        name = "database"
#    }
#
#    spec {
#        selector = {
#            pod = kubernetes_deployment.database.metadata[0].labels.pod
#        }
#
#        port {
#            port         = 27017
#        }
#
##        type             = "LoadBalancer"
#    }
#}