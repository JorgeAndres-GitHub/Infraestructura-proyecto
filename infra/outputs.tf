output "resource_group" {
  value = azurerm_resource_group.rg.name
}

output "static_app_url" {
  value = "https://${azurerm_static_web_app.static_app.default_host_name}"
}

output "static_app_api_key" {
  value     = azurerm_static_web_app.static_app.api_key
  sensitive = true
}

output "container_app_url" {
  value = "https://${azurerm_container_app.api.ingress[0].fqdn}"
}

output "frontdoor_endpoint" {
  value = "https://${azurerm_cdn_frontdoor_endpoint.endpoint.host_name}"
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
