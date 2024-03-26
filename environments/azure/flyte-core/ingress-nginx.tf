# resource "helm_release" "ingress-nginx" {
#   name             = "ingress-nginx"
#   namespace        = "ingress"
#   create_namespace = true
#   repository       = "https://kubernetes.github.io/ingress-nginx"
#   chart            = "ingress-nginx"
#   depends_on       = [helm_release.flyte-core]
#   # provisioner "local-exec" {
#   #   command = "./scripts/connect_flyte.sh ${azurerm_resource_group.flyte.name} ${azurerm_kubernetes_cluster.flyte.name} ${local.flyte_domain_label}"
#   # }
# }
