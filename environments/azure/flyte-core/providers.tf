terraform {
  required_version = ">= 1.3.7"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.13.0"
    }
  }
  # https://www.terraform.io/language/settings/backends/azurerm
  backend "azurerm" {}
}

provider "azurerm" {
  features {}

  subscription_id = local.subscription_id
  tenant_id       = local.tenant_id
  storage_use_azuread = true
  use_aks_workload_identity = true
 # use_cli                   = false
}

provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.flyte.kube_config.0.host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.flyte.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.flyte.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.flyte.kube_config.0.cluster_ca_certificate)
    config_path = "~/.kube/config"
  }
}
