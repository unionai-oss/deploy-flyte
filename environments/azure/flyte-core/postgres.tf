resource "random_password" "postgres" {
  length           = 20
  special          = true
  #override_special = "_%@"
}


resource "azurerm_postgresql_flexible_server" "flyte" {
  name                   = "${local.tenant}-${local.environment}-flyte"
  resource_group_name    = azurerm_resource_group.flyte.name
  location               = azurerm_resource_group.flyte.location
  version                = "15"
  administrator_login    = "flyte"
  administrator_password = random_password.postgres.result
  storage_mb             = 32768
  sku_name               = "B_Standard_B1ms"

  lifecycle {
      ignore_changes = [
        zone,
        high_availability.0.standby_availability_zone
      ]
  }
}

resource "azurerm_postgresql_flexible_server_database" "flyte" {
  name      = "flyte"
  server_id = azurerm_postgresql_flexible_server.flyte.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "all" {
  name             = "all"
  server_id        = azurerm_postgresql_flexible_server.flyte.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "255.255.255.255"
}
