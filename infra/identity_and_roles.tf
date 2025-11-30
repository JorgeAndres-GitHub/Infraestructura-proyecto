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

# NOTA: Los role assignments requieren permisos de Owner o User Access Administrator
# Si tu Service Principal solo tiene Contributor, estos role assignments deben
# asignarse manualmente desde el portal de Azure o con un usuario con más permisos.
#
# Roles necesarios (asignar manualmente si es necesario):
# - Reader sobre el Resource Group
# - Storage Blob Data Contributor sobre el Storage Account
# - Cognitive Services OpenAI User sobre el recurso OpenAI
