output "resource_group_name" {
  value = azurerm_resource_group.flyte.name
}

output "cluster_name" {
  value = azurerm_kubernetes_cluster.flyte.name
}

output "ip_dns_label" {
  value = local.flyte_domain_label
}
