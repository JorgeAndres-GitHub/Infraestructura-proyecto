resource "azurerm_storage_account" "storage" {
  name                     = lower("${var.prefix}storage")
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  allow_nested_items_to_be_public = false
  is_hns_enabled                  = false
}

resource "azurerm_storage_container" "static_container" {
  name                  = "static-web"
  storage_account_id    = azurerm_storage_account.storage.id
  container_access_type = "private"
}

# Container para datos de la aplicación
resource "azurerm_storage_container" "data_container" {
  name                  = "app-data"
  storage_account_id    = azurerm_storage_account.storage.id
  container_access_type = "private"
}
