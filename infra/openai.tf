resource "azurerm_cognitive_account" "openai" {
  name                = lower("${var.prefix}-openai")
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  kind                = "OpenAI"
  sku_name            = "S0"
}

# Deployment del modelo GPT-4o-mini (reemplaza GPT-3.5-turbo deprecado)
resource "azurerm_cognitive_deployment" "gpt4omini" {
  name                 = "gpt-4o-mini"
  cognitive_account_id = azurerm_cognitive_account.openai.id

  model {
    format  = "OpenAI"
    name    = "gpt-4o-mini"
    version = "2024-07-18"
  }

  sku {
    name     = "Standard"
    capacity = 10
  }
}
