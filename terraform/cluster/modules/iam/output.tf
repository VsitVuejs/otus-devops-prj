output "cluster_service_account_id" {
  value = yandex_iam_service_account.cluster.id
}
output "cluster_node_service_account_id" {
  value = yandex_iam_service_account.cluster_node.id
}
output "req" {
  value = [
    yandex_iam_service_account.cluster,
    yandex_iam_service_account.cluster_node,
    yandex_resourcemanager_folder_iam_member.cluster-admin,
    yandex_resourcemanager_folder_iam_member.cluster_node-admin,
  ]
}