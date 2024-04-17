output "resource_group_name" {
  value = azurerm_resource_group.flyte.name
}

output "cluster_name" {
  value = azurerm_kubernetes_cluster.flyte.name
}

output "ip_dns_label" {
  value = local.flyte_domain_label
}

output "service_principal_id" {
  value =  azuread_service_principal.flyte_sp.client_id

}

output "service_principal_secret" {

 value = azuread_service_principal_password.flyte_client_secret.value
 sensitive = true
}
