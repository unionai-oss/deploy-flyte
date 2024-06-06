data "azurerm_subscription" "current" {}

#Use the following keys to configure a GPU node pool as part of the AKs cluster
#gpu_node_pool_count = 0 disables the provisioning of the node pool and the GPU-related prerequisites.
locals {
  gpu_node_pool_count          = 0
  gpu_machine_type             = "Standard_NC6s_v3"
  gpu_node_pool_disk_size      = 100
  gpu_node_pool_max_count      = 3
  gpu_node_pool_min_count      = 1
}

resource "azurerm_kubernetes_cluster" "flyte" {
  name                = "${local.tenant}-${local.environment}-flytetf"
  location            = azurerm_resource_group.flyte.location
  resource_group_name = azurerm_resource_group.flyte.name
  dns_prefix          = "${local.tenant}${local.environment}flytetf"
  workload_identity_enabled = true
  oidc_issuer_enabled = true

  default_node_pool {
    name                = "cpupool"
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
}

# Additional pre-requisites for GPU scheduling
resource "azurerm_kubernetes_cluster_node_pool" "gpu_nodes" {
count = local.gpu_node_pool_count == 0 ? 0 : 1
depends_on = [ azurerm_kubernetes_cluster.flyte ]
name = "gpupool"
kubernetes_cluster_id = azurerm_kubernetes_cluster.flyte.id
node_count = local.gpu_node_pool_count
enable_auto_scaling = true
min_count           = local.gpu_node_pool_min_count
max_count           = local.gpu_node_pool_max_count
vm_size             = local.gpu_machine_type
os_disk_size_gb    = local.gpu_node_pool_disk_size
}

resource "kubectl_manifest" "gpu-operator-ns"{
 count = local.gpu_node_pool_count == 0 ? 0 : 1 
  yaml_body = (<<-YAML
apiVersion: v1
kind: Namespace
metadata:
  name: "gpu-operator"
  labels:
    cluster: ${azurerm_kubernetes_cluster.flyte.name}
    managed_by: "Terraform"  
  annotations:
    name: "gpu-operator"
    YAML
     )
}

/***************************
GPU Operator Configuration
***************************/
resource "helm_release" "gpu-operator" {
  count = local.gpu_node_pool_count == 0 ? 0 : 1
  depends_on       = [azurerm_kubernetes_cluster_node_pool.gpu_nodes, kubectl_manifest.gpu-operator-ns]
  name             = "gpu-operator"
  repository       = "https://helm.ngc.nvidia.com/nvidia"
  chart            = "gpu-operator"
  namespace        = "gpu-operator"
  create_namespace = false
  atomic           = true
  cleanup_on_fail  = true
  reset_values     = true
  replace          = true

  set {
    name  = "toolkit.enabled"
    value = "true"
  }

  set {
    name  = "operator.cleanupCRD"
    value = "true"
  }

  set {
    name  = "driver.enabled"
    value = "false"
  }

}