resource kubernetes_namespace "flyte-ns" {
  metadata {
  name = "flyte"
  }
depends_on = [ module.gke ]
}

resource kubernetes_namespace "nginx-ns" {
  metadata {
  name = "nginx-ingress"
  }
depends_on = [ module.gke ]
}

module "nginx-controller" {
  source  = "terraform-iaac/nginx-controller/helm"
  version = "2.3.0"
  namespace = "nginx-ingress"
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
depends_on = [ module.nginx-controller ]
}



resource kubernetes_secret "flyte-tls-secret" {
  depends_on = [ kubernetes_namespace.flyte-ns ]
  metadata {
   name = "flyte-secret-tls"
   namespace = "flyte"
  
  }

}
resource helm_release "cert-manager" {
  name = "cert-manager"
  namespace = "cert-manager"
  create_namespace = true
  repository = "https://charts.jetstack.io"
  chart = "cert-manager"
  version = "v1.13.2"
  depends_on = [ kubectl_manifest.cert-manager-crds ]

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
    email: ${local.email}
    privateKeySecretRef:
      name: letsencrypt-production
    solvers:
    - http01:
        ingress:
          ingressClassName: nginx
    YAML
     )
     depends_on = [ helm_release.cert-manager ]
}


