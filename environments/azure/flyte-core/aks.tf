data "azurerm_subscription" "current" {}

resource "azurerm_kubernetes_cluster" "flyte" {
  name                = "${local.tenant}-${local.environment}-flytetf"
  location            = azurerm_resource_group.flyte.location
  resource_group_name = azurerm_resource_group.flyte.name
  dns_prefix          = "${local.tenant}${local.environment}flytetf"
  workload_identity_enabled = true
  oidc_issuer_enabled = true

  default_node_pool {
    name                = "default"
    vm_size             = "Standard_D2_v2"
    node_count          = 1
    min_count           = 1
    max_count           = 10
    enable_auto_scaling = true
  }

identity {
  type =  "SystemAssigned"
}
#How to enable this section to also accept a UserAssignedID
  lifecycle {
    ignore_changes = [default_node_pool]
  }
  provisioner "local-exec" {
     command = "az aks get-credentials --resource-group ${azurerm_resource_group.flyte.name} --name ${azurerm_kubernetes_cluster.flyte.name} --overwrite-existing"
   }
}

