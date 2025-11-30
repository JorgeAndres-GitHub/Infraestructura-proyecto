# Backend configuration for Terraform state
# Descomentar y configurar cuando tengas el storage account para el state

# terraform {
#   backend "azurerm" {
#     resource_group_name  = "rg-terraform-state"
#     storage_account_name = "tfstatejhdemo"
#     container_name       = "tfstate"
#     key                  = "proyecto.tfstate"
#   }
# }

# Para usar backend local (desarrollo), deja esto comentado
# y el state se guardará localmente
