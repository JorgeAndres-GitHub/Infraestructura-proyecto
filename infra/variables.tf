variable "location" {
  type    = string
  default = "eastus"
}

variable "rg_name" {
  type    = string
  default = "rg-proyecto-demo"
}

variable "prefix" {
  type    = string
  default = "jhdemo" # cambia por algo tuyo
}

variable "sql_admin_user" {
  type    = string
  default = "sqladmin"
}

variable "sql_admin_pass" {
  type        = string
  description = "Contraseña para el administrador SQL. Cambia en producción"
  sensitive   = true
  default     = "P@ssw0rdDemo123!"
}

# tu IP pública para abrir firewall (opcional)
variable "my_ip" {
  type    = string
  default = ""  # deja vacío para no crear regla IP, o pon tu IP "1.2.3.4"
}

# Container image para la API (se puede cambiar desde GitHub Actions)
variable "container_image" {
  type        = string
  description = "Imagen de container para la API"
  default     = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
}
