#!/bin/bash

# Azure Deployment Script for Assets Manager
# Execute with: ./scripts/deploy-to-azure.sh -ResourceGroupName "my-rg" -Location "eastus" -Prefix "myapp"

# Default parameters
ResourceGroupName="assets-manager-rg"
Location="eastus2"
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
PostgresServerName="${Prefix}db"
PostgresDBName="assets_manager"
ServiceBusNamespace="${Prefix}-servicebus"
QueueName="image-processing"
StorageAccountName="${Prefix}storage"
ContainerName="images"
WebAppName="${Prefix}-web"
WorkerAppName="${Prefix}-worker"
EnvironmentName="${Prefix}-env"
AcrName="${Prefix}registry"
IdentityName="${Prefix}-identity"
ServiceConnectorName="postgres_connection"

echo "==========================================="
echo "Deploying Assets Manager to Azure"
echo "==========================================="
echo "Resource Group: $ResourceGroupName"
echo "Location: $Location"
echo "Resources prefix: $Prefix"
echo "==========================================="

# Check prerequisites
echo "Checking prerequisites..."
if ! command -v az &> /dev/null; then
    echo "Azure CLI not found. Please install it: https://docs.microsoft.com/cli/azure/install-azure-cli"
    exit 1
fi
echo "Prerequisites satisfied."

echo "Please ensure you are logged into Azure before running this script."
echo "You can log in by running 'az login' separately if needed."

# Get current subscription ID
SubscriptionId=$(az account show --query id -o tsv)
if [ -z "$SubscriptionId" ]; then
    echo "Failed to get Subscription ID. Exiting."
    exit 1
fi
echo "Using Subscription ID: $SubscriptionId"

# Register Microsoft.DBforPostgreSQL provider and wait until completion
echo "Registering Microsoft.DBforPostgreSQL provider..."
az provider register --namespace Microsoft.DBforPostgreSQL --wait
if [ $? -ne 0 ]; then
    echo "Failed to register Microsoft.DBforPostgreSQL provider. Exiting."
    exit 1
fi
echo "Microsoft.DBforPostgreSQL provider registration completed."

# Add Azure CLI extensions
echo "Adding/upgrading Azure CLI extensions..."
az extension add --name containerapp --upgrade
az extension add --name rdbms-connect --upgrade
az extension add --name serviceconnector-passwordless --upgrade
echo "Azure CLI extensions added/upgraded."

# Create resource group
echo "Creating resource group..."
az group create --name "$ResourceGroupName" --location "$Location"
if [ $? -ne 0 ]; then
    echo "Failed to create resource group. Exiting."
    exit 1
fi
echo "Resource group created."

# Create Azure PostgreSQL server with Microsoft Entra authentication enabled and database
echo "Creating Azure PostgreSQL server with Microsoft Entra authentication and database..."
az postgres flexible-server create \
  --resource-group "$ResourceGroupName" \
  --name "$PostgresServerName" \
  --location "$Location" \
  --database-name "$PostgresDBName" \
  --public-access 0.0.0.0 \
  --sku-name Standard_B1ms \
  --tier Burstable \
  --active-directory-auth Enabled
if [ $? -ne 0 ]; then
    echo "Failed to create PostgreSQL server and database. Exiting."
    exit 1
fi
echo "PostgreSQL server and database created."

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

# Create Azure Container Registry
echo "Creating Azure Container Registry..."
az acr create --resource-group "$ResourceGroupName" --name "$AcrName" --sku Basic
if [ $? -ne 0 ]; then
    echo "Failed to create Azure Container Registry. Exiting."
    exit 1
fi
echo "ACR created."
AcrLoginServer=$(az acr show --name "$AcrName" --resource-group "$ResourceGroupName" --query loginServer -o tsv)
if [ -z "$AcrLoginServer" ]; then
    echo "Failed to get ACR login server. Exiting."
    exit 1
fi
echo "Using ACR login server: $AcrLoginServer"

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

# Create managed identity for web and worker apps
echo "Creating managed identity..."
az identity create \
  --resource-group "$ResourceGroupName" \
  --name "${IdentityName}"
if [ $? -ne 0 ]; then
    echo "Failed to create managed identity. Exiting."
    exit 1
fi
echo "Managed identity created."

# Get identity details
echo "Getting identity details..."
IdentityId=$(az identity show --resource-group "$ResourceGroupName" --name "${IdentityName}" --query id -o tsv)
if [ -z "$IdentityId" ]; then
    echo "Failed to get Identity ID. Exiting."
    exit 1
