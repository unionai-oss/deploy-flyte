#Installs the flyte-core Helm chart in the flyte namespace using the outputs of Terraform modules
resource "helm_release" "flyte-core" {
  name             = "flyte-core"
  namespace        = "flyte"
  create_namespace = true
  repository       = "https://flyteorg.github.io/flyte"
  chart            = "flyte-core"
  timeout          = "1200"

  values = [templatefile("values-aks.yaml", {
    cosmos_postgres_user           = "flyte"
    cosmos_postgres_password       = random_password.postgres.result
    cosmos_postgres_database_name  = azurerm_postgresql_flexible_server_database.flyte.name
    cosmos_postgres_database_host  = azurerm_postgresql_flexible_server.flyte.fqdn
    storage_account_container_name = azurerm_storage_container.flyte.name
    storage_account_name           = azurerm_storage_account.flyte.name
    dns_label                      = "${local.flyte_domain_label}.${local.location}.cloudapp.azure.com"
    backend_wi_client_id           = azurerm_user_assigned_identity.flyte_admin.client_id
    tasks_wi_client_id             = azurerm_user_assigned_identity.flyte_user.client_id
    }
    )
  ]
  depends_on = [azurerm_postgresql_flexible_server_firewall_rule.all, azurerm_postgresql_flexible_server_database.flyte, azurerm_role_assignment.admin_role_assignment, azurerm_kubernetes_cluster.flyte, azurerm_federated_identity_credential.flyte_admin_federated_identity]

}
