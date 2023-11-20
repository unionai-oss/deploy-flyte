locals {

  #Change this on first use
  application            = "flyte" #By default, this is used to build the FQDN for Flyte. See flyte-host notes
  environment            = "gcp"
  project_id             = "<your-GCP-projectID>"
  dns-domain =           "uniondemo.run" #Change to your domain name 
  region   =             "us-east1" #Change to your GCP region

  # Change this only if you need to add more projects in the default installation
  flyte_projects         = ["flytesnacks"]
  flyte_domains          = ["development", "staging", "production"]
  
  #Don't change this
  flyte_ksas             = ["default"] 
  name_prefix            = "${local.application}-${local.environment}"
  flyte-host =           "${local.application}.${local.dns-domain}" #If you plan on using a different FQDN for Flyte, replace this with your FQDN (e.g flyte.example.com)
  
}