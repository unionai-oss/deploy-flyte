
data "azuread_client_config" "current" {}
### IAM for stow

resource "azuread_application" "flyte_app" {
  display_name = "flyte_app"
  owners       = [data.azuread_client_config.current.object_id]
}

#Service Principal for Flyte tasks
resource "azuread_service_principal" "flyte_stow_sp" {
  client_id                    = azuread_application.flyte_app.client_id
  app_role_assignment_required = true
  owners                       = [data.azuread_client_config.current.object_id]
}


locals {
  flyte_ksas = ["default"] #The KSA that Task Pods will use 
}
locals {
  flyte_ksa_ns = toset([
    for tpl in setproduct(
      local.flyte_projects,
      local.flyte_domains,
      local.flyte_ksas
    ) : format("%s-%s:%s", tpl...)
  ])
}

#WI Step 3
#Pending to be handled as a list
resource azuread_application_federated_identity_credential "workload_identity_service_account_propeller"{
application_id = azuread_application.flyte_app.id
display_name = "flytepropeller"
audiences = ["api://AzureADTokenExchange"]
issuer = azurerm_kubernetes_cluster.flyte.oidc_issuer_url 
subject = "system:serviceaccount:flyte:flytepropeller"
}

resource azuread_application_federated_identity_credential "workload_identity_service_account_admin"{
application_id = azuread_application.flyte_app.id
display_name = "flyteadmin"
audiences = ["api://AzureADTokenExchange"]
issuer = azurerm_kubernetes_cluster.flyte.oidc_issuer_url 
subject = "system:serviceaccount:flyte:flyteadmin"
}

resource azuread_application_federated_identity_credential "workload_identity_service_account_dc"{
application_id = azuread_application.flyte_app.id
display_name = "datacatalog"
audiences = ["api://AzureADTokenExchange"]
issuer = azurerm_kubernetes_cluster.flyte.oidc_issuer_url 
subject = "system:serviceaccount:flyte:datacatalog"
}

resource azuread_application_federated_identity_credential "workload_identity_service_account_default"{
application_id = azuread_application.flyte_app.id
display_name = "flytesnacks-development"
audiences = ["api://AzureADTokenExchange"]
issuer = azurerm_kubernetes_cluster.flyte.oidc_issuer_url 
subject = "system:serviceaccount:flytesnacks-development:default"
}
#resource azuread_application_federated_identity_credential "workload_identity_service_account"{
#for_each = local.flyte_ksa_ns
#application_id = azuread_application.flyte_app.id
#display_name = each.key
#audiences = ["api://AzureADTokenEchange"]
#issuer = azurerm_kubernetes_cluster.flyte.oidc_issuer_url 
#subject = format("system:serviceaccount:[%s]", local.flyte_ksa_ns)
#}

## Role assignment for stow
locals {
  sa_roles_for_stow = [
     "Storage Blob Data Owner"
  ]
}

resource "azurerm_role_assignment" "role_assignment" {
  for_each             = { for i, v in local.sa_roles_for_stow: v => v}
  scope                = azurerm_storage_account.flyte.id
  role_definition_name = each.value
  principal_id         = azuread_service_principal.flyte_stow_sp.object_id
}