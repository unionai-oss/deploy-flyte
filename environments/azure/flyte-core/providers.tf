terraform {
  required_version = ">= 1.3.7"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.13.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
  }
  
}

provider "kubectl" {
  host                   = azurerm_kubernetes_cluster.flyte.kube_config.0.host
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.flyte.kube_config.0.cluster_ca_certificate)
  token                  = yamldecode(azurerm_kubernetes_cluster.flyte.kube_config_raw).users[0].user.token
  load_config_file       = false
}
provider "azurerm" {
  features {}

  subscription_id           = var.subscription_id
  tenant_id                 = var.tenant_id
  use_aks_workload_identity = true
  storage_use_azuread       = true

}

provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.flyte.kube_config.0.host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.flyte.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.flyte.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.flyte.kube_config.0.cluster_ca_certificate)
    config_path            = "~/.kube/config"
  }
}
