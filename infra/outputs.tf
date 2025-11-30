output "resource_group" {
  value = azurerm_resource_group.rg.name
}

output "static_app_url" {
  value = azurerm_static_web_app.static_app.default_host_name
}

output "container_app_url" {
  value = azurerm_container_app.api.latest_revision_fqdn
}

output "sql_server_fqdn" {
  value = azurerm_mssql_server.sql.fully_qualified_domain_name
}

output "sql_database" {
  value = azurerm_mssql_database.sqldb.name
}

output "storage_blob_endpoint" {
  value = azurerm_storage_account.storage.primary_blob_endpoint
}

output "key_vault_uri" {
  value = azurerm_key_vault.kv.vault_uri
}

output "openai_endpoint" {
  value = azurerm_cognitive_account.openai.endpoint
}
