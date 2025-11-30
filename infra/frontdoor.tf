# Front Door requires a few resources: profile, frontend endpoint, backend pool, routing rule.
resource "azurerm_frontdoor" "fd" {
  name                = "${var.prefix}-frontdoor"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location

  routing_rule {
    name               = "route-staticapp"
    accepted_protocols = ["Https"]
    patterns_to_match  = ["/*"]

    frontend_endpoints = [azurerm_frontdoor_frontend_endpoint.fe.id]
    forwarding_configuration {
      backend_pool_id = azurerm_frontdoor_backend_pool.static_backend.id
    }
  }
}

resource "azurerm_frontdoor_frontend_endpoint" "fe" {
  name                = "${var.prefix}-fe"
  frontdoor_id        = azurerm_frontdoor.fd.id
  host_name           = "${var.prefix}-fd.azurefd.net"
  session_affinity_enabled = false
}

resource "azurerm_frontdoor_backend_pool" "static_backend" {
  name         = "${var.prefix}-backend"
  frontdoor_id = azurerm_frontdoor.fd.id

  backend {
    host_header = azurerm_static_web_app.static_app.default_host_name
    address     = azurerm_static_web_app.static_app.default_host_name
    http_port   = 80
    https_port  = 443
    priority    = 1
    weight      = 50
  }

  backend {
    host_header = azurerm_container_app.api.latest_revision_fqdn
    address     = azurerm_container_app.api.latest_revision_fqdn
    http_port   = 80
    https_port  = 443
    priority    = 2
    weight      = 50
  }

  health_probe {
    name                = "hp"
    protocol            = "Https"
    path                = "/"
    interval_in_seconds = 30
  }
}
