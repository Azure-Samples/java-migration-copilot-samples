terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "~> 1.2"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  subscription_id     = var.subscription_id
  storage_use_azuread = true
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azurecaf" {}

resource "random_string" "suffix" {
  length  = 5
  upper   = false
  special = false
}

data "azurerm_client_config" "current" {}

# ========================
# CAF Resource Naming
# ========================

resource "azurecaf_name" "rg" {
  name          = var.project_name
  resource_type = "azurerm_resource_group"
  clean_input   = true
}

resource "azurecaf_name" "aks" {
  name          = var.project_name
  resource_type = "azurerm_kubernetes_cluster"
  clean_input   = true
}

resource "azurecaf_name" "acr" {
  name          = "${var.project_name}${random_string.suffix.result}"
  resource_type = "azurerm_container_registry"
  clean_input   = true
}

resource "azurecaf_name" "storage" {
  name          = "${var.project_name}${random_string.suffix.result}"
  resource_type = "azurerm_storage_account"
  clean_input   = true
}

resource "azurecaf_name" "servicebus" {
  name          = "${var.project_name}${random_string.suffix.result}"
  resource_type = "azurerm_servicebus_namespace"
  clean_input   = true
}

resource "azurecaf_name" "postgres" {
  name          = "${var.project_name}${random_string.suffix.result}2"
  resource_type = "azurerm_postgresql_flexible_server"
  clean_input   = true
}

resource "azurecaf_name" "keyvault" {
  name          = var.project_name
  resource_type = "azurerm_key_vault"
  clean_input   = true
}

resource "azurecaf_name" "log_analytics" {
  name          = var.project_name
  resource_type = "azurerm_log_analytics_workspace"
  clean_input   = true
}

resource "azurecaf_name" "app_insights" {
  name          = var.project_name
  resource_type = "azurerm_application_insights"
  clean_input   = true
}

resource "azurecaf_name" "workload_identity" {
  name          = "${var.project_name}workload"
  resource_type = "azurerm_user_assigned_identity"
  clean_input   = true
}

# ========================
# Resource Group
# ========================

