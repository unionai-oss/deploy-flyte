
### IAM for stow

#locals {
#  sa_roles_for_test_user = [
#    "Contributor", "Storage Blob Data Owner"
#  ]
#}
## App registration
#resource "azuread_application" "flyte-app" {
#  display_name = "flyte-app"
#  owners       = [data.azuread_client_config.current.object_id]

#}

resource "azuread_application_registration" "flyte_app" {

display_name = "flyte-stow-app"


}

#Service Principal for Flyte tasks
resource "azuread_service_principal" "flyte_stow_sp" {
  client_id                    = azuread_application_registration.flyte_app.client_id
#  app_role_assignment_required = false
#  owners                       = [data.azuread_client_config.current.object_id]
  #app_roles                    = "Storage Blob Data Owner" 
#}

#resource "azurerm_role_assignment" "role_assignment" {
#  for_each             = { for i, v in local.sa_roles_for_test_user: v => v}
#  scope                = module.azurerm_storage_account.flyte.id
#  role_definition_name = each.value
  #principal_id         = data.azurerm_client_config.current.object_id
#  principal_id         = azuread_service_principal.flyte_sp.object_id
}

resource "azurerm_role_assignment" "flyte_sp_role_assignment" {
  scope                = azurerm_storage_account.flyte.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azuread_service_principal.flyte_stow_sp.id
  principal_type = "ServicePrincipal"
}

resource "time_rotating" "secret_rotation" {
  rotation_days = 180
}

resource "azuread_application_password" "flyte_client_secret" {
 # service_principal_id = azuread_service_principal.flyte_sp.object_id
  rotate_when_changed = {
   rotation = time_rotating.secret_rotation.id
  }
  application_id = azuread_application_registration.flyte_app.id
}