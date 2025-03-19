#!/bin/bash

# Azure Deployment Script for Assets Manager
# Execute with: ./deploy-to-azure.sh -ResourceGroupName "my-rg" -Location "eastus" -Prefix "myapp"
# Make sure to run chmod +x deploy-to-azure.sh before using

# Default parameters
ResourceGroupName="assets-manager-rg"
Location="eastus"
Prefix="assetsapp"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -ResourceGroupName)
      ResourceGroupName="$2"
      shift 2
      ;;
    -Location)
      Location="$2"
      shift 2
      ;;
    -Prefix)
      Prefix="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

# Define resource names
ContainerName="images"
# Add timestamp suffix to PostgreSQL server name for uniqueness (format that complies with PostgreSQL naming restrictions)
DATETIME=$(date '+%Y%m%d%H%M%S')
RandomSuffix=$((1000 + RANDOM % 9000))
PostgresServerName="${Prefix}db"
PostgresDBName="assets_manager"
PostgresAdmin="postgresadmin"
ServiceBusNamespace="${Prefix}-servicebus"
QueueName="image-processing"
StorageAccountName="${Prefix}storage"
WebAppName="${Prefix}-web"
WorkerAppName="${Prefix}-worker"
EnvironmentName="${Prefix}-env"
AcrName="${Prefix}registry"
WebServiceConnectorName="web_postgres"
WorkerServiceConnectorName="worker_postgres"

echo "==========================================="
echo "Deploying Assets Manager to Azure"
echo "==========================================="
echo "Resource Group: $ResourceGroupName"
echo "Location: $Location"
echo "Resources prefix: $Prefix"
echo "PostgreSQL Server: $PostgresServerName"
echo "==========================================="

# Check prerequisites
echo "Checking prerequisites..."
if ! command -v az &> /dev/null; then
    echo "Azure CLI not found. Please install it: https://docs.microsoft.com/cli/azure/install-azure-cli"
    exit 1
fi

if ! command -v mvn &> /dev/null; then
    echo "Maven not found. Please install it: https://maven.apache.org/install.html"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo "Docker not found. Please install it: https://docs.docker.com/get-docker/"
    exit 1
fi

echo "Please ensure you are logged into Azure before running this script."
echo "You can log in by running 'az login' separately if needed."

# Create resource group
echo "Creating resource group..."
az group create --name "$ResourceGroupName" --location "$Location"
if [ $? -ne 0 ]; then
    echo "Failed to create resource group. Exiting."
    exit 1
fi
echo "Resource group created."

# Get tenant ID for AAD configuration
TenantId=$(az account show --query tenantId -o tsv)
if [ -z "$TenantId" ]; then
    echo "Failed to get Tenant ID. Exiting."
    exit 1
fi

# Create Azure PostgreSQL server with Microsoft Entra authentication enabled early
echo "Creating Azure PostgreSQL server with Microsoft Entra authentication..."
RANDOM_TIME=$(date +%N)
randomPassword="Pstpwd01"

az postgres flexible-server create \
  --resource-group "$ResourceGroupName" \
  --name "$PostgresServerName" \
  --location "$Location" \
  --admin-user "$PostgresAdmin" \
  --admin-password "$randomPassword" \
  --sku-name Standard_B1ms \
  --tier Burstable \
  --storage-size 32 \
  --version 15 \
  --yes
if [ $? -ne 0 ]; then
    echo "Failed to create PostgreSQL server. Exiting."
    exit 1
fi
echo "PostgreSQL server created."

# Enable Microsoft Entra authentication
echo "Enabling Microsoft Entra authentication..."
az postgres flexible-server update \
  --resource-group "$ResourceGroupName" \
  --name "$PostgresServerName" \
  --set "authConfig.activeDirectoryAuth=enabled" \
  --set "authConfig.tenantId=$TenantId"
if [ $? -ne 0 ]; then
    echo "Failed to enable Microsoft Entra authentication. Exiting."
    exit 1
fi
echo "Microsoft Entra authentication enabled."

echo "Creating PostgreSQL database..."
az postgres flexible-server db create \
  --resource-group "$ResourceGroupName" \
  --server-name "$PostgresServerName" \
  --database-name "$PostgresDBName"
