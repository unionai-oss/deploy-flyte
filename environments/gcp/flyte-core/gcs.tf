locals {
    name_prefix            = "${local.application}-${local.environment}"
}

module "flyte-data" {
  # Metadata bucket. Learn more: https://docs.flyte.org/en/latest/concepts/data_management.html#types-of-data 
  source = "terraform-google-modules/cloud-storage/google"

  project_id      = local.project_id
  location        = local.region
  names           = ["${local.name_prefix}-data-${local.project_number}"]
  prefix          = ""
}

