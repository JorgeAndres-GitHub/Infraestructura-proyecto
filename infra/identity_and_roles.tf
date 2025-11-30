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
    "get",
    "list"
  ]
}

# Opcional: asignar rol Reader al identity sobre el resource group (según necesidad)
resource "azurerm_role_assignment" "ca_rg_reader" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.ca_identity.principal_id
}
