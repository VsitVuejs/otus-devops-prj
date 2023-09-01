terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

resource "yandex_kms_symmetric_key" "key-kms-kuber" {
  name              = "key-storage"
  description       = "key-storage"
  default_algorithm = "AES_128"
  rotation_period   = "8760h" // 1 год
}

resource "yandex_kubernetes_cluster" "cluster" {
  name = var.name

  network_id = var.vpc_id

  master {
    regional {
      region = var.region

      dynamic "location" {
        for_each = var.location_subnets

        content {
          zone = location.value.zone
          subnet_id = location.value.id
        }
      }
    }

    version = var.kube_version
    public_ip = var.public
  }

  service_account_id = var.cluster_service_account_id
  node_service_account_id = var.node_service_account_id

  release_channel = var.release_channel
  network_policy_provider = "CALICO"

  depends_on = [
    var.dep
  ]

  kms_provider {
    key_id = yandex_kms_symmetric_key.key-kms-kuber.id
  }
}

module "node_groups" {
  source = "./modules/node_groups"

  cluster_id = yandex_kubernetes_cluster.cluster.id
  kube_version = var.kube_version
  location_subnets = var.location_subnets
  cluster_node_groups = var.cluster_node_groups
}

