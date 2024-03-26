# resource "helm_release" "cert_manager" {
#   name             = "cert-manager"
#   namespace        = "ingress"
#   create_namespace = true
#   repository       = "https://charts.jetstack.io"
#   chart            = "cert-manager"
#   version          = "v1.8.0"

#   set {
#     name  = "installCRDs"
#     value = true
#   }
#   depends_on = [helm_release.ingress-nginx]
#   provisioner "local-exec" {
#     command = "kubectl apply -f k8s/cluster-issuer.yaml"
#   }
# }
