output "cluster_load_balancer_ip" {
  value = module.nginx-ingress.cluster_load_balancer_ip
}
output "cluster_id" {
  value = module.cluster.cluster_id
}
resource "local_file" "file_cluster_id" {
    content  = module.cluster.cluster_id
    filename = "yc_cluster_id.txt"
}