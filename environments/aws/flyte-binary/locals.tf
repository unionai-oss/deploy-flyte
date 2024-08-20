locals {
  project     = "flyte"
  environment = "terraform" 
  name_prefix = "${local.project}-${local.environment}"
  account_id  = data.aws_caller_identity.current.account_id
  
  domain_name = "flyte.${data.aws_route53_zone.zone.name}"
}

data "aws_availability_zones" "available" { state = "available" }
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_route53_zone" "zone" {
  name = "fthwdemo.com"  # Change this to your Route53 managed zone
}