data "azurerm_subscription" "current" {}

# WI: Step 2
resource "azurerm_user_assigned_identity" "managed_identity" { 

  name = "flyte-managed-identity"
  resource_group_name = azurerm_resource_group.flyte.name 
  location = azurerm_resource_group.flyte.location 

}


#resource "azurerm_role_assignment" "workload_identity_role" {
#  scope              = data.azurerm_subscription.current.id
#  role_definition_name = "Contributor"
#  principal_id       = azurerm_user_assigned_identity.managed_identity.principal_id
#}

#WI: step 1
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

#WI Step 3
# Federated credential for the backend
resource "azurerm_federated_identity_credential" "federated-identity-creds" {
  name                = azurerm_user_assigned_identity.managed_identity.name
  resource_group_name = azurerm_user_assigned_identity.managed_identity.resource_group_name
  parent_id           = azurerm_user_assigned_identity.managed_identity.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.flyte.oidc_issuer_url
  #subject             = formatlist("system:serviceaccount:[%s]", local.flyte_ksa_ns)
  subject = "system:serviceaccount:flyte:flytepropeller"
}

#WIP

resource "azurerm_federated_identity_credential" "federated-identity-creds-2" {
  name                = azurerm_user_assigned_identity.managed_identity.name
  resource_group_name = azurerm_user_assigned_identity.managed_identity.resource_group_name
  parent_id           = azurerm_user_assigned_identity.managed_identity.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.flyte.oidc_issuer_url
  #subject             = formatlist("system:serviceaccount:[%s]", local.flyte_ksa_ns)
  subject = "system:serviceaccount:flyte:flyteadmin"
}