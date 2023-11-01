module "nginx-controller" {
  source  = "terraform-iaac/nginx-controller/helm"
  version = "2.3.0"
  namespace = "kube-system"
depends_on = [ module.gke ]
}

data "http" "manifestfile" {
  url = "https://github.com/cert-manager/cert-manager/releases/download/v1.13.2/cert-manager.crds.yaml"
}

data kubectl_file_documents "cert-manager-manifest" {
  content = data.http.manifestfile.response_body 

}

#Installing cert-manager CRDs from the manifest instead of using Helm is the recommended approach for production environments. 
#Learn more https://cert-manager.io/docs/installation/helm/#option-1-installing-crds-with-kubectl

resource kubectl_manifest "cert-manager-crds" {
 for_each = data.kubectl_file_documents.cert-manager-manifest.manifests
 yaml_body = each.value
depends_on = [ module.gke ]
}

resource kubernetes_namespace "cert-manager-ns" {
  metadata {
  name = "cert-manager"
  }
depends_on = [ module.gke ]
}

resource kubernetes_namespace "flyte-ns" {
  metadata {
  name = "flyte"
  }
depends_on = [ module.gke ]
}

resource kubernetes_secret "flyte-tls-secret" {
  metadata {
   name = "flyte-secret-tls"
   namespace = "flyte"

  }

}
resource helm_release "cert-manager" {
  name = "cert-manager"
  namespace = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart = "cert-manager"
  version = "v1.13.2"
depends_on = [ resource.kubernetes_namespace.cert-manager-ns ]
}


resource kubectl_manifest "cert-manager-issuer" {
     yaml_body = (<<-YAML
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: letsencrypt-production
  namespace: flyte
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: noreply@flyte.org
    privateKeySecretRef:
      name: letsencrypt-production
    solvers:
    - http01:
        ingress:
          ingressClassName: nginx
    YAML
     )
}
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
