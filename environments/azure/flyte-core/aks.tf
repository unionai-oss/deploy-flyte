data "azurerm_subscription" "current" {}


#Use the following keys to configure a GPU node pool as part of the AKs cluster
#gpu_node_pool_count = 0 disables the provisioning of the node pool and the GPU-related prerequisites.
locals {
  gpu_settings = {
  gpu_node_pool_count          = 1
  gpu_machine_type             = "Standard_NC24ads_A100_v4" #Change it to the GPU-powered instance type you're using
  accelerator                  = "nvidia-tesla-a100" #Supported options: https://github.com/flyteorg/flytekit/blob/daeff3f5f0f36a1a9a1f86c5e024d1b76cdfd5cb/flytekit/extras/accelerators.py#L132-L160 - Change to "None" if don't plan to request specific accelerator models.
  partition_size               = "2g.10gb" #Only for MIG-enabled devices. Change to "None" for unpartiiooned devices.Learn more: https://developer.nvidia.com/blog/getting-the-most-out-of-the-a100-gpu-with-multi-instance-gpu/#mig_partitioning_and_gpu_instance_profiles
  gpu_node_pool_disk_size      = 100
  gpu_node_pool_max_count      = 3
  gpu_node_pool_min_count      = 1
  additional_taints            = "" #Expressed in the format key=value:effect. Omit "=value" if the operator is "Exists"
  }

}

resource "azurerm_kubernetes_cluster" "flyte" {
  name                      = "${local.tenant}-${local.environment}-flytetf"
  location                  = azurerm_resource_group.flyte.location
  resource_group_name       = azurerm_resource_group.flyte.name
  dns_prefix                = "${local.tenant}${local.environment}flytetf"
  workload_identity_enabled = true
  oidc_issuer_enabled       = true

  default_node_pool {
    name                = "cpupool"
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
  provisioner "local-exec" {
    command = "az aks get-credentials --resource-group ${azurerm_resource_group.flyte.name} --name ${azurerm_kubernetes_cluster.flyte.name} --overwrite-existing"
  }
}

# Additional pre-requisites for GPU scheduling
resource "azurerm_kubernetes_cluster_node_pool" "gpu_nodes" {
count = local.gpu_settings.gpu_node_pool_count == 0 ? 0 : 1
depends_on = [ azurerm_kubernetes_cluster.flyte ]
name = "gpupool"
kubernetes_cluster_id = azurerm_kubernetes_cluster.flyte.id
node_count = local.gpu_settings.gpu_node_pool_count
enable_auto_scaling = true
min_count           = local.gpu_settings.gpu_node_pool_min_count
max_count           = local.gpu_settings.gpu_node_pool_max_count
vm_size             = local.gpu_settings.gpu_machine_type
os_disk_size_gb    = local.gpu_settings.gpu_node_pool_disk_size

#Only used in case you request specific accelerators and/or partitions. Additional configuration may be required.
# Learn more: https://docs.flyte.org/en/latest/user_guide/productionizing/configuring_access_to_gpus.html

node_labels = merge(
  local.gpu_settings.accelerator != "None" ? {
    "nvidia.com/gpu.accelerator" : "${local.gpu_settings.accelerator}"
  }: {},
  local.gpu_settings.partition_size != "None" ? {
   "nvidia.com/gpu.partition-size" : "${local.gpu_settings.partition_size}" 
  } : {},
)
#The matching toleration is automatically inserted by flytepropeller when you request a GPU (Requests=Resources(gpu=1))
node_taints = [
  "nvidia.com/gpu:NoSchedule",
  ]
}

resource "kubectl_manifest" "gpu-operator-ns"{
 count = local.gpu_settings.gpu_node_pool_count == 0 ? 0 : 1 
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
  count = local.gpu_settings.gpu_node_pool_count == 0 ? 0 : 1
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
