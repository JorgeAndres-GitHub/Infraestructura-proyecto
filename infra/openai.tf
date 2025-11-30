resource "azurerm_cognitive_account" "openai" {
  name                = lower("${var.prefix}-openai")
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  kind                = "OpenAI"
  sku_name            = "S0"
}

# Deployment del modelo GPT-3.5-Turbo
resource "azurerm_cognitive_deployment" "gpt35" {
  name                 = "gpt-35-turbo"
  cognitive_account_id = azurerm_cognitive_account.openai.id

  model {
    format  = "OpenAI"
    name    = "gpt-35-turbo"
    version = "0613"
  }

  sku {
    name     = "Standard"
    capacity = 10  # Tokens por minuto (en miles)
  }
}
