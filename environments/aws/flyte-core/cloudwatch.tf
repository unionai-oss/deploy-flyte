data "aws_iam_policy" "cloudwatch_agent_server_policy" {
  name = "CloudWatchAgentServerPolicy"
}

module "aws_cloudwatch_metrics_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.11.2"

  role_name = "${local.name_prefix}-aws-cloudwatch-metrics"
  role_policy_arns = {
    default = data.aws_iam_policy.cloudwatch_agent_server_policy.arn
  }

  oidc_providers = {
    default = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-cloudwatch-metrics"]
    }
  }
}

data "aws_iam_policy_document" "aws_for_fluent_bit_policy" {
  source_policy_documents = [data.aws_iam_policy.cloudwatch_agent_server_policy.policy]

  # Fluent-bit CloudWatch plugin manages log groups and retention policies
  statement {
    actions = [
      "logs:DeleteRetentionPolicy",
      "logs:PutRetentionPolicy"
    ]
    resources = ["*"]
  }
}

resource "helm_release" "aws_cloudwatch_metrics" {
  namespace = "kube-system"
  wait      = true
  timeout   = 600

  name = "aws-cloudwatch-metrics"

  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-cloudwatch-metrics"
  version    = "0.0.8"

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.aws_cloudwatch_metrics_irsa_role.iam_role_arn
  }

  set {
    name  = "tolerations[0].operator"
    value = "Exists"
  }
}

resource "aws_cloudwatch_log_group" "flyte_log_group" {
  name = "${local.name_prefix}"

  tags = {
    terraform = "true"
  }
   lifecycle {
    ignore_changes = [name]
  }
}