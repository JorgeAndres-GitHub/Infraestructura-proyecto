resource "azurerm_storage_account" "storage" {
  name                     = lower("${var.prefix}storage")
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  allow_blob_public_access = false
  is_hns_enabled           = false
}

resource "azurerm_storage_container" "static_container" {
  name                  = "static-web"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}
