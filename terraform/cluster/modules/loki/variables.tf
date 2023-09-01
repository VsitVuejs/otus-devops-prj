variable "loki_storage_size" {
  type = string
}
variable "loki_storage_type" {
  type = string
  default = "yc-network-ssd"
}
variable "loki_version" {
  type = string
  default = "2.8.4"
}