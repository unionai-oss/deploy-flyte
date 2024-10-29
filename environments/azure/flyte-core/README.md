# Introduction

The modules in this repo have been tested with Terraform and OpenTofu, and will help you deploy a production-grade Flyte instance on Microsoft Azure including:

- AKS cluster
- Azure Database for Postgres - Flexible Server
- Azure blob storage container
- Support for Workload Identity Federation with Entra ID
- NGINX Ingress controller
- cert-manager for TLS
- Azure Container Registry
- (Optional) AKS GPU-powered node pool

# Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli#install-terraform) (version 1.3.7)
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli#install)
- [Helm](https://helm.sh/docs/intro/install/#through-package-managers)
- Your Microsoft account should have access to an Azure subscription with at least Contributor role.
- Log into Azure via `az login`


# Configure the Terraform backend

- Once logged in, create a new:
    - Storage account with default settings
    - Storage container for the Terraform state
- Put these values, including the Resource Group where the above resources were created, into [backend.tf](./backend.tf)

# Update locals values

- Go to [locals.tf](./locals.tf) and update the values to match your desired configuration.

- To automatically provide the input variables that the module needs you can uncomment and edit the values on [terraform.tfvars](./terraform.tfvars) 

# Deploy dependencies and install Flyte
1. From the `environments/azure/flyte-core` folder, initialize the Terraform backend:

```bash
cd environments/azure/flyte-core && terraform init -backend=true -backend-config=backend.tfvars
```
2. Generate a Terraform plan:

```bash
terraform plan -out=flyte.plan
```
3. Apply the plan:
```bash
terraform apply flyte.plan
```
Example output:
```bash
Apply complete! Resources: 9 added, 0 changed, 0 destroyed.

Outputs:

cluster_endpoint = "flytedeploy01.eastus.cloudapp.azure.com"
```

# Test your deployment

1. Verify Flyte's backend status


```bash
kubectl get pods -n flyte

NAME                                 READY   STATUS    RESTARTS   AGE
datacatalog-6864645db6-99msb         1/1     Running   0          6m45s
flyte-pod-webhook-848d7db899-8wltj   1/1     Running   0          6m45s
flyteadmin-6cc67b49b4-cmt7j          1/1     Running   0          6m45s
flyteconsole-68f677797f-p4s98        1/1     Running   0          6m45s
flytepropeller-b88f7bf6d-lqc8s       1/1     Running   0          6m45s
flytescheduler-844db4658c-hfrhv      1/1     Running   0          6m45s
syncresources-767d7fc77b-5mj6n       1/1     Running   0          6m45s
```
2. Update your `$HOME/.flyte/config,yaml` and configure `endpoint` with the value of the `cluster_endpoint` output:
>NOTE: installing `flytectl` will typically create an initial `config.yaml` file. [Learn more](https://docs.flyte.org/projects/flytectl/en/latest/#installation).

Example:
```yaml
...
admin:
  endpoint: dns:///flytedeploy01.eastus.cloudapp.azure.com" 
  insecure: false #it means, the connection uses SSL, even if it's a temporary cert-manager cert.
...
#Uncomment only if you want to test CLI commands and the certificate is not generated yet.
# You can confirm the cert by either going to the UI (a valid certificate should be used) or
#from your terminal: kubectl get challenges.acme.cert-manager.io -n flyte (there should not be any pending challenge). With this flag enabled, SSL is still used but the client doesn't verify the certificate chain.

  #insecureSkipVerify: true 
```
> NOTE: this configuration step is only needed for CLI access (`flytectl` or `pyflyte`), not for the UI.


3. Save the following "hello world" workflow definition:
```bash
cat << 'EOF' >hello_world.py
from flytekit import task, workflow
@task
def say_hello() -> str:
    return "hello world"
@workflow
def my_wf() -> str:
    res = say_hello()
    return res
if __name__ == "__main__":
    print(f"Running my_wf() {my_wf()}")
EOF
```
4. Execute the workflow on the Flyte cluster:
```bash
pyflyte run --remote hello_world.py my_wf
```
Example output:
```bash
Running Execution on Remote.

[✔] Go to https://flytedeploy01.eastus.cloudapp.azure.com/console/projects/flytesnacks/domains/development/executions/fae18cf6750bd4d64bc7 to see execution in the console.
```
5. Go to the console and verify the succesful execution:

![](https://raw.githubusercontent.com/flyteorg/static-resources/main/common/flyte-on-azure-execution.png)  

**Congratulations!**  
You have a fully working Flyte environment on Azure.

From this point on, you can continue your learning journey by going through the [Flyte Fundamentals](https://docs.flyte.org/en/latest/flyte_fundamentals/index.html) tutorials.

## Consuming GPU accelerators

To be able to request GPUs on Azure directly from your Flyte tasks, you have multiple options. This section covers how to use some of them with the Terraform/OpenTofu modules.

>The examples in this section use [ImageSpec](https://docs.flyte.org/en/latest/user_guide/customizing_dependencies/imagespec.html#imagespec), a Flyte feature that builds a custom container image without a Dockerfile. Install it using `pip install flytekitplugins-envd`.\

### 1. Request a generic GPU device

- Go to `aks.tf` and switch the `locals.gpu_node_pool_count` value to the number of GPU-enabled nodes you need in your AKS node pool.  
- Run a `terraform plan` + `terraform apply` operation.  
- Save the following test workflow:
```python
from flytekit import ImageSpec, Resources, task

image = ImageSpec(
    base_image= "ghcr.io/flyteorg/flytekit:py3.10-1.10.2",
     name="pytorch",
     python_version="3.10",
     packages=["torch"],
     builder="envd",
     registry="<YOUR_CONTAINER_REGISTRY>",
 )

@task(container_image=image, requests=Resources(gpu="1"))
def check_torch() -> bool:
    import torch
    return torch.cuda.is_available()

```
- Execute it remotely on your Flyte cluster:
```bash
pyflyte run --remote hello_gpu.py gpu_available
```
It should return a `True` value.

### 2. Request a specific accelerator
- Go to `values-aks.yaml` and uncomment the key `gpu-device-node-label` under `configmap.k8s.plugins.k8s`. This is an arbitrary label that is applied as a `nodeAffinity` to Pods spawned from Tasks that request a specific accelerator.  
- Go to `aks.tf` and confirm or change the `locals.accelerator` value to the GPU device model that you plan to use. Make sure to check the [supported options](https://github.com/flyteorg/flytekit/blob/daeff3f5f0f36a1a9a1f86c5e024d1b76cdfd5cb/flytekit/extras/accelerators.py#L132-L160).  
- Run a `terraform plan` + `terraform apply` operation   
- Save and execute the following test workflow, changing the GPU device model to match your environment (example with a V100):
```python
from flytekit import ImageSpec, Resources, task
from flytekit.extras.accelerators import V100

image = ImageSpec(
    base_image= "ghcr.io/flyteorg/flytekit:py3.10-1.10.2",
     name="pytorch",
     python_version="3.10",
     packages=["torch"],
     builder="envd",
     registry="<YOUR_CONTAINER_REGISTRY>",
 )

@task(requests=Resources( gpu="1"),
              accelerator=V100,
              )
def gpu_available() -> bool:
   return torch.cuda.is_available()
```
> Learn more about [accelerators in flytekit](https://docs.flyte.org/en/latest/api/flytekit/extras.accelerators.html)

### 3. Request a GPU partition 
- Go to `aks.tf` and adjust the value of the `locals.partition_size` key to your desired GPU partition size. 
> Learn more about the [supported partition profiles for NVIDIA A100 devices](https://developer.nvidia.com/blog/getting-the-most-out-of-the-a100-gpu-with-multi-instance-gpu/#mig_partitioning_and_gpu_instance_profiles)

- Run a `terraform plan` + `terraform apply` operation
- Save and execute the following test workflow, changing the GPU partition size to match your needs:
```python
from flytekit import ImageSpec, Resources, task
from flytekit.extras.accelerators import A100

image = ImageSpec(
    base_image= "ghcr.io/flyteorg/flytekit:py3.10-1.10.2",
     name="pytorch",
     python_version="3.10",
     packages=["torch"],
     builder="envd",
     registry="<YOUR_CONTAINER_REGISTRY>",
 )

@task(requests=Resources( gpu="1"),
              accelerator=A100.partition_2g_10gb,
              )
def gpu_available() -> bool:
   return torch.cuda.is_available()
``` 

Learn more about GPU configuration in the [Flyte docs](https://docs.flyte.org/en/latest/user_guide/productionizing/configuring_access_to_gpus.html#configure-gpus).

## How to tear down your deployment

1. Once you're done testing/using Flyte, just invoke the following command:

```bash
terraform destroy
```
