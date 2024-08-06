terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.18.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.9.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }

     http = {
      source  = "hashicorp/http"
      version = "3.1.0"
    }
  }

  backend "s3" {
    profile =  var.aws_cli_profile #AWS CLI profile name
    bucket  = var.tfstate_s3_bucket #create an S3 bucket to store Terraform state
    key     = "terraform.tfstate"
    region  = var.aws_region #AWS region where the bucket was created
  }


}

