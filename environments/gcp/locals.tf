locals {
  application            = "flyte"
  environment            = "terraform"
  name_prefix            = "${local.application}-${local.environment}"
  region                 = data.google_client_config.current.region
  project_id             = "my-GCP-project" #Insert your GCP Project ID
  workload_identity_pool = "${local.project_id}"
  flyte_projects         = ["flytesnacks"]
  flyte_domains          = ["development", "staging", "production"]
  flyte_ksas             = ["default"]
  default_region         = "my-GCP-region" #Insert your default GCP region   
  dns-domain =           "gcp.run" #replace with your CloudDNS domain
  flyte-host =           "${local.application}.${local.dns-domain}"
  tfstate_bucket         = "my-tfstate-bucket"
}
