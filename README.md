# Infraestructura Azure - Proyecto Demo

Este proyecto despliega una arquitectura completa en Azure usando Terraform y GitHub Actions.

## 🏗️ Arquitectura

```
                         ┌─────────────────────────────────────────────────────┐
                         │                   MICROSOFT AZURE                   │
                         │                   Region: East US                   │
                         │                                                     │
                         │    ┌─────────────┐     ┌─────────────────────────┐ │
                         │    │ Static Apps │────▶│    Azure SQL Database   │ │
                         │    └─────────────┘     └─────────────────────────┘ │
    ┌──────────┐         │          │                         │               │
    │ Clientes │────▶────│──▶ Load Balancer                   │               │
    └──────────┘         │    (Front Door)                    ▼               │
                         │          │             ┌─────────────────────────┐ │
                         │    ┌─────────────┐     │     Storage Blob        │ │
                         │    │ Static Apps │     └─────────────────────────┘ │
                         │    └─────────────┘                                 │
                         │          │                                         │
                         │          ▼             ┌─────────────────────────┐ │
                         │    ┌─────────────┐     │     Azure OpenAI        │ │
                         │    │ Container   │────▶└─────────────────────────┘ │
                         │    │    App      │                                 │
                         │    └─────────────┘                                 │
                         │          │                                         │
                         │          ▼                                         │
                         │    ┌─────────────┐                                 │
                         │    │  Key Vault  │                                 │
                         │    └─────────────┘                                 │
                         └─────────────────────────────────────────────────────┘
```

## 📦 Componentes

| Componente | Descripción |
|------------|-------------|
| **Azure Front Door** | Load Balancer global y CDN |
| **Static Web Apps** | Hosting para el frontend (HTML/CSS/JS) |
| **Container Apps** | API backend containerizada |
| **Azure SQL** | Base de datos relacional |
| **Storage Account** | Almacenamiento de blobs |
| **Key Vault** | Gestión segura de secretos |
| **Azure OpenAI** | Servicios de IA |
| **Managed Identity** | Autenticación sin contraseñas |

## 🚀 Despliegue

### Prerrequisitos

1. **Azure CLI** instalado y configurado
2. **Terraform** >= 1.3.0
3. **Cuenta de Azure** con permisos de Contributor
4. **Repositorio en GitHub** con Actions habilitado

### Configuración de Secrets en GitHub

Ir a **Settings > Secrets and variables > Actions** y agregar:

| Secret | Descripción |
|--------|-------------|
| `AZURE_CLIENT_ID` | Client ID del Service Principal |
| `AZURE_CLIENT_SECRET` | Secret del Service Principal |
| `AZURE_SUBSCRIPTION_ID` | ID de la suscripción de Azure |
| `AZURE_TENANT_ID` | Tenant ID de Azure AD |
| `SQL_ADMIN_PASSWORD` | Contraseña del admin de SQL |
| `AZURE_STATIC_WEB_APPS_API_TOKEN` | Token de la Static Web App |
| `AZURE_CREDENTIALS` | JSON completo de credenciales de Azure |

### Crear Service Principal

```bash
# Login a Azure
az login

# Crear Service Principal
az ad sp create-for-rbac --name "github-actions-sp" \
  --role contributor \
  --scopes /subscriptions/{subscription-id} \
  --sdk-auth

# El output JSON va en AZURE_CREDENTIALS
# Los valores individuales van en los otros secrets
```

### Despliegue Local (Desarrollo)

```bash
cd infra

# Copiar y editar variables
cp terraform.tfvars.example terraform.tfvars
# Editar terraform.tfvars con tus valores

# Inicializar Terraform
terraform init

# Validar configuración
terraform validate

# Ver plan de cambios
terraform plan

# Aplicar cambios
terraform apply
```

### Despliegue con GitHub Actions

1. Push a la rama `main` activa el workflow de Terraform
2. Los cambios en `static-app/` despliegan la Static Web App
3. Los cambios en `api/` despliegan el Container App

## 📁 Estructura del Proyecto

```
├── .github/
│   └── workflows/
│       ├── terraform.yml           # Infraestructura
│       ├── deploy-static-app.yml   # Frontend
│       └── deploy-container-app.yml # Backend
├── infra/
│   ├── providers.tf        # Configuración del provider
│   ├── variables.tf        # Variables de entrada
│   ├── resource_group.tf   # Grupo de recursos
│   ├── frontdoor.tf        # Azure Front Door (Load Balancer)
│   ├── static_app.tf       # Static Web Apps
│   ├── container_apps.tf   # Container Apps
│   ├── sql.tf              # Azure SQL Database
│   ├── storage.tf          # Storage Account
│   ├── keyvault.tf         # Key Vault
│   ├── openai.tf           # Azure OpenAI
│   ├── identity_and_roles.tf # Managed Identity y RBAC
│   ├── outputs.tf          # Outputs
│   └── backend.tf          # Backend configuration
├── static-app/
│   ├── index.html          # Página principal
│   ├── styles.css          # Estilos
│   └── app.js              # JavaScript
└── script.sql              # Script de inicialización de DB
```

## 🔐 Seguridad

- Las contraseñas se almacenan en Key Vault
- Container App usa Managed Identity para acceder a recursos
- Front Door proporciona WAF y protección DDoS
- SQL Server solo permite conexiones de servicios de Azure
- Storage Account no tiene acceso público

## 💡 Notas Importantes

1. **Costos**: Esta arquitectura tiene costos asociados. Revisa el [Calculator de Azure](https://azure.microsoft.com/pricing/calculator/)

2. **OpenAI**: El recurso de Azure OpenAI requiere aprobación previa. Si no lo tienes aprobado, comenta el archivo `openai.tf`

3. **Prefijo**: Usa un prefijo único para evitar conflictos con nombres de recursos globales

4. **Región**: Algunos servicios (como OpenAI) no están disponibles en todas las regiones

## 📝 Outputs

Después del despliegue, obtendrás:

- URL del Static Web App
- URL del Container App
- URL del Front Door (punto de entrada principal)
- FQDN del SQL Server
- URI del Key Vault
- Endpoint de OpenAI

## 🧹 Limpieza

```bash
cd infra
terraform destroy
```
