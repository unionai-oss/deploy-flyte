locals {
  flyte_backend_ksas = ["flytepropeller","flyteadmin","datacatalog"]
  flyte_ksas = ["default"] #The KSA that Task Pods will use 

  flyte_worker_wi_members = toset([
    for tpl in setproduct(
      local.flyte_projects,
      local.flyte_domains,
      local.flyte_ksas
    ) : format("%s-%s:%s", tpl...)
  ])
}
data "aws_iam_policy_document" "flyte_data_bucket_policy" {
  statement {
    sid    = ""
    effect = "Allow"
    actions = [
      "s3:DeleteObject*",
      "s3:GetObject*",
      "s3:ListBucket",
      "s3:PutObject*"
    ]
    resources = [
      "arn:aws:s3:::${module.flyte_data.s3_bucket_id}",
      "arn:aws:s3:::${module.flyte_data.s3_bucket_id}/*"
    ]
  }
}

data "aws_iam_policy_document" "flyte_backend_iam_policy" {
  source_policy_documents = compact([
    data.aws_iam_policy_document.flyte_data_bucket_policy.json
  ])
}

resource "aws_iam_policy" "flyte_backend_iam_policy" {
  name   = "${local.name_prefix}-flyte-backend-iam-policy"
  policy = data.aws_iam_policy_document.flyte_backend_iam_policy.json
}

module "flyte_backend_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.11.2"
  assume_role_condition_test = "StringEquals" 
  role_name = "${local.name_prefix}-backend-role"
  role_policy_arns = {
    default = aws_iam_policy.flyte_backend_iam_policy.arn
  }
  oidc_providers = {
    default = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["flyte:flytepropeller","flyte:flyteadmin","flyte:datacatalog"]
    }
  }
}

data "aws_iam_policy_document" "flyte_worker_iam_policy" {
  source_policy_documents = compact([
    data.aws_iam_policy_document.flyte_data_bucket_policy.json
  ])
}

resource "aws_iam_policy" "flyte_worker_iam_policy" {
  name   = "${local.name_prefix}-flyte-worker-iam-policy"
  policy = data.aws_iam_policy_document.flyte_worker_iam_policy.json
}

module "flyte_worker_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.11.2"
  assume_role_condition_test = "StringEquals"
  role_name                  = "${local.name_prefix}-flyte-worker"
  role_policy_arns = {
    default = aws_iam_policy.flyte_worker_iam_policy.arn
  }

  oidc_providers = {
    default = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = local.flyte_worker_wi_members
    }
  }
}


