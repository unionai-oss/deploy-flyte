resource "azurerm_resource_group" "flyte" {
  name     = "${local.tenant}-${local.environment}-flytetf"
  location = local.location
}
