## Flyte on AWS

### Customize your deployment
1. Configure your AWS CLI with the credentials to access your account. Check out the different options in the [AWS Documentation](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-quickstart.html) if needed.

2. Go to `environments/aws`
3. Go to  `provider.tf` and replace `profile` with your AWS CLI profile name and the `region` where you plan to run Flyte:

Example: 
```hcl
provider "aws" {
  region  = "us-west-1"
  profile = "MyAWSProfile"
}
```
3. Create an S3 bucket to store Terraform state and update the values in the `backend` section on `terraform.tf`:

```hcl
  backend "s3" {
    profile = "<MyAWSProfile>"
    bucket  = "<MyS3-TF-state-bucket>"
    key     = "terraform.tfstate"
    region  = "<region>" # region where the S3 bucket was created
  }
```
4. Go to `dns.tf` and change the following values:

 - 4.1. Indicate the DNS zone you'll be using:
 ```hcl
  data "aws_route53_zone" "zone" {
  name = "example.run."  # Change name to your Route53 managed zone
}
 ```
 - 4.2. In the `cname_record` resource, change `name` with the subdomain you plan to use to connect to Flyte.   

For example, if `flyte.example.run` is your intended URL, the `name` portion here would be only `flyte`


```hcl
 resource "aws_route53_record" "cname_record" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "change-me"  # Replace with your desired subdomain
  type    = "CNAME"
  ttl     = 300  # Time to Live in seconds

  records = ["lb.example"] #Once Flyte is deployed, you can change this with the ALB

  allow_overwrite = true
} 
 ```
> NOTE: this is needed if you plan to use Flyte with Ingress. Because of that, the `records` where the CNAME points can only be added once Flyte and its corresponding Ingress and ALB resources are deployed. For now you can leave it as is.

- 4.3. In the `aws_acm_certificate` resource, change the `domain_name` to reflect the full URL you plan to use to connect to Flyte:

```hcl
resource "aws_acm_certificate" "flyte_cert" {
  domain_name       = "flyte.example.run" # change this
  validation_method = "DNS"
  ...
```
5. Go to `locals.tf` and change the `project` and `environment` name. These parameters will be used to name the resources to be created:

```hcl
locals {
  project     = "flyte"
  environment = "terraform"
  ...
```
6. Go to `rds.tf` and define whether you want Terraform to generate and set a random password for the DB (default behavior) or you want to indicate a specific one:

```hcl
  #Comment to disable random password generation for the DB
  random_password_length = 63

  #Uncomment and update the value to set a specific password for the DB.
  #master_password = "my-db-password"
```
7. Save your changes.
### Prepare the infrastructure with Terraform
8. Initialize the Terraform backend

```bash
terraform init
```

9. Generate an especulative execution plan:

```bash
terraform plan -out flyte-plan
```
10. Apply changes:

```bash
terraform apply flyte-plan
```
A successful execution should produce the following information in the output:

```bash
aws_acm_certificate = ["<your-cert-ARN>"]
cluster_endpoint = "<project-environment-db.cluster-ID.region.rds.amazonaws.com>"
cluster_master_password = <sensitive>
flyte_binary_irsa_role = "<arn:aws:iam::<AWS_account_ID>:role/project-environment-flyte-binary>"
flyte_worker_irsa_role = "arn:aws:iam::<AWS_account_ID:role/project-environment-flyte-worker"

```
11. Switch your `kubectl` context to the new EKS cluster (named after the `project` and `environment` configured on `locals.tf`):

```bash
aws eks update-kubeconfig --name <project-environment>  --region <AWS-region>
```

### (Optional) Create a secret for the DB password

To avoid having to use the plain-text version of your DB password in the Helm `values` file, leverage the `flyte-binary` capability to mount pre-created secrets:

- Create an external secret containing the DB password:

```yaml
cat <<EOF >local-secret.yaml      
apiVersion: v1
kind: Secret
metadata:
  name: flyte-binary-inline-config-secret
  namespace: flyte
type: Opaque
stringData:
  202-database-secrets.yaml: |
    database:
      postgres:
        password: <DB_PASSWORD>
EOF
```
> NOTE: if you chose to let Terraform generate a random password for the DB, retrieve it from the outputs:

```bash
terraform output cluster_master_password
```
- Create the `flyte` namespace:
```bash
kubectl create ns flyte
```
- Submit the manifest:
```bash
kubectl create -f local-secret.yaml
```
### Install Flyte
11. Add the Helm repo with the Flyte charts:
```bash
helm repo add flyteorg https://flyteorg.github.io/flyte
```
12. Download the values file:
```bash
curl -sL https://raw.githubusercontent.com/flyteorg/flyte/master/charts/flyte-binary/eks-production.yaml
```
13. Update the following fields with the outputs from step 10:

