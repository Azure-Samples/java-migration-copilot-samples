output "resource_group_name" {
  description = "Name of the Azure resource group"
  value       = azurerm_resource_group.rg.name
}

output "aks_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "aks_resource_id" {
  description = "Resource ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.id
}

output "aks_oidc_issuer_url" {
  description = "OIDC issuer URL for workload identity federation"
  value       = azurerm_kubernetes_cluster.aks.oidc_issuer_url
}

output "aks_kv_identity_client_id" {
  description = "Client ID of the AKS Key Vault secrets provider identity (for SecretProviderClass)"
  value       = azurerm_kubernetes_cluster.aks.key_vault_secrets_provider[0].secret_identity[0].client_id
}

output "acr_login_server" {
  description = "ACR login server URL"
  value       = azurerm_container_registry.acr.login_server
}

output "acr_name" {
  description = "Name of the Azure Container Registry"
  value       = azurerm_container_registry.acr.name
}

output "storage_account_name" {
  description = "Name of the Azure Storage account"
  value       = azurerm_storage_account.storage.name
}

output "blob_container_name" {
  description = "Name of the blob container for assets"
  value       = azurerm_storage_container.assets.name
}

output "servicebus_namespace" {
  description = "Name of the Azure Service Bus namespace"
  value       = azurerm_servicebus_namespace.servicebus.name
}

output "servicebus_queue_name" {
  description = "Name of the Service Bus queue"
  value       = azurerm_servicebus_queue.image_processing.name
}

output "postgres_server_name" {
  description = "Name of the PostgreSQL flexible server"
  value       = azurerm_postgresql_flexible_server.postgres.name
}

output "postgres_fqdn" {
  description = "FQDN of the PostgreSQL flexible server"
  value       = azurerm_postgresql_flexible_server.postgres.fqdn
}

output "postgres_resource_id" {
  description = "Resource ID of the PostgreSQL server (used for Service Connector)"
  value       = azurerm_postgresql_flexible_server.postgres.id
}

output "key_vault_name" {
  description = "Name of the Azure Key Vault"
  value       = azurerm_key_vault.keyvault.name
}

output "workload_identity_client_id" {
  description = "Client ID of the workload identity (inject as AZURE_CLIENT_ID in pods)"
  value       = azurerm_user_assigned_identity.workload_identity.client_id
}

output "tenant_id" {
  description = "Azure tenant ID"
  value       = data.azurerm_client_config.current.tenant_id
}

output "location" {
  description = "Azure region where resources are deployed"
  value       = azurerm_resource_group.rg.location
}

output "app_insights_connection_string" {
  description = "Application Insights connection string"
  value       = azurerm_application_insights.appinsights.connection_string
  sensitive   = true
}
