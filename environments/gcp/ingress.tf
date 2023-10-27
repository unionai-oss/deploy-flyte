module "nginx-controller" {
  source  = "terraform-iaac/nginx-controller/helm"
  version = "2.3.0"
  namespace = "kube-system"
depends_on = [ module.gke ]
}

module "cert-manager" {
  source  = "terraform-iaac/cert-manager/kubernetes"
  version = "2.6.1"
  cluster_issuer_email = "noreply@flyte.org"
 # cluster_issuer_name = "letsencrypt-production"
  depends_on = [ module.gke ]


#  certificates = {
   

#    "${local.flyte-host}" = {
 
 #     dns_names = ["${local.flyte-host}"]
  #    namespace = "flyte"
   #   cluster_issuer_name = module.cert-manager.cluster_issuer_name
    #  secret_name = "${local.flyte-host}"
      #ip_addresses = [module.gke.endpoint]
    }
 # }

#}
resource "google_dns_managed_zone" "flyte-zone" {
  name        = "flyte-zone"
  dns_name    = "${local.dns-domain}."
  description = "DNS Zone created by Terraform to host the FQDN entry for Flyte"
  
}

resource "google_dns_record_set" "flyte-host" {
  name         = "${local.flyte-host}."
  managed_zone = google_dns_managed_zone.flyte-zone.name
  type         = "A"
  ttl          = 300
  rrdatas      = [module.gke.endpoint]
  
}
