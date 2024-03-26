resource "azurerm_storage_account" "flyte" {
  name                          = "${local.tenant}${local.environment}flyte"
  resource_group_name           = azurerm_resource_group.flyte.name
  location                      = azurerm_resource_group.flyte.location
  account_tier                  = "Standard"
  account_replication_type      = "LRS"
  account_kind                  = "StorageV2"
  is_hns_enabled                = true
  public_network_access_enabled = true
}

resource "azurerm_storage_container" "flyte" {
  name                  = "flyte"
  storage_account_name  = azurerm_storage_account.flyte.name
  container_access_type = "private"
}
