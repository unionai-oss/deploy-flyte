locals {
  flyte_domain_label = "flyte" #Used to build the DNS name of your deployment
  environment        = "deployment"
  tenant             = "mytenant"
  location           = "eastus" #Azure region or zone
  subscription_id    = "8c8589f3-42da-4083-be83-ff9b12412edd"
  tenant_id          = "35356303-ece0-4649-85bb-c8a9c67fd341"
  
  #You must replace this email address with your own.
  # Let's Encrypt will use this to contact you about expiring
  # certificates, and issues related to your account.
  email    =             "noreply@flyte.org"

# Change this only if you need to add more projects in the default installation name
# Learn more about Flyte projects and domains: https://docs.flyte.org/en/latest/concepts/projects.html - https://docs.flyte.org/en/latest/concepts/domains.html
  flyte_projects     = ["flytesnacks"]
  flyte_domains      = ["development", "staging", "production"]
}