|Helm parameter|Value|Comments|
|---|--- |---|
|`configuration.database.host`|`cluster_endpoint` output value| |
|`configuration.storage.metadataContainer`|`<project-environment-data>`| |
|`configuration.storage.userDataContainer`|`<project-environment-data>` or other bucket as needed| By default only one S3 bucket is created. It can be used both for metadata and user data. Use different or existent buckets if your project needs it.
|`configuration.storage.providerConfig.s3.region`|`<AWS-region>`|
|`inlineSecretRef`|`flyte-binary-inline-config-secret `|Set this line only in case you're using the pre-created secret for the DB password|
|`cluster_resources.customData.<domain>.defaultIamRole`|`flyte_worker_irsa_role` output value|Update the value for each domain (`production`, `staging` and `development`)|


14. Under the `clusterResourceTemplates` section, add the following content to enable Flyte to automatically annotate the `default` service account on each `project-domain` namespace with the IAM Role, enabling the worker Pods to access AWS resources:

```yaml
002_serviceaccount.yaml: |
      apiVersion: v1
      kind: ServiceAccount
      metadata:
        name: default
        namespace: '{{ namespace }}'
        annotations:
          eks.amazonaws.com/role-arn: '{{ defaultIamRole }}'
```
15. If needed, set platform-wide resource limits and requests, according to your organization's policies, adding the following section:

```yaml
  inline:
  
    task_resources:
      defaults:
      #Example values, change to match your needs.
        cpu: 1
        memory: 1Gi
        storage: 100Mi
      limits:
        cpu: 1
        memory: 4Gi
```
16. Go to the `ingress` section and update the certificate's ARN:

```yaml
ingress:
  create: true
  commonAnnotations:
    alb.ingress.kubernetes.io/certificate-arn: '<aws_acm_certificate output value'
    ...
```

17. In the same section, edit your `host` to match the URL you'll use to connect to Flyte (it has to match the one you used in the `aws_acm_certificate` resource. See step 4.3):
```yaml
ingres:
  ...
  host: <flyte.example.run>
```
18. Finally, under the `serviceAccount` section, enter the ARN from the `flyte_binary_irsa_role` Terraform output value:
```yaml
serviceAccount:
  create: true 
  annotations:
    eks.amazonaws.com/role-arn: "arn:aws:iam::<account-ID>:role/project-environment-flyte-binary"

```
18. Save your changes.
19. Install Flyte:

```bash
helm install flyte-binary flyteorg/flyte-binary  --values eks-production.yaml -n flyte

```
20. After a couple of minutes, verify the Pod is running:

```bash
kubectl get pod -n flyte
```
Example output:
```bash
NAME                            READY   STATUS    RESTARTS       AGE
flyte-binary-6b9d9f8cd9-9z826   1/1     Running   1 (2m7s ago)   2m23s
```
### Use Flyte

21. Retrieve the ALB address created during Flyte's installation:
```bash
kubectl get ingress -n flyte
```
Example output:
```bash
NAME                CLASS    HOSTS                              ADDRESS                                                      PORTS   AGE
flyte-binary-grpc   <none>   flyte.example.run   k8s-flyte-d7fea18695-922840377.us-west-1.elb.amazonaws.com   80      4m14s
flyte-binary-http   <none>   flyte.example.run   k8s-flyte-d7fea18695-922840377.us-west-1.elb.amazonaws.com   80      4m14s
```
22. Copy the `ADDRESS` field
23. Go to `dns.tf`, find the `aws_route_record` resource and replace the dummy value for the `records` attribute with the value from `ADDRESS`:
```hcl
resource "aws_route53_record" "cname_record" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "flyte"  # Replace with your desired subdomain
  type    = "CNAME"
  ttl     = 300  # Time to Live in seconds

  records = ["k8s-flyte-d7fea18695-922840377.<aws-region>-1.elb.amazonaws.com"] #Once Flyte is deployed, you can change this with the ALB address

  allow_overwrite = true
}

```


23. Run `terraform apply`.

Example output:
```bash
aws_route53_record.cname_record: Modifications complete after 48s [id=Z03330882ZYS93N5LE2WW_flyte-the-hard-way_CNAME]

Apply complete! Resources: 0 added, 1 changed, 0 destroyed.
```
24. Install Flyte on your machine as indicated [here](https://docs.flyte.org/projects/cookbook/en/latest/index.html#installation)
25. Go to your local config file (typically`$HOME/.flyte/config.yaml`) and configure it to point to your URL:

```yaml
admin:
  # For GRPC endpoints you might want to use dns:///flyte.myexample.com
  endpoint: dns:///flyte.example.run #
  authType: Pkce
  insecure: false
```
26. Save the following "hello world" workflow definition:

```bash
cat <<<EOF >hello_world.py
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
27. Execute the workflow on the Flyte cluster:
```bash
pyflyte run --remote hello_world.py my_wf
```
Example output:
```bash
Go to https://flyte.example.run/console/projects/flytesnacks/domains/development/executions/f4b064c7341014ded929 to see execution in the console.
```
28. Go to the console and verify the succesful execution:

![](https://raw.githubusercontent.com/flyteorg/static-resources/main/common/tf-succesful-execution-01.png)  

**Congratulations!**  
You have a fully working Flyte environment on AWS.

From this point on, you can continue your learning journey by going through the [Flyte Fundamentals](https://docs.flyte.org/projects/cookbook/en/latest/getting_started/flyte_fundamentals.html#getting-started-fundamentals) tutorials
