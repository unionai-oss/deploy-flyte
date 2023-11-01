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

3 . Set the default project

``gcloud config set project <YOUR_PROJECT_ID>``

4. Set the default region
    - ``gcloud config set compute/region <your-GCP-region> ``
    - [Learn more](https://cloud.google.com/compute/docs/gcloud-compute)
5.  Enable necessary APIS:
    - ``gcloud services enable servicenetworking.googleapis.com container.googleapis.com compute.googleapis.com``
6. Create a bucket in the project and in the same region, leaving public access off, and go to `terraform.tf`, change the `bucket` for the backend.
7. Go to ``locals.tf`` and change the ``dns-domain`` field to match your CloudDNS zone
Run
```bash
terraform init
```
8. Then
```bash
terraform plan
```
9. Verify changes to be applied and then
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

1. ``gcloud container clusters get-credentials <gke-cluster-name> --region <your-GCP-region> --project <your-project_id>``
2. Copy ``terraform output db-password``
3. Update the `values-gcp-binary.yaml` file with the Terraform outputs and GCP project info
4. Run
```bash
helm install flyte-binary flyteorg/flyte-binary --values values-gcp-binary.yaml 
```
5. Update the DNS A entry with the Ingress IP:
    - kubectl get ingress -n flyte
6. Update your `$HOME\.flyte\config,yaml` and make `endpoint` your DNS name:
```yaml
...
#Example
endpoint: dns://flyte-on-gcp.uniondemo.run 
```