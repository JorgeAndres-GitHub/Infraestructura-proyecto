resource "azurerm_cognitive_account" "openai" {
  name                = lower("${var.prefix}-openai")
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  kind                = "OpenAI"
  sku_name            = "S0"
}
