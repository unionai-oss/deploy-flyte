# Flyte on GCP

Prerequisites:

- [terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli#install-terraform)

Procedure:

1. Create a project on GCP

2. Run ``gcloud auth application-default login``
3. Confirm the ID of your project:
    ```bash
    gcloud projects list
    ```
4. Create a bucket in the project and region where you will deploy FLyte, leaving public access off. Then, go to `locals.tf`and change the following variable to your new bucket name:

```json
tfstate_bucket = "my-tfstate-bucket"
```

5.  While on `locals.tf`, set the following variable to your project ID:

```json
project_id = "my-GCP-project" 
```

6. Set the default GCP region:

```json
default_region = "my-GCP-region"
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
Outputs:

another-pwd = <sensitive>
db-host = tolist([
  {
    "ip_address" = "10.191.0.3"
    "time_to_retire" = ""
    "type" = "PRIVATE"
  },
])
db-password = <sensitive>
gcp-binary-service-account = "flyte-onterraform-flyte-binary"
gcp-worker-service-account = "flyte-onterraform-flyte-worker"
gcs_bucket_name = "flyte-onterraform-data"
gke-cluster-name = "flyte-onterraform"
```

**Once everything is installed**:

1. Generate the `kubeconfig` entry for your new GKE cluster:

```bash
gcloud container clusters get-credentials <gke-cluster-name> --region <your-GCP-region> --project <your-project_id>
```

2. Obtain your PostgreSQL database password:
```bash
terraform output db-password
```
3. Update the `values-gcp-binary.yaml` file with the Terraform outputs and GCP project info. Especifically, these sections need to be updated:

| Key      | Value |
| ----------- | ----------- |
| userSettings.dbHost      | `db-host` Terraform output       |
|userSettings.googleProjectID | Your GCP project ID|
| userSettings.hostname   | The FQDN you will use to connect to Flyte        |
|userSettings.IAMWorkerRole |`gcp-worker-service-account` Terraform output |
|userSettings.IAMBackendRole|`gcp-binary-service-account` Terraform output|
|configuration.database.password |`db-password` Terraform output |
|configuration.storage.metadataContainer |`gcs_bucket_name` Terraform output |
|configuration.storage.userDataContainer | `gcs_bucket_name` Terraform output|
|configuration.storage.providerConfig.project|Your GCP project ID*|

> NOTE: a current limitation in the `flyte-binary` chart, creates this need to use the GCP project ID in two different ways in the values file.

4. Save your changes and run:
```bash
helm install flyte-binary flyteorg/flyte-binary --values values-gcp-binary.yaml 
```
5. Update the DNS A entry to point to the Ingress IP:
    - `kubectl get ingress -n flyte`
6. Update your `$HOME\.flyte\config,yaml` and make `endpoint` your DNS name:
```yaml
...
#Example
endpoint: dns://flyte-on-gcp.uniondemo.run 
```