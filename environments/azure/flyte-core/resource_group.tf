resource "azurerm_resource_group" "flyte" {
  name     = "${local.tenant}-${local.environment}-flyte"
  location = local.location
}
