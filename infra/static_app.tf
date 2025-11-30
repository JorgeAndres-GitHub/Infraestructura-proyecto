resource "azurerm_static_web_app" "static_app" {
  name                = "${var.prefix}-static"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  sku_tier            = "Free"

  # nota: para deploys automáticos se integra con GitHub Actions.
  # Para testing puedes usar Storage static website si prefieres.
}