resource "azurerm_resource_group" "rg" {
  name     = azurecaf_name.rg.result
  location = var.location
  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# ========================
# Log Analytics Workspace
# ========================

resource "azurerm_log_analytics_workspace" "logs" {
  name                = azurecaf_name.log_analytics.result
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags = {
    Environment = var.environment
  }
}

# ========================
# Application Insights
# ========================

resource "azurerm_application_insights" "appinsights" {
  name                = azurecaf_name.app_insights.result
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  workspace_id        = azurerm_log_analytics_workspace.logs.id
  application_type    = "web"
  tags = {
    Environment = var.environment
  }
}

# ========================
# Azure Container Registry
# ========================

resource "azurerm_container_registry" "acr" {
  name                = azurecaf_name.acr.result
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = false
  tags = {
    Environment = var.environment
  }
}

# ========================
# Key Vault
# ========================

resource "azurerm_key_vault" "keyvault" {
  name                          = azurecaf_name.keyvault.result
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                          = "standard"
  rbac_authorization_enabled        = true
  purge_protection_enabled          = true
  public_network_access_enabled = true
  tags = {
    Environment = var.environment
  }
}

# Key Vault Secrets Officer for current user (required to store secrets)
resource "azurerm_role_assignment" "kv_secrets_officer_current_user" {
  scope                = azurerm_key_vault.keyvault.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
  depends_on           = [azurerm_key_vault.keyvault]
}

# ========================
# Storage Account
# ========================

resource "azurerm_storage_account" "storage" {
  name                            = azurecaf_name.storage.result
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  shared_access_key_enabled       = false
  allow_nested_items_to_be_public = false
  tags = {
    Environment = var.environment
  }
}

resource "azurerm_storage_container" "assets" {
  name                  = var.blob_container_name
  storage_account_id    = azurerm_storage_account.storage.id
  container_access_type = "private"
}

# ========================
# Service Bus Namespace & Queue
# ========================

resource "azurerm_servicebus_namespace" "servicebus" {
  name                = azurecaf_name.servicebus.result
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  tags = {
    Environment = var.environment
  }
}

resource "azurerm_servicebus_queue" "image_processing" {
  name         = var.servicebus_queue_name
  namespace_id = azurerm_servicebus_namespace.servicebus.id
}

# ========================
# VNet + Subnet + NSG for AKS
# (Required by subscription policy: subnets must have NSG)
# ========================

# ========================
# NSG + VNet (subnet inline with NSG — required by subscription deny policy)
# ========================

resource "azurerm_network_security_group" "aks" {
  name                = "nsg-aks-${var.project_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags = {
    Environment = var.environment
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.project_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.1.0.0/16"]

  subnet {
    name             = "snet-aks"
    address_prefixes = ["10.1.0.0/22"]
    security_group   = azurerm_network_security_group.aks.id
  }

  depends_on = [azurerm_network_security_group.aks]

  lifecycle {
    ignore_changes = [subnet]
  }

  tags = {
    Environment = var.environment
  }
}

# ========================
# PostgreSQL Flexible Server
# ========================

resource "azurerm_postgresql_flexible_server" "postgres" {
  name                   = azurecaf_name.postgres.result
  resource_group_name    = azurerm_resource_group.rg.name
  location               = var.postgres_location
  version                = "16"
  administrator_login    = var.postgres_admin_user
  administrator_password = var.postgres_admin_password
  storage_mb             = 32768
  sku_name               = "B_Standard_B1ms"
  zone                   = "1"

  authentication {
    active_directory_auth_enabled = true
    password_auth_enabled         = true
    tenant_id                     = data.azurerm_client_config.current.tenant_id
  }

  tags = {
    Environment = var.environment
  }
}

resource "azurerm_postgresql_flexible_server_database" "db" {
  name      = var.database_name
  server_id = azurerm_postgresql_flexible_server.postgres.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

# Allow Azure services (IP 0.0.0.0 = allow Azure internal traffic)
resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_azure_services" {
  name             = "allow-azure-services"
  server_id        = azurerm_postgresql_flexible_server.postgres.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# ========================
# User-Assigned Managed Identity (Workload Identity)
# ========================

resource "azurerm_user_assigned_identity" "workload_identity" {
  name                = azurecaf_name.workload_identity.result
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags = {
    Environment = var.environment
  }
}

# Storage Blob Data Contributor for workload identity
resource "azurerm_role_assignment" "workload_storage_contributor" {
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.workload_identity.principal_id
  depends_on           = [azurerm_user_assigned_identity.workload_identity]
}

# Azure Service Bus Data Owner for workload identity
resource "azurerm_role_assignment" "workload_servicebus_owner" {
  scope                = azurerm_servicebus_namespace.servicebus.id
  role_definition_name = "Azure Service Bus Data Owner"
  principal_id         = azurerm_user_assigned_identity.workload_identity.principal_id
  depends_on           = [azurerm_user_assigned_identity.workload_identity]
}

# ========================
# AKS Cluster
# ========================

resource "azurerm_kubernetes_cluster" "aks" {
  name                = azurecaf_name.aks.result
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.project_name
  kubernetes_version  = var.kubernetes_version

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  default_node_pool {
    name            = "default"
    node_count      = var.node_count
    vm_size         = var.node_vm_size
    os_disk_size_gb = 30
  vnet_subnet_id  = tolist(azurerm_virtual_network.vnet.subnet)[0].id
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "kubenet"
    load_balancer_sku = "standard"
    pod_cidr          = "10.244.0.0/16"
    service_cidr      = "10.2.0.0/16"
    dns_service_ip    = "10.2.0.10"
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id
  }

  depends_on = [azurerm_virtual_network.vnet]

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# AcrPull role for AKS kubelet identity → ACR
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_id               = "/subscriptions/${var.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/7f951dda-4ed3-4680-a7ca-43fe172d538d"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
  depends_on                       = [azurerm_kubernetes_cluster.aks]
}

# Key Vault Secrets User for AKS Key Vault secrets provider identity
resource "azurerm_role_assignment" "aks_kv_secrets_user" {
  scope                = azurerm_key_vault.keyvault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_kubernetes_cluster.aks.key_vault_secrets_provider[0].secret_identity[0].object_id
  depends_on           = [azurerm_kubernetes_cluster.aks]
}

# ========================
# Federated Identity Credentials (Workload Identity)
# ========================

# Web service account federation
resource "azurerm_federated_identity_credential" "web_federated" {
  name                = "web-federated-credential"
  resource_group_name = azurerm_resource_group.rg.name
  parent_id           = azurerm_user_assigned_identity.workload_identity.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.aks.oidc_issuer_url
  subject             = "system:serviceaccount:${var.web_namespace}:${var.web_service_account}"
  depends_on          = [azurerm_kubernetes_cluster.aks, azurerm_user_assigned_identity.workload_identity]
}

# Worker service account federation
resource "azurerm_federated_identity_credential" "worker_federated" {
  name                = "worker-federated-credential"
  resource_group_name = azurerm_resource_group.rg.name
  parent_id           = azurerm_user_assigned_identity.workload_identity.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.aks.oidc_issuer_url
  subject             = "system:serviceaccount:${var.web_namespace}:${var.worker_service_account}"
  depends_on          = [azurerm_kubernetes_cluster.aks, azurerm_user_assigned_identity.workload_identity]
}

# ========================
# Key Vault Secrets
# ========================

# Store PostgreSQL FQDN in Key Vault for SecretProviderClass
resource "azurerm_key_vault_secret" "postgres_fqdn" {
  name             = "postgres-fqdn"
  value            = azurerm_postgresql_flexible_server.postgres.fqdn
  key_vault_id     = azurerm_key_vault.keyvault.id
  expiration_date  = "2026-05-29T00:00:00Z"
  depends_on       = [azurerm_role_assignment.kv_secrets_officer_current_user]
}

resource "azurerm_key_vault_secret" "postgres_database" {
  name         = "postgres-database"
  value        = var.database_name
  key_vault_id = azurerm_key_vault.keyvault.id
  depends_on   = [azurerm_role_assignment.kv_secrets_officer_current_user]
}
