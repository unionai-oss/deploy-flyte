locals {
  flyte_ksas = ["default"] #The KSA that Task Pods will use 
}

# As recommended by Google, we make use of Workload Identity as a mechanism to enable KSAs
#to impersonate GSAs and access GCP resources. To do so, the following process is implemented in this module:
# 1. Create a GSA. This is the Principal that will be impersonated by the KSAs
# 2. Create the custom roles that include the permissions for flyteadmin, the dataplane (flytepropeller) and the workers (the Task Pods)
# 3. Grant the custom role to each GSA
# 4. Define an IAM binding at the SA level to associate the GSA with the KSA as a Workload Identity user



#1. Define the GSAs a.k.a the Principals
resource "google_service_account" "flyteadmin-gsa" {
  account_id = "${local.name_prefix}-flyteadmin"
}

resource "google_service_account" "flytepropeller-gsa" {
  account_id = "${local.name_prefix}-flytepropeller"
}

resource "google_service_account" "flytescheduler-gsa" {
  account_id = "${local.name_prefix}-flytescheduler"
}

resource "google_service_account" "datacatalog-gsa" {
  account_id = "${local.name_prefix}-datacatalog"
}

resource "google_service_account" "flyteworkers-gsa" {
  account_id = "${local.name_prefix}-flyteworkers"
}

#GSA to be used to push container images to Artifact Registry. 
#https://cloud.google.com/artifact-registry/docs/docker/authentication#token
resource "google_service_account" "artifactregistry-writer" {
  account_id = "${local.name_prefix}-registrywriter" 
}


#2. Create custom roles
resource "google_project_iam_custom_role" "custom_IAM_roles" {

  for_each = {
    
    flyteadmin = [
      "iam.serviceAccounts.signBlob",
      "storage.buckets.get",
      "storage.objects.create",
      "storage.objects.delete",
      "storage.objects.get",
      "storage.objects.getIamPolicy",
      "storage.objects.update",
    ],
    flytepropeller = [
      "storage.buckets.get",
      "storage.objects.create",
      "storage.objects.delete",
      "storage.objects.get",
      "storage.objects.getIamPolicy",
      "storage.objects.update",
    ],
    flytescheduler = [
      "storage.buckets.get",
      "storage.objects.create",
      "storage.objects.delete",
      "storage.objects.get",
      "storage.objects.getIamPolicy",
      "storage.objects.update",
    ],
    datacatalog = [
      "storage.buckets.get",
      "storage.objects.create",
      "storage.objects.delete",
      "storage.objects.get",
      "storage.objects.update",
    ],
    flyteworkers = [
      "storage.buckets.get",
      "storage.objects.create",
      "storage.objects.delete",
      "storage.objects.get",
      "storage.objects.list",
      "storage.objects.update"
    ],
  }
  role_id = each.key
  title = each.key
  permissions = each.value
  }
 
 # 3. Define role<>GSA bindinggs at the project level
resource google_project_iam_binding "flyteadmin-binding" {
  project = local.project_id
  role = google_project_iam_custom_role.custom_IAM_roles["flyteadmin"].id
  members = ["serviceAccount:${google_service_account.flyteadmin-gsa.email}"]
}

resource "google_project_iam_binding" "flytepropeller-binding" {
  project = local.project_id
  role = google_project_iam_custom_role.custom_IAM_roles["flytepropeller"].id
  members = ["serviceAccount:${google_service_account.flytepropeller-gsa.email}"]
  
}

resource "google_project_iam_binding" "flytescheduler-binding" {
  project = local.project_id
  role = google_project_iam_custom_role.custom_IAM_roles["flytescheduler"].id
  members =["serviceAccount:${google_service_account.flytescheduler-gsa.email}"]
  
}

resource "google_project_iam_binding" "datacatalog-binding" {
  project = local.project_id
  role = google_project_iam_custom_role.custom_IAM_roles["datacatalog"].id
  members = ["serviceAccount:${google_service_account.datacatalog-gsa.email}"]
  
}

resource "google_project_iam_binding" "flyteworkers-binding" {
  project = local.project_id
  role = google_project_iam_custom_role.custom_IAM_roles["flyteworkers"].id
  members = ["serviceAccount:${google_service_account.flyteworkers-gsa.email}"]
  
}

#This particular binding enables the necessary permissions for the Flyte Pods to 
#pull images from Artifact Registry.
#Feel free to remove it if you plan on using a different container registry.
resource "google_project_iam_binding" "flyteworkers-binding-registry" {
  project = local.project_id
  role = "roles/artifactregistry.reader"
  members = ["serviceAccount:${google_service_account.flyteworkers-gsa.email}"] 
}

#This permission is granted so the end user/CI can obtain an access token to push container images to AR. 
#See https://cloud.google.com/artifact-registry/docs/docker/authentication#token
resource "google_project_iam_binding" "artifactregistry-writer"{
  project = local.project_id
  role = "roles/artifactregistry.writer"
  members = ["serviceAccount:${google_service_account.artifactregistry-writer.email}"] 

}

# Step 4 Bind GSAs with KSAs as Workload Identity Users, enabling impersonation
resource google_service_account_iam_binding "flyteadmin-workload-identity-binding" {
   role               = "roles/iam.workloadIdentityUser"
   service_account_id = google_service_account.flyteadmin-gsa.name
   members = ["serviceAccount:${module.gke.identity_namespace}[flyte/flyteadmin]"]

}

resource google_service_account_iam_binding "flytepropeller-workload-identity-binding" {
   role               = "roles/iam.workloadIdentityUser"
   service_account_id = google_service_account.flytepropeller-gsa.name
   members = ["serviceAccount:${module.gke.identity_namespace}[flyte/flytepropeller]"]

}

resource google_service_account_iam_binding "flytescheduler-workload-identity-binding" {
   role               = "roles/iam.workloadIdentityUser"
   service_account_id = google_service_account.flytescheduler-gsa.name
   members = ["serviceAccount:${module.gke.identity_namespace}[flyte/flytescheduler]"]

}

resource google_service_account_iam_binding "datacatalog-workload-identity-binding" {
   role               = "roles/iam.workloadIdentityUser"
   service_account_id = google_service_account.datacatalog-gsa.name
   members = ["serviceAccount:${module.gke.identity_namespace}[flyte/datacatalog]"]

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

# IAM Policy for the Flyte workers role. The SA IAM Policy resource is authoritative for, in this case, the Flyteworkers SA. 
#It is implemented in this way both as a convenience to be able to configure SA impersonation for the `default` SA of 
#each and every project-domain combination in a programmatic way, but also because the Flyteworkers SA should only act as a
#Workload Identity User. 

data "google_iam_policy" "flyte-worker-workload-identity" {
  binding {
    members = formatlist("serviceAccount:${module.gke.identity_namespace}[%s]", local.flyte_worker_wi_members)
    role    = "roles/iam.workloadIdentityUser"
  }
}

resource "google_service_account_iam_policy" "flyte-worker-workload-identity" {
  depends_on = [ module.gke.identity_namespace ]
  service_account_id = google_service_account.flyteworkers-gsa.name
  policy_data        = data.google_iam_policy.flyte-worker-workload-identity.policy_data
}