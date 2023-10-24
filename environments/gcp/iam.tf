resource "google_service_account" "flyte_binary" {
  account_id = "${local.name_prefix}-flyte-binary"
}

data "google_iam_policy" "flyte_binary_workload_identity" {
  binding {
    members = [google_service_account.flyte_binary.member]
    role    = "roles/iam.serviceAccountTokenCreator"
  }

  binding {
    members = ["serviceAccount:${local.workload_identity_pool}[flyte/flyte-binary]"]
    role    = "roles/iam.workloadIdentityUser"
  }
}

resource "google_service_account_iam_policy" "flyte_binary_workload_identity" {
  service_account_id = google_service_account.flyte_binary.name
  policy_data        = data.google_iam_policy.flyte_binary_workload_identity.policy_data
}

resource "google_service_account" "flyte_worker" {
  account_id = "${local.name_prefix}-flyte-worker"
}

locals {
  flyte_worker_wi_members = toset([
    for tpl in setproduct(
      local.flyte_projects,
      local.flyte_domains,
      local.flyte_ksas
    ) : format("%s-%s/%s", tpl...)
  ])
}

data "google_iam_policy" "flyte_worker_workload_identity" {
  binding {
    members = formatlist("serviceAccount:${local.workload_identity_pool}[%s]", local.flyte_worker_wi_members)
    role    = "roles/iam.workloadIdentityUser"
  }
}

resource "google_service_account_iam_policy" "flyte_worker_workload_identity" {
  service_account_id = google_service_account.flyte_worker.name
  policy_data        = data.google_iam_policy.flyte_worker_workload_identity.policy_data
}


output "gcp-binary-service-account"  {
  value = google_service_account.flyte_binary.account_id

}

output "gcp-worker-service-account" {
  value = google_service_account.flyte_worker.account_id
  
}