fi

IdentityClientId=$(az identity show --resource-group "$ResourceGroupName" --name "${IdentityName}" --query clientId -o tsv)
if [ -z "$IdentityClientId" ]; then
    echo "Failed to get Identity Client ID. Exiting."
    exit 1
fi

IdentityPrincipalId=$(az identity show --resource-group "$ResourceGroupName" --name "${IdentityName}" --query principalId -o tsv)
if [ -z "$IdentityPrincipalId" ]; then
    echo "Failed to get Identity Principal ID. Exiting."
    exit 1
fi
echo "Identity details retrieved."

# Assign roles to the managed identity - use the user identity principal ID
echo "Assigning roles to managed identity..."
# Storage Blob Data Contributor role
az role assignment create \
  --assignee-object-id "$IdentityPrincipalId" \
  --assignee-principal-type ServicePrincipal \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/${SubscriptionId}/resourceGroups/${ResourceGroupName}/providers/Microsoft.Storage/storageAccounts/${StorageAccountName}"
if [ $? -ne 0 ]; then
    echo "Failed to assign Storage Blob Data Contributor role to identity. Exiting."
    exit 1
fi
echo "Storage Blob Data Contributor role assigned."

# Service Bus Data Owner role (needed for resolving 401 issue in web and context.abandon() and context.complete() in ServiceBusListener of worker)
az role assignment create \
  --assignee-object-id "$IdentityPrincipalId" \
  --assignee-principal-type ServicePrincipal \
  --role "Azure Service Bus Data Owner" \
  --scope "/subscriptions/${SubscriptionId}/resourceGroups/${ResourceGroupName}/providers/Microsoft.ServiceBus/namespaces/${ServiceBusNamespace}"
if [ $? -ne 0 ]; then
    echo "Failed to assign Service Bus Data Owner role to identity. Exiting."
    exit 1
fi
echo "Service Bus Data Owner role assigned."

# Assign AcrPull role to the managed identity
echo "Assigning AcrPull role to managed identity..."
az role assignment create \
  --assignee-object-id "$IdentityPrincipalId" \
  --assignee-principal-type ServicePrincipal \
  --role "acrpull" \
  --scope "/subscriptions/${SubscriptionId}/resourceGroups/${ResourceGroupName}/providers/Microsoft.ContainerRegistry/registries/${AcrName}"
if [ $? -ne 0 ]; then
    echo "Failed to assign AcrPull role to identity. Exiting."
    exit 1
fi
echo "AcrPull role assigned."

