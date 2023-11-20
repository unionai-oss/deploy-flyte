
#Installs the flyte-core Helm chart in the flyte namespace using the outputs of Terraform modules
resource helm_release "flyte-core" {
  depends_on = [ module.gke ]
  name = "flyte-core"
  namespace = "flyte"
  create_namespace = true
  repository = "https://flyteorg.github.io/flyte"
  chart = "flyte-core"
  values = [templatefile("values-gcp-core.yaml", {
   gcp-project-id = local.project_id
   dbpassword = module.flyte-db.additional_users[0].password
   dbhost = module.flyte-db.instance_first_ip_address
   gcsbucket = module.flyte_data.name
   hostname = local.flyte-host
   flyteadminServiceAccount = google_service_account.flyteadmin_gsa.account_id
   flytepropellerServiceAccount = google_service_account.flytepropeller_gsa.account_id
   flyteschedulerServiceAccount = google_service_account.flytescheduler_gsa.account_id
   datacatalogServiceAccount = google_service_account.datacatalog_gsa.account_id
   flyteworkersServiceAccount = google_service_account.flyteworkers_gsa.account_id
  }
  
  
  
  )
  ]
}

