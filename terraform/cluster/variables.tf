variable zone {
  description = "Zone"
  # Значение по умолчанию
  default = "ru-central1-a"
}
variable cloud_id {
  description = "Cloud"
}
variable folder_id {
  description = "Folder"
}
variable cluster_name {
  description = "cluster_name"
  # Значение по умолчанию
  default = "otus-prj"
}
variable "node_groups_scale" {
  default = {
    node-crawler = {
      fixed_scale = 1
    }
  }
}
variable "cluster_version" {
  type = string
  default = "1.23"
}
variable "cluster_release_channel" {
  type = string
  default = "STABLE"
}
variable "yc_token" {
  type = string
}
variable "loki_storage_size" {
  type = string
  default = "4Gi"
}
variable "loki_storage_type" {
  type = string
  default = "yc-network-ssd"
}
variable "loki_version" {
  type = string
  default = "2.8.4"
}