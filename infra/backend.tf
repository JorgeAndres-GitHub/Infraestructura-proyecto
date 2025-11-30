# Backend configuration for Terraform state
# El estado se guarda en Azure Storage para persistir entre ejecuciones

terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "tfstateinfradm24"
    container_name       = "tfstate"
    key                  = "proyecto.tfstate"
  }
}
