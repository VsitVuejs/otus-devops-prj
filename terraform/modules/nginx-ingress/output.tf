output "load_balancer_ip" {
  value = data.kubernetes_service.nginx-ingress
}