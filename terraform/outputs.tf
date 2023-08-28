#output "ingress_auth_pass" {
#  sensitive = true
#  value = random_password.ingress_auth.result
#}
#
#output "cluster_cluster_ca_certificate" {
#  value = yandex_kubernetes_cluster.otus-cluster-kuber.master[0].cluster_ca_certificate
#}
#
#output "cluster_client_certificate" {
#  value = yandex_kubernetes_cluster.otus-cluster-kuber.master[0].
#}
#
#output "cluster_cluster_ca_certificate" {
#  value = yandex_kubernetes_cluster.otus-cluster-kuber.master[0].cluster_ca_certificate
#}
#
#output "cluster_cluster_username" {
#  value = azurerm_kubernetes_cluster.cluster.kube_config[0].username
#}
#
#output "cluster_cluster_password" {
#  value = azurerm_kubernetes_cluster.cluster.kube_config[0].password
#}
#
#output "cluster_kube_config" {
#  value = azurerm_kubernetes_cluster.cluster.kube_config_raw
#}
#
#output "cluster_load_balancer_ip" {
#  value = module.crawler-ui.load_balancer_ingress
#}
output "cluster_load_balancer_ip" {
  value = module.nginx-ingress.cluster_load_balancer_ip
}