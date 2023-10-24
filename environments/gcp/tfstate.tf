locals {
  tfstate_bucket_name = "${local.name_prefix}-tf-state"
}

module "gcs_buckets" {
  source = "terraform-google-modules/cloud-storage/google"

  project_id = local.project_id
  location   = local.region
  names      = [local.tfstate_bucket_name]
  prefix     = ""
  versioning = {
    (local.tfstate_bucket_name) = true
  }
}
