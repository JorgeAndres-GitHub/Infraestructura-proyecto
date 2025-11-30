variable "location" {
  type    = string
  default = "eastus2"
}

variable "rg_name" {
  type    = string
  default = "rg-infra-project"
}

variable "prefix" {
  type    = string
  default = "infradm24"
}

variable "sql_admin_user" {
  type    = string
  default = "sqladmin"
}

variable "sql_admin_pass" {
  type        = string
  description = "Contraseña para el administrador SQL"
  sensitive   = true
  # Sin default - debe proporcionarse en terraform.tfvars o GitHub Secrets
}

variable "my_ip" {
  type        = string
  description = "Tu IP pública para acceso al SQL Server"
  default     = ""
}

variable "container_image" {
  type        = string
  description = "Imagen de container para la API"
  default     = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
}
