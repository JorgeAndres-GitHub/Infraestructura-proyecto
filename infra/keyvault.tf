resource "azurerm_key_vault" "kv" {
  name                        = lower("${var.prefix}-kv")
  resource_group_name         = azurerm_resource_group.rg.name
  location                    = var.location
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  purge_protection_enabled    = false
  soft_delete_retention_days  = 7
}

resource "azurerm_key_vault_secret" "sql_password" {
  name         = "sql-admin-password"
  value        = var.sql_admin_pass
  key_vault_id = azurerm_key_vault.kv.id
}
