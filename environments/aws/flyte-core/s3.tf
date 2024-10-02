module "flyte_data" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.7.0"

  bucket                  = "${local.account_id}-${local.name_prefix}-data"
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

