module "tfstate" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.7.0"

  bucket                  = "${local.name_prefix}-tf-state"
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = true
  }
}
