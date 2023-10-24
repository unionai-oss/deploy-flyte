module "flyte_data" {
  source = "terraform-google-modules/cloud-storage/google"

  project_id      = local.project_id
  location        = local.region
  names           = ["${local.name_prefix}-data"]
  prefix          = ""
  set_admin_roles = true
  admins = [
    google_service_account.flyte_binary.member,
    google_service_account.flyte_worker.member
  ]
}

resource "google_storage_bucket_iam_binding" "flyte_data_bucket_reader" {
  bucket = module.flyte_data.name
  role   = "roles/storage.legacyBucketReader"
  members = [
    google_service_account.flyte_binary.member,
    google_service_account.flyte_worker.member
  ]
}

module "flyte_user_data" {
  source = "terraform-google-modules/cloud-storage/google"

  project_id      = local.project_id
  location        = local.region
  names           = ["${local.name_prefix}-user-data"]
  prefix          = ""
  set_admin_roles = true
  admins = [
    google_service_account.flyte_worker.member
  ]
}

output "gcs_bucket_name" {
  value = module.flyte_data.name

}