resource "azurerm_container_registry" "acr" {
  name                = "${local.tenant}${local.environment}images"
  resource_group_name = azurerm_resource_group.flyte.name
  location            = azurerm_resource_group.flyte.location
  sku                 = "Premium"
}

# ACR Pull for flyte cluster kubelet identity
resource "azurerm_role_assignment" "flyte_user_role_acr_pull" {
  scope                            = azurerm_container_registry.acr.id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_kubernetes_cluster.flyte.kubelet_identity[0].object_id
  skip_service_principal_aad_check = true
}

# ACR Push for current logged in user
data "azurerm_client_config" "user" {
}
resource "azurerm_role_assignment" "current_user_role_acr_push" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPush"
  principal_id         = data.azurerm_client_config.user.object_id

  depends_on = [ azurerm_container_registry.acr ]
}
