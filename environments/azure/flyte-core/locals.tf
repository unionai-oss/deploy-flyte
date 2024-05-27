locals {
  flyte_domain_label = "flyte" #Used to build the DNS name of your deployment
  environment        = "deployment"
  tenant             = "mytenant"
  location           = "eastus" #Azure region or zone
  subscription_id    = "<MY_SUBSCRIPTION_ID>"
  tenant_id          = "<MY_TENANT_ID>"
  
  #You must replace this email address with your own.
  # Let's Encrypt will use this to contact you about expiring
  # certificates, and issues related to your account.
  email    =             "noreply@flyte.org"

# Change this only if you need to add more projects in the default installation name
# Learn more about Flyte projects and domains: https://docs.flyte.org/en/latest/concepts/projects.html - https://docs.flyte.org/en/latest/concepts/domains.html
  flyte_projects     = ["flytesnacks"]
  flyte_domains      = ["development", "staging", "production"]
}
