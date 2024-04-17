data "azuread_client_config" "current" {}

## This section implements the requirements to use Azure AD for stow, the Go library that 
## interfaces between Flyte and Azure Blob Storage:

resource "azurerm_storage_account" "flyte" {
  name                          = "${local.tenant}${local.environment}flytetf"
  resource_group_name           = azurerm_resource_group.flyte.name
  location                      = azurerm_resource_group.flyte.location
  account_tier                  = "Standard"
  account_replication_type      = "LRS"
  account_kind                  = "StorageV2"
  is_hns_enabled                = true
  public_network_access_enabled = true
  shared_access_key_enabled     = true
}

data "azurerm_client_config" "current" {}
resource "azurerm_storage_container" "flyte" {
  name                  = "flytetf"
  storage_account_name  = azurerm_storage_account.flyte.name
  container_access_type = "private"
}

locals {
  sa_roles_for_test_user = [
    "Contributor", "Storage Blob Data Owner"
  ]
}

resource "azurerm_role_assignment" "role_assignment" {
  for_each             = { for i, v in local.sa_roles_for_test_user: v => v}
  scope                = azurerm_storage_account.flyte.id
  role_definition_name = each.value
  principal_id         = data.azurerm_client_config.current.object_id
}
## App registration
resource "azuread_application" "flyte-app" {
  display_name = "flyte"
  owners       = [data.azuread_client_config.current.object_id]
}
# Service Principal for Flyte tasks
resource "azuread_service_principal" "flyte_sp" {
  client_id                    = azuread_application.flyte-app.client_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.current.object_id]
 # app_roles                    = "Storage Blob Data Owner" 
}

resource "azurerm_role_assignment" "flyte_sp_role_assignment" {
  scope                = azurerm_storage_account.flyte.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azuread_service_principal.flyte_sp.object_id
}

resource "time_rotating" "secret_rotation" {
  rotation_days = 30
}

resource "azuread_service_principal_password" "flyte_client_secret" {
  service_principal_id = azuread_service_principal.flyte_sp.object_id
  rotate_when_changed = {
    rotation = time_rotating.secret_rotation.id
  }
}