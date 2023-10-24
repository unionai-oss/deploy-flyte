#--- This section creates part of the network requirements to enable Flyte to connect to the PostgreSQL DB using Private Services Access


#module "private_service_connect" {
 # source                     = "terraform-google-modules/network/google//modules/private-service-connect"

#  project_id                 = local.project_id 
 # network_self_link          = module.network.network_self_link
  #private_service_connect_ip = "172.24.0.5"
  #forwarding_rule_target     = "all-apis"
#}

#-----------------------------------------

module "flyte-db" {
  source               = "GoogleCloudPlatform/sql-db/google//modules/postgresql"
  name                 = "${local.name_prefix}-db"
  random_instance_name = true
  database_version     = "POSTGRES_14"
  project_id           = local.project_id
  region               = local.region
  zone                 = "${local.region}-b"
  tier                 = "db-custom-1-3840"
  module_depends_on    = [google_service_networking_connection.default]
# See https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_database_instance#private-ip-instance
  
  additional_databases = [
    {
      name      = "flyte"
      charset   = ""
      collation = ""
    }
  ]

  additional_users = [
    {
      name            = "flyte"
      password        = ""
      random_password = true
    }
  ]

  ip_configuration = {
    allocated_ip_range  = null,
    authorized_networks = [],
    ipv4_enabled        = false,
    enable_private_path_for_google_cloud_services = true
    private_network     = module.network.network_self_link
    
    require_ssl         = null
  }
}





output "db_host" {
  value = module.flyte-db.instance_ip_address

}

output "db-password" {
  value = module.flyte-db.generated_user_password
  sensitive = true
}