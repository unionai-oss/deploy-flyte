#Installs the flyte-core Helm chart in the flyte namespace using the outputs of Terraform modules
resource "helm_release" "flyte-core" {
  name             = "flyte-core"
  namespace        = "flyte"
  create_namespace = true
  repository       = "https://flyteorg.github.io/flyte"
  chart            = "flyte-core"
  timeout          = "600"

  values = [templatefile("values-eks-core.yaml", {
    rds_postgres_user           =  module.flyte_db.cluster_master_username
    rds_postgres_password       =  module.flyte_db.cluster_master_password
    rds_postgres_database_name  =  module.flyte_db.cluster_database_name
    rds_postgres_database_host  =  module.flyte_db.cluster_endpoint
    bucket_name                 =  module.flyte_data.s3_bucket_id
    flyte_backend_role_arn      = module.flyte_backend_irsa_role.iam_role_arn
    flyte_tasks_role_arn        = module.flyte_worker_irsa_role.iam_role_arn
    acm_certificate             = aws_acm_certificate.flyte_cert.arn
    aws_compute_region          = var.aws_region
    ingress_host                = local.domain_name
    }
    )
  ]
  depends_on = [module.eks,module.flyte_db,module.flyte_worker_irsa_role,module.flyte_backend_irsa_role, aws_acm_certificate_validation.dns_validated_cert]
provisioner "local-exec" {
    command = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name} --profile ${var.aws_cli_profile}"
    
  }

provisioner "local-exec" {
    command = "./scripts/get_elb.sh"
    }
}


output "flyte_endpoint" {
   value= local.domain_name
}
