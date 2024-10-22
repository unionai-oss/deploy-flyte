

resource "random_string" "storage_account_suffix" {
  length  = 6
  special = false
  upper   = false
}
resource "azurerm_storage_account" "flyte" {
  name                          = "${local.tenant}${local.environment}${random_string.storage_account_suffix.result}"
  resource_group_name           = azurerm_resource_group.flyte.name
  location                      = azurerm_resource_group.flyte.location
  account_tier                  = "Standard"
  account_replication_type      = "LRS"
  account_kind                  = "StorageV2"
  is_hns_enabled                = true
  public_network_access_enabled = true
  shared_access_key_enabled     = false
}


resource "azurerm_storage_container" "flyte" {
  name                  = "flytetf"
  storage_account_name  = azurerm_storage_account.flyte.name
  container_access_type = "private"
}

