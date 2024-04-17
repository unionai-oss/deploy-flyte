locals {

  #Change this on first use
  application            = "flyte" #Change if needed. By default, this is used to build the FQDN for Flyte. See flyte-host notes
  environment            = "gcp" #Change to match your needs
  project_id             = "kpro-prod"
  project_number         = "151964844764"
  dns-domain             = "khiladipro.in" #Change to your domain name 
  region                 = "asia-south1" #Change to your GCP region
  
  #You must replace this email address with your own.
  # Let's Encrypt will use this to contact you about expiring
  # certificates, and issues related to your account.
  email    =             "shiv@khiladipro.com" 
  
  # Change this only if you need to add more projects in the default installation
  flyte_projects         = ["vision"]
  flyte_domains          = ["production"]
}

