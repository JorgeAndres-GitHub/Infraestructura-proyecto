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

      # No ponemos la contraseña aquí; la añadiremos como secret reference
    }
  }

  ingress {
    external_enabled = true
    target_port      = 80

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  # secrets: traer el valor del Key Vault secret al Container App como secret value
  # NOTA: azurerm_container_app supports secrets block; but to reference Key Vault automatically there are features requiring provider features.
  # Simplificamos: copiamos el secret value from Key Vault (not ideal for prod). Better: use Managed Identity + KeyVault provider in app to fetch secret at runtime.
  # Aquí añadimos una secret local con el valor (solo para demo)
  secret {
    name  = "SQL_ADMIN_PASSWORD"
    value = azurerm_key_vault_secret.sql_password.value
  }

  # Inyectar el secret como env var
  template {
    container {
      name = "api"
      env {
        name = "SQL_ADMIN_PASSWORD"
        secret_ref = "SQL_ADMIN_PASSWORD"
      }
    }
  }
}
