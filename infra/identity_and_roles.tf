# Identity to assign to Container App
resource "azurerm_user_assigned_identity" "ca_identity" {
  name                = "${var.prefix}-ca-id"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
}

# Permitir que la identity acceda a Key Vault secrets (access policy)
resource "azurerm_key_vault_access_policy" "ca_kv_policy" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.ca_identity.principal_id

  secret_permissions = [
    "Get",
    "List"
  ]
}

# Rol Reader sobre el resource group
resource "azurerm_role_assignment" "ca_rg_reader" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.ca_identity.principal_id
}

# Rol para acceder a Storage Blob Data
resource "azurerm_role_assignment" "ca_storage_blob" {
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.ca_identity.principal_id
}

# Rol para acceder a Azure OpenAI
resource "azurerm_role_assignment" "ca_openai" {
  scope                = azurerm_cognitive_account.openai.id
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = azurerm_user_assigned_identity.ca_identity.principal_id
}
