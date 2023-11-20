module "flyte_data" {
  # Metadata bucket. Learn more: https://docs.flyte.org/en/latest/concepts/data_management.html#types-of-data 
  source = "terraform-google-modules/cloud-storage/google"

  project_id      = local.project_id
  location        = local.region
  names           = ["${local.name_prefix}-data"]
  prefix          = ""
}

module "flyte_user_data" {
  # Bucket for Raw data. See https://docs.flyte.org/en/latest/concepts/data_management.html#types-of-data 
  source = "terraform-google-modules/cloud-storage/google"

  project_id      = local.project_id
  location        = local.region
  names           = ["${local.name_prefix}-user-data"]
  prefix          = ""
}

