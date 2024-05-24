
data "azuread_client_config" "current" {}

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

# Federated Identity for the ServiceAccount used by the Pods bootstraped by Flyte with each execution
resource azuread_application_federated_identity_credential "flyte_tasks_federated_identity"{
for_each = local.flyte_ksa_ns
application_id = azuread_application.flyte_app.id
display_name = trimsuffix(each.value, ":default" )
audiences = ["api://AzureADTokenEchange"]
issuer = azurerm_kubernetes_cluster.flyte.oidc_issuer_url 
subject = format("system:serviceaccount:%s", each.value)
}

#These are individual KSAs that the flyte-core Helm chart creates. 
#They are also the components that require access to blob storage.
locals {
  flyte_backend_ksas = ["flytepropeller","flyteadmin","datacatalog"]

}
# Federated Identity for the Flyte backend components

resource azuread_application_federated_identity_credential "flyte_backend_federated_identity"{
for_each = toset(local.flyte_backend_ksas)
application_id = azuread_application.flyte_app.id
display_name = each.key
audiences = ["api://AzureADTokenExchange"]
issuer = azurerm_kubernetes_cluster.flyte.oidc_issuer_url 

subject =format("system:serviceaccount:flyte:%s", each.value)
}

## Role assignment for stow
locals {
  sa_roles_for_stow = [
     "Storage Blob Data Owner"
  ]
}

resource "azurerm_role_assignment" "stow_role_assignment" {
  for_each             = { for i, v in local.sa_roles_for_stow: v => v}
  scope                = azurerm_storage_account.flyte.id
  role_definition_name = each.value
  principal_id         = azuread_service_principal.flyte_stow_sp.object_id
}