locals {
  flyte-host =           "${local.application}.${local.dns-domain}" #If you plan on using a different FQDN for Flyte, replace this with your FQDN (e.g flyte.example.com)
}

#Installs the flyte-core Helm chart in the flyte namespace using the outputs of Terraform modules
resource "helm_release" "flyte-core" {
  depends_on       = [
                      kubectl_manifest.cert-manager-issuer,
                      module.nginx-controller
                      ]
  name             = "flyte-core"
  namespace        = "flyte"
  repository       = "https://flyteorg.github.io/flyte"
  chart            = "flyte-core"
  values = [templatefile("values-gcp-core.yaml", {
    gcp-project-id               = local.project_id
    dbpassword                   = module.flyte-db.additional_users[0].password
    dbhost                       = module.flyte-db.instance_first_ip_address
    gcsbucket                    = module.flyte-data.name
    hostname                     = local.flyte-host
    flyteadminServiceAccount     = google_service_account.flyteadmin-gsa.account_id
    flytepropellerServiceAccount = google_service_account.flytepropeller-gsa.account_id
    flyteschedulerServiceAccount = google_service_account.flytescheduler-gsa.account_id
    datacatalogServiceAccount    = google_service_account.datacatalog-gsa.account_id
    flyteworkersServiceAccount   = google_service_account.flyteworkers-gsa.account_id
    }
    )
  ]
}

