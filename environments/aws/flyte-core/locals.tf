locals {
  project     = "flyte"
  environment = "terraform" 
  name_prefix = "${local.project}-${local.environment}"
  account_id  = data.aws_caller_identity.current.account_id
  
  domain_name = "flytetf.${data.aws_route53_zone.zone.name}"

  # Change this only if you need to add more projects in the default installation
  flyte_projects         = ["flytesnacks"]
  flyte_domains          = ["development", "staging", "production"]
}


data "aws_route53_zone" "zone" {
  name = "fthwdemo.com"  # Change this to your Route53 managed zone
}