
data "azuread_client_config" "current" {}
### IAM for stow

locals {
  sa_roles_for_flyte_sp = [
    "b24988ac-6180-42a0-ab88-20f7382dd24c", "b7e6dc6d-f1e8-4753-8033-0f276bb0955b"
  ]
}
## App registration
resource "random_uuid" "role_id" {
}

resource "azuread_application" "flyte_app" {
  display_name = "flyte_app"
  owners       = [data.azuread_client_config.current.object_id]

app_role {
  allowed_member_types = ["Application"]
  description = "This is for stow"
  display_name = "Stow"
  id = "${random_uuid.role_id.result}"
  value = "Admin.All"
}
}

#resource "azuread_application_registration" "flyte_app" {

#display_name = "flyte-stow-app"



#}

#Service Principal for Flyte tasks
resource "azuread_service_principal" "flyte_stow_sp" {
  client_id                    = azuread_application.flyte_app.client_id
  app_role_assignment_required = true
  owners                       = [data.azuread_client_config.current.object_id]
}

#resource "azuread_app_role_assignment" "role_assignment" {
 # for_each             = { for i, v in local.sa_roles_for_flyte_sp: v => v}
 # app_role_id          = azuread_application.flyte_app.app_role_ids["Admin.All"]
 # principal_object_id  = azuread_application.flyte_app.object_id
 # resource_object_id   = azuread_service_principal.flyte_stow_sp.object_id
  
#}


#resource "time_rotating" "secret_rotation" {
#  rotation_days = 180
#}

#resource "azuread_application_password" "flyte_client_secret" {
 # service_principal_id = azuread_service_principal.flyte_sp.object_id
  #rotate_when_changed = {
 #  rotation = time_rotating.secret_rotation.id
  #}
  #application_id = azuread_application.flyte_app.id
#}

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
    "Contributor", "Storage Blob Data Owner"
  ]
}

resource "azurerm_role_assignment" "role_assignment" {
  for_each             = { for i, v in local.sa_roles_for_stow: v => v}
  scope                = azurerm_storage_account.flyte.id
  role_definition_name = each.value
  principal_id         = azuread_service_principal.flyte_stow_sp.object_id
}