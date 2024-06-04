
resource "azurerm_user_assigned_identity" "flyte_backend" {
  location            = azurerm_resource_group.flyte.location
  name                = "${local.tenant}-${local.environment}-flyte-backend"
  resource_group_name = azurerm_resource_group.flyte.name
}
resource "azurerm_user_assigned_identity" "flyte_user" {
  location            = azurerm_resource_group.flyte.location
  name                = "${local.tenant}-${local.environment}-flyte-user"
  resource_group_name = azurerm_resource_group.flyte.name
}

locals {
  flyte_ksas = ["default"] #The Kubernetes ServiceAccount that Task Pods will use 
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

#Federated Identity for the Flyte User's ServiceAccounts
resource "azurerm_federated_identity_credential" "flyte_user_federated_identity" {
  for_each            = local.flyte_ksa_ns
  name                = replace(each.value, ":", "-")
  resource_group_name = azurerm_resource_group.flyte.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.flyte.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.flyte_user.id
  subject             = format("system:serviceaccount:%s", each.value)
}

#These are individual KSAs that the flyte-core Helm chart creates. 
#They are also the backend components that require access to blob storage.
locals {
  flyte_backend_ksas = ["flytepropeller", "flyteadmin", "datacatalog"]

}
# Federated Identity for the Flyte Admin components
resource "azurerm_federated_identity_credential" "flyte_backend_federated_identity" {
  for_each            = toset(local.flyte_backend_ksas)
  name                = each.value
  resource_group_name = azurerm_resource_group.flyte.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.flyte.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.flyte_backend.id
  subject             = format("system:serviceaccount:flyte:%s", each.value)
}

## Role assignment for stow (backend module used by Flyte to access blob storage)
locals {
  sa_roles_for_stow = [
    "Storage Blob Data Owner"
  ]
}

#Role assignment for Flyte User Managed Identity
resource "azurerm_role_assignment" "user_role_assignment" {
  for_each             = { for i, v in local.sa_roles_for_stow : v => v }
  scope                = azurerm_storage_account.flyte.id
  role_definition_name = each.value
  principal_id         = azurerm_user_assigned_identity.flyte_user.principal_id
}

#Role assignment for Flyte Admin Managed Identity
resource "azurerm_role_assignment" "backend_role_assignment" {
  for_each             = { for i, v in local.sa_roles_for_stow : v => v }
  scope                = azurerm_storage_account.flyte.id
  role_definition_name = each.value
  principal_id         = azurerm_user_assigned_identity.flyte_backend.principal_id
}
