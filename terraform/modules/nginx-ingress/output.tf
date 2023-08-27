output "nginx-ingress" {
  value = data.kubernetes_service.nginx-ingress
}