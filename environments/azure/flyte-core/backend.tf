# https://www.terraform.io/language/settings/backends/azurerm
#Change the following values to match your environment
terraform {
  backend "azurerm" {
    resource_group_name  = "flyte-deploy"
    storage_account_name = "fdtfstate"
    container_name       = "tfstate"
    key                  = "flyte-on-azure/terraform.tfstate"
  }
}
