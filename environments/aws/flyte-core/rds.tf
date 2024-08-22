module "flyte_db" {
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "7.6.2"

  name           = "${local.name_prefix}-db"
  engine         = "aurora-postgresql"
  engine_version = "14.9"
  instance_class = "db.t3.medium"
  instances = {
    0 = {}
  }

  allowed_cidr_blocks = module.vpc.private_subnets_cidr_blocks
  subnets             = module.vpc.database_subnets
  vpc_id              = module.vpc.vpc_id

  database_name          = "flyte"
  master_username        = "flyte"
  
#Comment to disable random password generation for the DB
  random_password_length = 63

#Uncomment and update the value to set a specific password for the DB.
  #master_password = "my-db-password"
}
