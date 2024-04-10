#Installs the flyte-core Helm chart in the flyte namespace using the outputs of Terraform modules
resource "helm_release" "flyte-core" {
  name             = "flyte-core"
  namespace        = "flyte"
  create_namespace = true
  repository       = "https://flyteorg.github.io/flyte"
  chart            = "flyte-core"
  version          = "1.9.0"
  values = [templatefile("values-aks.yaml", {
    cosmos_postgres_user           = "flyte"
    cosmos_postgres_password       = random_password.postgres.result
    cosmos_postgres_database_name  = azurerm_postgresql_flexible_server_database.flyte.name
    cosmos_postgres_database_host  = azurerm_postgresql_flexible_server.flyte.fqdn
    storage_account_container_name = azurerm_storage_container.flyte.name
    storage_account_name           = azurerm_storage_account.flyte.name
    storage_account_key            = azurerm_storage_account.flyte.primary_access_key
    dns_label                      = "${local.flyte_domain_label}.${local.location}.cloudapp.azure.com"
    }
    )
  ]
  depends_on = [azurerm_postgresql_flexible_server_firewall_rule.all, azurerm_postgresql_flexible_server_database.flyte]
  # provisioner "local-exec" {
  #   command = "az aks get-credentials --resource-group ${azurerm_resource_group.flyte.name} --name ${azurerm_kubernetes_cluster.flyte.name} --overwrite-existing"
  # }
}
