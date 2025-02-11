## Flyte on AWS

> [Read the blog about the architecture and components deployed by this implementation](https://flyte.org/blog/speed-up-time-to-production-with-flyte-on-eks-from-automation-to-multicloud)

### Customize your deployment
1. Configure your AWS CLI with the credentials to access your account. Check out the different options in the [AWS Documentation](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-quickstart.html) if needed.

2. Create an S3 bucket to store Terraform state. It shouldn't be covered by lifecycle rules.
3. Go to  `terraform.tfvars`, uncomment and replace values to match your environment.
3. Go to `locals.tf` and update the values to match your environment.
4. Save your changes.

### Prepare for deployment
6. From the CLI, go to the `environments/aws` folder and initialize the Terraform/OpenTofu backend

```bash
terraform init
```

7. Generate an especulative execution plan:

```bash
terraform plan -out=flyte-plan
```
8. Apply changes:

```bash
terraform apply flyte-plan
```
A successful execution should produce a single `endpoint` output.

9. Go to your local config file (typically`$HOME/.flyte/config.yaml`) and configure it to point to the `endpoint` URL:

```yaml
admin:
  # For GRPC endpoints you might want to use dns:///flyte.myexample.com
  endpoint: dns:///flyte.example.run #
  authType: Pkce
  insecure: false
```
10. Save the following "hello world" workflow definition:

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
11. Execute the workflow on the Flyte cluster:
```bash
pyflyte run --remote hello_world.py my_wf
```
Example output:
```bash
Go to https://flyte.example.run/console/projects/flytesnacks/domains/development/executions/f4b064c7341014ded929 to see execution in the console.
```
12. Go to the console and verify the succesful execution:

![](https://raw.githubusercontent.com/flyteorg/static-resources/main/common/tf-succesful-execution-01.png)  

**Congratulations!**  
You have a fully working Flyte environment on AWS.

From this point on, you can continue your learning journey by going through the [Getting started guide](https://docs.flyte.org/en/latest/user_guide/getting_started_with_workflow_development/index.html).
