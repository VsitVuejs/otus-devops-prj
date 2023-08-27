output "docker_cred_name" {
  value = kubernetes_secret.docker_credentials.metadata[0].name
}