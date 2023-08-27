variable public_key_path {
  description = "Path to the public key used for ssh access"
}
variable network_id {
description = "Network for modules"
}
variable subnet_id {
description = "Subnets for modules"
}
variable version_id {
description = "Version kubernetes"
}
variable private_key_path {
  # Описание переменной
  description = "Path to the private key used for ssh access"
}
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
variable service_account_key_file {
  description = "key .json"
}
variable app_disk_image {
  description = "Disk image for reddit app"
  default     = "reddit-app-base"
}
variable count_ci {
  description = "count compute instance"
  # Значение по умолчанию
  default = "1"
}
variable cluster_name {
  description = "cluster_name"
  # Значение по умолчанию
  default = "otus-prj"
}

variable "node_groups_scale" {
  default = {
    service = {
      fixed_scale = 1
    }
  }
}
variable "basic_auth_pass" {
  type = string
}
variable "cluster_version" {
  type = string
  default = "1.23"
}
variable "cluster_release_channel" {
  type = string
  default = "STABLE"
}
variable "docker_login" {
  type = string
  default = "vsit"
}
variable "docker_username" {
  type = string
}
variable "docker_password" {
  type = string
}
variable "rmq_username" {
  type = string
}
variable "rmq_password" {
  type = string
}