if [ $? -ne 0 ]; then
    echo "Failed to create PostgreSQL database. Exiting."
    exit 1
fi
echo "PostgreSQL database created."

# Allow Azure services to access PostgreSQL server
echo "Configuring PostgreSQL firewall rules..."
az postgres flexible-server firewall-rule create \
  --resource-group "$ResourceGroupName" \
  --name "$PostgresServerName" \
  --rule-name "AllowAzureServices" \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0
if [ $? -ne 0 ]; then
    echo "Failed to configure PostgreSQL firewall rules. Exiting."
    exit 1
fi
echo "PostgreSQL firewall rules configured."

# Create managed identities first
echo "Creating managed identities..."
az identity create \
  --resource-group "$ResourceGroupName" \
  --name "${WebAppName}-identity"
if [ $? -ne 0 ]; then
    echo "Failed to create Web app managed identity. Exiting."
    exit 1
fi
echo "Web app managed identity created."

az identity create \
  --resource-group "$ResourceGroupName" \
  --name "${WorkerAppName}-identity"
if [ $? -ne 0 ]; then
    echo "Failed to create Worker app managed identity. Exiting."
    exit 1
fi
echo "Worker app managed identity created."

# Get identity details early
echo "Getting identity details..."
WebIdentityId=$(az identity show --resource-group "$ResourceGroupName" --name "${WebAppName}-identity" --query id -o tsv)
if [ -z "$WebIdentityId" ]; then
    echo "Failed to get Web Identity ID. Exiting."
    exit 1
fi

WebIdentityClientId=$(az identity show --resource-group "$ResourceGroupName" --name "${WebAppName}-identity" --query clientId -o tsv)
if [ -z "$WebIdentityClientId" ]; then
    echo "Failed to get Web Identity Client ID. Exiting."
    exit 1
fi

WebIdentityPrincipalId=$(az identity show --resource-group "$ResourceGroupName" --name "${WebAppName}-identity" --query principalId -o tsv)
if [ -z "$WebIdentityPrincipalId" ]; then
    echo "Failed to get Web Identity Principal ID. Exiting."
    exit 1
fi

WorkerIdentityId=$(az identity show --resource-group "$ResourceGroupName" --name "${WorkerAppName}-identity" --query id -o tsv)
if [ -z "$WorkerIdentityId" ]; then
    echo "Failed to get Worker Identity ID. Exiting."
    exit 1
fi

WorkerIdentityClientId=$(az identity show --resource-group "$ResourceGroupName" --name "${WorkerAppName}-identity" --query clientId -o tsv)
if [ -z "$WorkerIdentityClientId" ]; then
    echo "Failed to get Worker Identity Client ID. Exiting."
    exit 1
fi

WorkerIdentityPrincipalId=$(az identity show --resource-group "$ResourceGroupName" --name "${WorkerAppName}-identity" --query principalId -o tsv)
if [ -z "$WorkerIdentityPrincipalId" ]; then
    echo "Failed to get Worker Identity Principal ID. Exiting."
    exit 1
fi
echo "Identity details retrieved."

# Create Azure Container Registry
echo "Creating Azure Container Registry..."
az acr create --resource-group "$ResourceGroupName" --name "$AcrName" --sku Basic
if [ $? -ne 0 ]; then
    echo "Failed to create Azure Container Registry. Exiting."
    exit 1
fi
echo "ACR created."

az acr login --name "$AcrName"
if [ $? -ne 0 ]; then
    echo "Failed to log in to ACR. Exiting."
    exit 1
fi
echo "Logged in to ACR."

# Create Azure Service Bus namespace and queue
echo "Creating Azure Service Bus namespace..."
az servicebus namespace create \
  --resource-group "$ResourceGroupName" \
  --name "$ServiceBusNamespace" \
  --location "$Location" \
  --sku Standard
if [ $? -ne 0 ]; then
    echo "Failed to create Service Bus namespace. Exiting."
    exit 1
fi
echo "Service Bus namespace created."

echo "Creating Service Bus queue..."
az servicebus queue create \
  --resource-group "$ResourceGroupName" \
  --namespace-name "$ServiceBusNamespace" \
  --name "$QueueName"
if [ $? -ne 0 ]; then
    echo "Failed to create Service Bus queue. Exiting."
    exit 1
fi
echo "Service Bus queue created."

