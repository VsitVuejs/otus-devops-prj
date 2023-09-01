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
variable "basic_auth_pass" {
  type = string
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
variable "yc_token" {
  type = string
}