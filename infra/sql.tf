resource "azurerm_mssql_server" "sql" {
  name                         = lower("${var.prefix}-sqlsrv")
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_user
  administrator_login_password = var.sql_admin_pass
}

resource "azurerm_mssql_database" "sqldb" {
  name      = "dbdemo"
  server_id = azurerm_mssql_server.sql.id
  sku_name  = "Basic"
}

# permitir servicios de Azure (start=end=0.0.0.0)
resource "azurerm_mssql_firewall_rule" "allow_azure" {
  name                = "AllowAzureServices"
  server_id           = azurerm_mssql_server.sql.id
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

# opcional: regla para tu IP
resource "azurerm_mssql_firewall_rule" "my_ip" {
  count               = length(var.my_ip) > 0 ? 1 : 0
  name                = "MyIp"
  server_id           = azurerm_mssql_server.sql.id
  start_ip_address    = var.my_ip
  end_ip_address      = var.my_ip
}
