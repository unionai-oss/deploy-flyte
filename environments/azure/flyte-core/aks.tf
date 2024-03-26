resource "azurerm_kubernetes_cluster" "flyte" {
  name                = "${local.tenant}-${local.environment}-flyte"
  location            = azurerm_resource_group.flyte.location
  resource_group_name = azurerm_resource_group.flyte.name
  dns_prefix          = "${local.tenant}${local.environment}flyte"
  kubernetes_version  = "1.29.0"

  default_node_pool {
    name                = "default"
    vm_size             = "Standard_D2_v2"
    node_count          = 1
    min_count           = 1
    max_count           = 10
    enable_auto_scaling = true
  }

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    ignore_changes = ["default_node_pool"]
  }
}
