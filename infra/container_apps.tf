resource "azurerm_container_app_environment" "env" {
  name                = "${var.prefix}-ca-env"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
}

resource "azurerm_container_app" "api" {
  name                         = "${var.prefix}-containerapp"
  resource_group_name          = azurerm_resource_group.rg.name
  container_app_environment_id = azurerm_container_app_environment.env.id

  revision_mode = "Single"

  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.ca_identity.id
    ]
  }

  # Secrets del Container App (referenciando Key Vault)
  secret {
    name  = "sql-admin-password"
    value = var.sql_admin_pass
  }

  template {
    container {
      name   = "api"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "SQL_SERVER"
        value = azurerm_mssql_server.sql.fully_qualified_domain_name
      }

      env {
        name  = "SQL_DB"
        value = azurerm_mssql_database.sqldb.name
      }

      env {
        name        = "SQL_ADMIN_PASSWORD"
        secret_name = "sql-admin-password"
      }

      env {
        name  = "AZURE_OPENAI_ENDPOINT"
        value = azurerm_cognitive_account.openai.endpoint
      }

      env {
        name  = "STORAGE_BLOB_ENDPOINT"
        value = azurerm_storage_account.storage.primary_blob_endpoint
      }

      env {
        name  = "KEY_VAULT_URI"
        value = azurerm_key_vault.kv.vault_uri
      }
    }

    min_replicas = 0
    max_replicas = 3
  }

  ingress {
    external_enabled = true
    target_port      = 80

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}
