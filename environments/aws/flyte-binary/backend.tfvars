
backend "s3" {
profile = var.aws_cli_profile #AWS CLI profile name
bucket  = var.tfstate_s3_bucket #create an S3 bucket to store Terraform state
region  = var.aws_region
key     = "terraform.tfstate"
}