# Flyte on GCP

Prerequisites:

- [terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli#install-terraform)

Procedure:

1. Create a project on GCP and get its PROJECT_ID:

    ```bash
    gcloud projects list
    ```
>NOTE: learn how to setup the gcloud CLI [here](https://cloud.google.com/sdk/docs/initializing#initialize_the)

2. Acquire credentials to access the new project:

```bash
gcloud auth application-default login
```

3. Create a bucket in the project and region where you will deploy Flyte, leaving public access off. 

4. Go to `locals.tf` and change the following variables to your environment specifics:

| Key      | Value |Notes |
| ----------- | ----------- |-----|
| `application`      | Use your own/leave default      |    This is just a label  |
| `environment`  | Use your own/leave default    |  This is just a label    |
| `project_id` | your GPC project ID |
`dns-domain` | A DNS domain you own, so SSL certificates can be generated|
|`region` | The GCP region you'll use |

5. Save your changes.
6. Go to `terraform.tf` and replace the name of the GCS bucket you created in step 2 in the appropiate section:

```json
...
backend "gcs" {
    bucket = <your-GCS-state-bucket> 
  }
```

7. Initialize your Terraform environment:
```bash
terraform init
```
8. Then:

```bash
terraform plan
```
9. Verify changes to be applied and run:
```bash
terraform apply
```
Example output:
```bash


**Once everything is installed**:

1. Generate the `kubeconfig` entry for your new GKE cluster:

```bash
gcloud container clusters get-credentials <gke-cluster-name> --region <your-GCP-region> --project <your-project_id>
```

2. Obtain the IP address for your Ingress resource:

```bash
kubectl get ingress -n flyte
```

Example output:

```bash
NAME              CLASS    HOSTS                     ADDRESS         PORTS     AGE
flyte-core        <none>   flyteontf.uniondemo.run   35.237.42.230   80, 443   3m1s
flyte-core-grpc   <none>   flyteontf.uniondemo.run   35.237.42.230   80, 443   3m1s
```
3. Create a DNS `A` record in a zone you own, pointing to the Ingress IP.
4. Update your `$HOME\.flyte\config,yaml` and make `endpoint` your DNS name:
```yaml
...
#Example
endpoint: dns://flyteontf.uniondemo.run 
```

> NOTE: this is only needed for CLI access (`flytectl` or `pyflyte`)

### Testing your deployment


5. In your browser, go to `https://<your-DNS-record>/console`