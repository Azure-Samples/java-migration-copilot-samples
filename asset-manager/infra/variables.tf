variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "project_name" {
  description = "Project name used for resource naming (CAF convention)"
  type        = string
  default     = "assetsmanager"
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Primary Azure region for all resources"
  type        = string
  default     = "eastus2"
}

variable "kubernetes_version" {
  description = "AKS Kubernetes version (get stable from: az aks get-versions --query 'values[?isDefault].version' --location <region> -o tsv)"
  type        = string
}

variable "node_count" {
  description = "Number of AKS worker nodes"
  type        = number
  default     = 2
}

variable "node_vm_size" {
  description = "VM size for AKS node pool (from appmod_get_available_region_sku)"
  type        = string
  default     = "Standard_DS2_v2"
}

variable "postgres_admin_user" {
  description = "PostgreSQL administrator login name"
  type        = string
  default     = "pgadmin"
}

variable "postgres_admin_password" {
  description = "PostgreSQL administrator password"
  type        = string
  sensitive   = true
}

variable "database_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "assetsdb"
}

variable "blob_container_name" {
  description = "Azure Blob Storage container name for asset uploads"
  type        = string
  default     = "assets"
}

variable "servicebus_queue_name" {
  description = "Azure Service Bus queue name for image processing messages"
  type        = string
  default     = "image-processing"
}

variable "web_namespace" {
  description = "Kubernetes namespace for application deployments"
  type        = string
  default     = "assets-manager"
}

variable "web_service_account" {
  description = "Kubernetes service account name for the web service"
  type        = string
  default     = "assets-manager-web-sa"
}

variable "worker_service_account" {
  description = "Kubernetes service account name for the worker service"
  type        = string
  default     = "assets-manager-worker-sa"
}

variable "postgres_location" {
  description = "Azure region for PostgreSQL Flexible Server (may differ from primary location due to subscription quota)"
  type        = string
  default     = "canadacentral"
}
