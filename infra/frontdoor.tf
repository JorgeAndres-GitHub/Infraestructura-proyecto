# Azure Front Door Standard/Premium (CDN FrontDoor)
# Actúa como Load Balancer global para Static Apps y Container Apps

resource "azurerm_cdn_frontdoor_profile" "fd" {
  name                = "${var.prefix}-frontdoor"
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "Standard_AzureFrontDoor"
}

# Endpoint principal
resource "azurerm_cdn_frontdoor_endpoint" "endpoint" {
  name                     = "${var.prefix}-endpoint"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fd.id
}

# Origin Group para Static Web Apps
resource "azurerm_cdn_frontdoor_origin_group" "static_origin_group" {
  name                     = "static-origin-group"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fd.id

  load_balancing {
    sample_size                 = 4
    successful_samples_required = 3
  }

  health_probe {
    path                = "/"
    request_type        = "HEAD"
    protocol            = "Https"
    interval_in_seconds = 100
  }
}

# Origin para Static Web App
resource "azurerm_cdn_frontdoor_origin" "static_origin" {
  name                          = "static-app-origin"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.static_origin_group.id

  enabled                        = true
  host_name                      = azurerm_static_web_app.static_app.default_host_name
  http_port                      = 80
  https_port                     = 443
  origin_host_header             = azurerm_static_web_app.static_app.default_host_name
  priority                       = 1
  weight                         = 1000
  certificate_name_check_enabled = true
}

# Origin Group para Container App (API)
resource "azurerm_cdn_frontdoor_origin_group" "api_origin_group" {
  name                     = "api-origin-group"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fd.id

  load_balancing {
    sample_size                 = 4
    successful_samples_required = 3
  }

  health_probe {
    path                = "/"
    request_type        = "HEAD"
    protocol            = "Https"
    interval_in_seconds = 100
  }
}

# Origin para Container App
resource "azurerm_cdn_frontdoor_origin" "api_origin" {
  name                          = "api-origin"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.api_origin_group.id

  enabled                        = true
  host_name                      = azurerm_container_app.api.ingress[0].fqdn
  http_port                      = 80
  https_port                     = 443
  origin_host_header             = azurerm_container_app.api.ingress[0].fqdn
  priority                       = 1
  weight                         = 1000
  certificate_name_check_enabled = true
}

# Ruta para el frontend (Static App) - ruta por defecto
resource "azurerm_cdn_frontdoor_route" "static_route" {
  name                          = "static-route"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.endpoint.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.static_origin_group.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.static_origin.id]

  supported_protocols    = ["Http", "Https"]
  patterns_to_match      = ["/*"]
  forwarding_protocol    = "HttpsOnly"
  link_to_default_domain = true
  https_redirect_enabled = true
}

# Ruta para la API (Container App)
resource "azurerm_cdn_frontdoor_route" "api_route" {
  name                          = "api-route"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.endpoint.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.api_origin_group.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.api_origin.id]

  supported_protocols    = ["Http", "Https"]
  patterns_to_match      = ["/api/*"]
  forwarding_protocol    = "HttpsOnly"
  link_to_default_domain = true
  https_redirect_enabled = true
}
