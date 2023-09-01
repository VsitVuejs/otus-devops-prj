variable "docker_username" {
  type = string
}
variable "docker_password" {
  type = string
}
variable "basic_auth_pass" {
  type = string
}
variable "app_version" {
  type = string
  default = "1.0"
}
variable "docker_cred" {
  type = string
}