 resource "helm_release" "ingress-nginx" {
   name             = "ingress-nginx"
   namespace        = "ingress"
   create_namespace = true
   repository       = "https://kubernetes.github.io/ingress-nginx"
   chart            = "ingress-nginx"
   depends_on       = [helm_release.flyte-core]
   set{
    name = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-health-probe-request-path"
    value = "/healthz"
   }
    provisioner "local-exec" {
      command = "./scripts/connect_flyte.sh ${azurerm_resource_group.flyte.name} ${azurerm_kubernetes_cluster.flyte.name} ${local.flyte_domain_label}"
 }
 }

#resource kubernetes_secret "flyte-tls-secret" {
 # metadata {
 #  name = "flyte-tls"
  # namespace = "flyte"
  #}
  #}

resource kubernetes_namespace "cert_manager_ns"{
 metadata {
    name = "cert-manager"
    labels = {
         "cert-manager.io/disable-validation" = "true"
    }
 }
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
#depends_on = [ helm_release.ingress-nginx ]
}

resource helm_release "cert-manager" {
  name = "cert-manager"
  namespace = "cert-manager"
  create_namespace = false
  repository = "https://charts.jetstack.io"
  chart = "cert-manager"
  version = "v1.13.2"
  depends_on = [ kubectl_manifest.cert-manager-crds, kubernetes_namespace.cert_manager_ns ]

}


resource kubectl_manifest "cert-manager-issuer" {
     yaml_body = (<<-YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-production
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
