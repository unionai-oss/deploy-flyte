resource "azurerm_user_assigned_identity" "workload_identity" { 

  name = "flyte-workload-identity"
  resource_group_name = azurerm_resource_group.flyte.name 
  location = azurerm_resource_group.flyte.location 

}

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
    type = "SystemAssigned"
  }

  lifecycle {
    ignore_changes = [default_node_pool]
  }
}

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
resource "azurerm_federated_identity_credential" "federated-identity-creds" {
  name                = azurerm_user_assigned_identity.workload_identity.name
  resource_group_name = azurerm_user_assigned_identity.workload_identity.resource_group_name
  parent_id           = azurerm_user_assigned_identity.workload_identity.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.flyte.oidc_issuer_url
  #subject             = formatlist("system:serviceaccount:[%s]", local.flyte_ksa_ns)
  subject = "system:serviceaccount:flytesnacks-development:default"
}

