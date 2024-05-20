locals {
  flyte_domain_label = "flytedeploy01"
  environment        = "terraform"
  tenant             = "flyte"
  location           = "eastus"
  subscription_id    = "8c8589f3-42da-4083-be83-ff9b12412edd"
  tenant_id          = "35356303-ece0-4649-85bb-c8a9c67fd341"
  
  #You must replace this email address with your own.
  # Let's Encrypt will use this to contact you about expiring
  # certificates, and issues related to your account.
  email    =             "noreply@flyte.org"

# Change this only if you need to add more projects in the default installation
  flyte_projects     = ["flytesnacks"]
  flyte_domains      = ["development", "staging", "production"]
}
