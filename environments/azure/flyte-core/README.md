# Prerequisites
- terraform installed locally (version 1.3.7)
- azure cli installed (`brew update && brew install azure-cli`)
- helm installed
- having an User in our Microsoft Tenant with at least Contributor access on the unionai-playground Subscription
- log into Azure via `az login`
- Create a azure resource group & storage account & storage container for the terraform state
- Put these values into [backend.tfvars](./backend.tfvars)


# Create Cluster & Cluster Resources
- `terraform -chdir=environments/azure/flyte-core init -backend=true -backend-config=backend.tfvars`
- `terraform -chdir=environments/azure/flyte-core plan -out=out.plan`
- `terraform -chdir=environments/azure/flyte-core apply out.plan`
# Get Cluster Config
- `az aks get-credentials --resource-group unionai-playground-flyte --name unionai-playground-flyte --overwrite-existing`
- check: `k get pods -n flyte`:
```
NAME                                 READY   STATUS    RESTARTS   AGE
datacatalog-6864645db6-99msb         1/1     Running   0          6m45s
flyte-pod-webhook-848d7db899-8wltj   1/1     Running   0          6m45s
flyteadmin-6cc67b49b4-cmt7j          1/1     Running   0          6m45s
flyteconsole-68f677797f-p4s98        1/1     Running   0          6m45s
flytepropeller-b88f7bf6d-lqc8s       1/1     Running   0          6m45s
flytescheduler-844db4658c-hfrhv      1/1     Running   0          6m45s
syncresources-767d7fc77b-5mj6n       1/1     Running   0          6m45s
```

# Add ingress & TLS (We can think of also putting the following in terraform)
## add ingress
- `helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx`
- `helm repo update`
- 
```
helm install ingress-nginx ingress-nginx/ingress-nginx \
--create-namespace --namespace ingress \
--set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz
```
## assign dns label to ingress controller ip
- `./environments/azure/flyte-core/connect_flyte.sh unionai-playground-flyte unionai-playground-flyte unionai-flyte-playground`
## install cert manager

- `kubectl label namespace ingress cert-manager.io/disable-validation=true`
- `helm repo add jetstack https://charts.jetstack.io`
- `helm repo update`
- 
```
helm install cert-manager jetstack/cert-manager \
  --namespace ingress \
  --version=v1.8.0 \
  --set installCRDs=true \
  --set nodeSelector."kubernetes\.io/os"=linux
```
## apply certmanager cluster issuer
- `k apply -f environments/azure/flyte-core/cluster-issuer.yaml`

# Voila 🎉
- [unionai-flyte-playground.westus2.cloudapp.azure.com](https://unionai-flyte-playground.westus2.cloudapp.azure.com)

# Delete Cluster
- `terraform -chdir=environments/azure/flyte-core destroy`


# Things i want to improve besides better documentation
- merge values & values-aks.yaml into one file
- clean up this one yaml. A lot of unused resources in there and also references to aws
- Make use of AKS cluster workload identities and connect the to k8s service accounts
- For stow also use identities and get rid of piping the storage acccount key, this is bad practise (There was a merged PR of Terence Kent, which i cannot find atm)