# Create Dockerfiles for both modules
echo "Creating Dockerfile for web module..."
cat > web/Dockerfile << EOF
FROM eclipse-temurin:21-jre-alpine
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
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY target/*.jar app.jar
ENTRYPOINT ["java", "-jar", "app.jar"]
EOF
if [ $? -ne 0 ]; then
    echo "Failed to create Worker module Dockerfile. Exiting."
    exit 1
fi
echo "Worker module Dockerfile created."

# Package and build Docker images
echo "Building web and worker modules..."
./mvnw clean package -DskipTests
if [ $? -ne 0 ]; then
    echo "Failed to build web and worker modules. Exiting."
    exit 1
fi
echo "Web and worker modules built."

# Web module
echo "Building web Docker image in ACR..."
az acr build -t "${WebAppName}:latest" -r $AcrName --file ./web/Dockerfile ./web
if [ $? -ne 0 ]; then
    echo "Failed to build Web Docker image in ACR. Exiting."
    exit 1
fi
echo "Web Docker image built and pushed to ACR."
# Worker module
echo "Building worker Docker image in ACR..."
az acr build -t "${WorkerAppName}:latest" -r $AcrName --file ./worker/Dockerfile ./worker
if [ $? -ne 0 ]; then
    echo "Failed to build Worker Docker image in ACR. Exiting."
    exit 1
fi
echo "Worker Docker image built and pushed to ACR."

# Create Container Apps with user-assigned managed identity for web module
echo "Creating Container App for web module..."
az containerapp create \
  --resource-group "$ResourceGroupName" \
  --name "$WebAppName" \
  --environment "$EnvironmentName" \
  --image "${AcrLoginServer}/${WebAppName}:latest" \
  --registry-server "$AcrLoginServer" \
  --target-port 8080 \
  --ingress external \
  --user-assigned "$IdentityId" \
  --registry-identity "$IdentityId" \
  --min-replicas 1 \
  --max-replicas 3 \
  --env-vars "AZURE_CLIENT_ID=${IdentityClientId}" \
             "AZURE_STORAGE_ACCOUNT_NAME=${StorageAccountName}" \
             "AZURE_STORAGE_BLOB_CONTAINER_NAME=${ContainerName}" \
             "AZURE_SERVICEBUS_NAMESPACE=${ServiceBusNamespace}"
if [ $? -ne 0 ]; then
    echo "Failed to create Web Container App. Exiting."
    exit 1
fi
echo "Web Container App created."

# Use Service Connector to connect web app to PostgreSQL with user-assigned managed identity
echo "Creating Service Connector between Web app and PostgreSQL..."
az containerapp connection create postgres-flexible \
  --client-type springBoot \
  --resource-group "$ResourceGroupName" \
  --name "$WebAppName" \
  --container "$WebAppName" \
  --target-resource-group "$ResourceGroupName" \
  --server "$PostgresServerName" \
  --database "$PostgresDBName" \
  --user-identity client-id=${IdentityClientId} subs-id=${SubscriptionId} \
  --connection "$ServiceConnectorName" \
  --customized-keys spring.datasource.username=SPRING_DATASOURCE_USERNAME \
                    spring.datasource.url=SPRING_DATASOURCE_URL \
                    spring.cloud.azure.credential.managed-identity-enabled=SPRING_CLOUD_AZURE_CREDENTIAL_MANAGEDIDENTITYENABLED \
                    spring.datasource.azure.passwordless-enabled=SPRING_DATASOURCE_AZURE_PASSWORDLESSENABLED \
                    spring.cloud.azure.credential.client-id=SPRING_CLOUD_AZURE_CREDENTIAL_CLIENTID \
  --yes
if [ $? -ne 0 ]; then
    echo "Failed to create Service Connector between Web app and PostgreSQL. Exiting."
    exit 1
fi
echo "Web app Service Connector to PostgreSQL created."

# Retrieve values for env vars SPRING_DATASOURCE_USERNAME & SPRING_DATASOURCE_URL injected by service connector
SPRING_DATASOURCE_USERNAME=$(az containerapp connection show \
  --connection $ServiceConnectorName \
  --resource-group "$ResourceGroupName" \
  --name $WebAppName \
  --query "configurations[?name=='SPRING_DATASOURCE_USERNAME'].value" -o tsv)
echo "Using SPRING_DATASOURCE_USERNAME: $SPRING_DATASOURCE_USERNAME"
if [ -z "$SPRING_DATASOURCE_USERNAME" ]; then
    echo "Failed to get SPRING_DATASOURCE_USERNAME. Exiting."
    exit 1
fi
SPRING_DATASOURCE_URL=$(az containerapp connection show \
  --connection $ServiceConnectorName \
  --resource-group "$ResourceGroupName" \
  --name $WebAppName --query "configurations[?name=='SPRING_DATASOURCE_URL'].value" -o tsv)
echo "Using SPRING_DATASOURCE_URL: $SPRING_DATASOURCE_URL"
if [ -z "$SPRING_DATASOURCE_URL" ]; then
    echo "Failed to get SPRING_DATASOURCE_URL. Exiting."
    exit 1
fi

# Create Container Apps with user-assigned managed identity and database connection env vars for worker module
echo "Creating Container App for worker module..."
az containerapp create \
  --resource-group "$ResourceGroupName" \
  --name "$WorkerAppName" \
  --environment "$EnvironmentName" \
  --image "${AcrLoginServer}/${WorkerAppName}:latest" \
  --registry-server "$AcrLoginServer" \
  --user-assigned "$IdentityId" \
  --registry-identity "$IdentityId" \
  --min-replicas 1 \
  --max-replicas 3 \
  --env-vars "AZURE_CLIENT_ID=${IdentityClientId}" \
             "AZURE_STORAGE_ACCOUNT_NAME=${StorageAccountName}" \
             "AZURE_STORAGE_BLOB_CONTAINER_NAME=${ContainerName}" \
             "AZURE_SERVICEBUS_NAMESPACE=${ServiceBusNamespace}" \
             "SPRING_DATASOURCE_USERNAME=${SPRING_DATASOURCE_USERNAME}" \
             "SPRING_DATASOURCE_URL=${SPRING_DATASOURCE_URL}"
if [ $? -ne 0 ]; then
    echo "Failed to create Worker Container App. Exiting."
    exit 1
fi
echo "Worker Container App created."

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