# Create Azure Storage account and container
echo "Creating Azure Storage account..."
az storage account create \
  --resource-group "$ResourceGroupName" \
  --name "$StorageAccountName" \
  --location "$Location" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --enable-hierarchical-namespace false \
  --allow-blob-public-access true
if [ $? -ne 0 ]; then
    echo "Failed to create Storage account. Exiting."
    exit 1
fi
echo "Storage account created."

echo "Creating Blob container..."
StorageKey=$(az storage account keys list --resource-group "$ResourceGroupName" --account-name "$StorageAccountName" --query [0].value -o tsv)
if [ -z "$StorageKey" ]; then
    echo "Failed to get Storage account key. Exiting."
    exit 1
fi

az storage container create \
  --name "$ContainerName" \
  --account-name "$StorageAccountName" \
  --account-key "$StorageKey" \
  --public-access container
if [ $? -ne 0 ]; then
    echo "Failed to create Blob container. Exiting."
    exit 1
fi
echo "Blob container created."

# Create Container Apps environment
echo "Creating Container Apps environment..."
az containerapp env create \
  --resource-group "$ResourceGroupName" \
  --name "$EnvironmentName" \
  --location "$Location"
if [ $? -ne 0 ]; then
    echo "Failed to create Container Apps environment. Exiting."
    exit 1
fi
echo "Container Apps environment created."

# Get current subscription ID
SubscriptionId=$(az account show --query id -o tsv)
if [ -z "$SubscriptionId" ]; then
    echo "Failed to get Subscription ID. Exiting."
    exit 1
fi
echo "Using Subscription ID: $SubscriptionId"

# Create Dockerfiles for both modules
echo "Creating Dockerfile for web module..."
cat > web/Dockerfile << EOF
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
EOF
if [ $? -ne 0 ]; then
    echo "Failed to create Web module Dockerfile. Exiting."
    exit 1
fi
echo "Web module Dockerfile created."

echo "Creating Dockerfile for worker module..."
cat > worker/Dockerfile << EOF
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY target/*.jar app.jar
EXPOSE 8081
ENTRYPOINT ["java", "-jar", "app.jar"]
EOF
if [ $? -ne 0 ]; then
    echo "Failed to create Worker module Dockerfile. Exiting."
    exit 1
fi
echo "Worker module Dockerfile created."

# Package and build Docker images
echo "Building web module..."
cd web
../mvnw clean package -DskipTests
if [ $? -ne 0 ]; then
    echo "Failed to build Web module. Exiting."
    cd ..
    exit 1
fi
cd ..
echo "Web module built."

echo "Building worker module..."
cd worker
../mvnw clean package -DskipTests
if [ $? -ne 0 ]; then
    echo "Failed to build Worker module. Exiting."
    cd ..
    exit 1
fi
cd ..
echo "Worker module built."

# Build and push Docker images to ACR
echo "Building and pushing Docker images to ACR..."
AcrLoginServer=$(az acr show --name "$AcrName" --resource-group "$ResourceGroupName" --query loginServer -o tsv)
if [ -z "$AcrLoginServer" ]; then
    echo "Failed to get ACR login server. Exiting."
    exit 1
fi
echo "Using ACR login server: $AcrLoginServer"

# Web module
echo "Building web Docker image..."
cd web
docker build -t "${AcrLoginServer}/${WebAppName}:latest" .
if [ $? -ne 0 ]; then
    echo "Failed to build Web Docker image. Exiting."
    cd ..
    exit 1
fi

echo "Pushing web Docker image to ACR..."
docker push "${AcrLoginServer}/${WebAppName}:latest"
if [ $? -ne 0 ]; then
    echo "Failed to push Web Docker image to ACR. Exiting."
    cd ..
    exit 1
fi
cd ..
echo "Web Docker image pushed to ACR."

# Worker module
echo "Building worker Docker image..."
cd worker
docker build -t "${AcrLoginServer}/${WorkerAppName}:latest" .
if [ $? -ne 0 ]; then
    echo "Failed to build Worker Docker image. Exiting."
    cd ..
    exit 1
fi

echo "Pushing worker Docker image to ACR..."
docker push "${AcrLoginServer}/${WorkerAppName}:latest"
if [ $? -ne 0 ]; then
    echo "Failed to push Worker Docker image to ACR. Exiting."
    cd ..
    exit 1
fi
cd ..
echo "Worker Docker image pushed to ACR."

# Create Container Apps with user-assigned managed identities
echo "Creating Container App for web module..."
az containerapp create \
  --resource-group "$ResourceGroupName" \
  --name "$WebAppName" \
  --environment "$EnvironmentName" \
  --image "${AcrLoginServer}/${WebAppName}:latest" \
  --registry-server "$AcrLoginServer" \
  --target-port 8080 \
  --ingress external \
  --user-assigned "$WebIdentityId" \
  --registry-identity "$WebIdentityId" \
  --min-replicas 1 \
  --max-replicas 3 \
  --env-vars "AZURE_CLIENT_ID=${WebIdentityClientId}" \
              "AZURE_STORAGE_ACCOUNT_NAME=${StorageAccountName}" \
              "AZURE_STORAGE_BLOB_CONTAINER_NAME=${ContainerName}" \
              "AZURE_SERVICEBUS_NAMESPACE=${ServiceBusNamespace}"
if [ $? -ne 0 ]; then
    echo "Failed to create Web Container App. Exiting."
    exit 1
fi
echo "Web Container App created."

echo "Creating Container App for worker module..."
az containerapp create \
  --resource-group "$ResourceGroupName" \
  --name "$WorkerAppName" \
  --environment "$EnvironmentName" \
  --image "${AcrLoginServer}/${WorkerAppName}:latest" \
  --registry-server "$AcrLoginServer" \
  --target-port 8081 \
  --ingress internal \
  --user-assigned "$WorkerIdentityId" \
  --registry-identity "$WorkerIdentityId" \
  --min-replicas 1 \
  --max-replicas 3 \
  --env-vars "AZURE_CLIENT_ID=${WorkerIdentityClientId}" \
              "AZURE_STORAGE_ACCOUNT_NAME=${StorageAccountName}" \
              "AZURE_STORAGE_BLOB_CONTAINER_NAME=${ContainerName}" \
              "AZURE_SERVICEBUS_NAMESPACE=${ServiceBusNamespace}"
if [ $? -ne 0 ]; then
    echo "Failed to create Worker Container App. Exiting."
    exit 1
fi
echo "Worker Container App created."

# For user-assigned identities, we already have the identity details
echo "Using previously retrieved managed identity details..."

# Set environment variables for the apps - update for user-assigned identity
echo "Setting environment variables for Container Apps..."
az containerapp update \
  --resource-group "$ResourceGroupName" \
  --name "$WebAppName" \
  --set-env-vars "AZURE_CLIENT_ID=${WebIdentityClientId}"
if [ $? -ne 0 ]; then
    echo "Failed to set environment variables for Web Container App."
    exit 1
fi

az containerapp update \
  --resource-group "$ResourceGroupName" \
  --name "$WorkerAppName" \
  --set-env-vars "AZURE_CLIENT_ID=${WorkerIdentityClientId}"
if [ $? -ne 0 ]; then
    echo "Failed to set environment variables for Worker Container App."
    exit 1
fi
echo "Container App environment variables set."

# Assign roles to the managed identities - use the user identity principal IDs
echo "Assigning roles to managed identities..."
# Storage Blob Data Contributor role for both web and worker
az role assignment create \
  --assignee-object-id "$WebIdentityPrincipalId" \
  --assignee-principal-type ServicePrincipal \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/${SubscriptionId}/resourceGroups/${ResourceGroupName}/providers/Microsoft.Storage/storageAccounts/${StorageAccountName}"
if [ $? -ne 0 ]; then
    echo "Failed to assign Storage Blob Data Contributor role to Web app identity. Exiting."
    exit 1
fi
echo "Web app Storage Blob Data Contributor role assigned."

az role assignment create \
  --assignee-object-id "$WorkerIdentityPrincipalId" \
  --assignee-principal-type ServicePrincipal \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/${SubscriptionId}/resourceGroups/${ResourceGroupName}/providers/Microsoft.Storage/storageAccounts/${StorageAccountName}"
if [ $? -ne 0 ]; then
    echo "Failed to assign Storage Blob Data Contributor role to Worker app identity. Exiting."
    exit 1
fi
echo "Worker app Storage Blob Data Contributor role assigned."

# Service Bus Data Sender role for web
az role assignment create \
  --assignee-object-id "$WebIdentityPrincipalId" \
  --assignee-principal-type ServicePrincipal \
  --role "Azure Service Bus Data Sender" \
  --scope "/subscriptions/${SubscriptionId}/resourceGroups/${ResourceGroupName}/providers/Microsoft.ServiceBus/namespaces/${ServiceBusNamespace}"
if [ $? -ne 0 ]; then
    echo "Failed to assign Service Bus Data Sender role to Web app identity. Exiting."
    exit 1
fi
echo "Web app Service Bus Data Sender role assigned."

# Service Bus Data Receiver role for worker
az role assignment create \
  --assignee-object-id "$WorkerIdentityPrincipalId" \
  --assignee-principal-type ServicePrincipal \
  --role "Azure Service Bus Data Receiver" \
  --scope "/subscriptions/${SubscriptionId}/resourceGroups/${ResourceGroupName}/providers/Microsoft.ServiceBus/namespaces/${ServiceBusNamespace}"
if [ $? -ne 0 ]; then
    echo "Failed to assign Service Bus Data Receiver role to Worker app identity. Exiting."
    exit 1
fi
echo "Worker app Service Bus Data Receiver role assigned."

# Service Bus Data Owner role for worker (needed for context.abandon() and context.complete() in ServiceBusListener)
az role assignment create \
  --assignee-object-id "$WorkerIdentityPrincipalId" \
  --assignee-principal-type ServicePrincipal \
  --role "Azure Service Bus Data Owner" \
  --scope "/subscriptions/${SubscriptionId}/resourceGroups/${ResourceGroupName}/providers/Microsoft.ServiceBus/namespaces/${ServiceBusNamespace}"
if [ $? -ne 0 ]; then
    echo "Failed to assign Service Bus Data Owner role to Worker app identity. Exiting."
    exit 1
fi
echo "Worker app Service Bus Data Owner role assigned."

# Use Service Connector to connect apps to PostgreSQL with user-assigned managed identity
echo "Creating Service Connector between Web app and PostgreSQL..."
az containerapp connection create postgres-flexible \
  --client-type springboot \
  --resource-group "$ResourceGroupName" \
  --name "$WebAppName" \
  --container "$WebAppName" \
  --target-resource-group "$ResourceGroupName" \
  --server "$PostgresServerName" \
  --database "$PostgresDBName" \
  --user-identity "client-id=${WebIdentityClientId} subs-id=${SubscriptionId}" \
  --connection "$WebServiceConnectorName"
if [ $? -ne 0 ]; then
    echo "Failed to create Service Connector between Web app and PostgreSQL. Exiting."
    exit 1
fi
echo "Web app Service Connector to PostgreSQL created."

echo "Creating Service Connector between Worker app and PostgreSQL..."
az containerapp connection create postgres-flexible \
  --client-type springboot \
  --resource-group "$ResourceGroupName" \
  --name "$WorkerAppName" \
  --container "$WorkerAppName" \
  --target-resource-group "$ResourceGroupName" \
  --server "$PostgresServerName" \
  --database "$PostgresDBName" \
  --user-identity "client-id=${WorkerIdentityClientId} subs-id=${SubscriptionId}" \
  --connection "$WorkerServiceConnectorName"
if [ $? -ne 0 ]; then
    echo "Failed to create Service Connector between Worker app and PostgreSQL. Exiting."
    exit 1
fi
echo "Worker app Service Connector to PostgreSQL created."

# Get the web app URL
WebAppUrl=$(az containerapp show --resource-group "$ResourceGroupName" --name "$WebAppName" --query properties.configuration.ingress.fqdn -o tsv)
if [ -z "$WebAppUrl" ]; then
    echo "Failed to get Web Application URL, but deployment is complete."
fi

echo "==========================================="
echo "Deployment complete!"
echo "==========================================="
echo "Resource Group: $ResourceGroupName"
if [ -n "$WebAppUrl" ]; then
    echo "Web Application URL: https://$WebAppUrl"
fi
echo "Storage Account: $StorageAccountName"
echo "Service Bus Namespace: $ServiceBusNamespace"
echo "PostgreSQL Server: $PostgresServerName"
echo "==========================================="