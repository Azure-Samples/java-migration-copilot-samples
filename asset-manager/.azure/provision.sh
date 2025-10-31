#!/bin/bash
set -e  # Exit immediately if a command exits with a non-zero status

# Configuration
LOCATION="northeurope"
RESOURCE_TOKEN=$(openssl rand -hex 2 | tr '[:upper:]' '[:lower:]')  # 4 character random string
RESOURCE_GROUP_NAME="rg${RESOURCE_TOKEN}"
AKS_CLUSTER_NAME="aks${RESOURCE_TOKEN}"
ACR_NAME="acr${RESOURCE_TOKEN}"
STORAGE_ACCOUNT_NAME="st${RESOURCE_TOKEN}"
KEYVAULT_NAME="kv${RESOURCE_TOKEN}"
POSTGRESQL_SERVER_NAME="psql${RESOURCE_TOKEN}"
SERVICEBUS_NAMESPACE="sb${RESOURCE_TOKEN}"
USER_IDENTITY_NAME="id${RESOURCE_TOKEN}"
DATABASE_NAME="assetsdb"
SERVICEBUS_QUEUE_NAME="image-processing"
BLOB_CONTAINER_NAME="assets"

echo "Starting deployment with resource token: $RESOURCE_TOKEN"
echo "Location: $LOCATION"

# Check if resource group exists
if ! az group show --name $RESOURCE_GROUP_NAME &>/dev/null; then
    echo "Creating resource group: $RESOURCE_GROUP_NAME"
    az group create --name $RESOURCE_GROUP_NAME --location $LOCATION
else
    echo "Resource group $RESOURCE_GROUP_NAME already exists"
fi

# Create User-Assigned Managed Identity
if ! az identity show --name $USER_IDENTITY_NAME --resource-group $RESOURCE_GROUP_NAME &>/dev/null; then
    echo "Creating user-assigned managed identity: $USER_IDENTITY_NAME"
    az identity create --name $USER_IDENTITY_NAME --resource-group $RESOURCE_GROUP_NAME --location $LOCATION
else
    echo "User-assigned managed identity $USER_IDENTITY_NAME already exists"
fi

# Get the managed identity details
IDENTITY_ID=$(az identity show --name $USER_IDENTITY_NAME --resource-group $RESOURCE_GROUP_NAME --query id -o tsv)
IDENTITY_CLIENT_ID=$(az identity show --name $USER_IDENTITY_NAME --resource-group $RESOURCE_GROUP_NAME --query clientId -o tsv)
IDENTITY_OBJECT_ID=$(az identity show --name $USER_IDENTITY_NAME --resource-group $RESOURCE_GROUP_NAME --query principalId -o tsv)

echo "Managed Identity ID: $IDENTITY_ID"
echo "Managed Identity Client ID: $IDENTITY_CLIENT_ID"

# Create Key Vault
if ! az keyvault show --name $KEYVAULT_NAME --resource-group $RESOURCE_GROUP_NAME &>/dev/null; then
    echo "Creating Key Vault: $KEYVAULT_NAME"
    az keyvault create --name $KEYVAULT_NAME --resource-group $RESOURCE_GROUP_NAME --location $LOCATION --enable-rbac-authorization
else
    echo "Key Vault $KEYVAULT_NAME already exists"
fi

# Assign Key Vault Secrets User role to managed identity
echo "Assigning Key Vault Secrets User role to managed identity"
az role assignment create --assignee $IDENTITY_OBJECT_ID --role "Key Vault Secrets User" --scope "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.KeyVault/vaults/$KEYVAULT_NAME" || true

# Create Storage Account
if ! az storage account show --name $STORAGE_ACCOUNT_NAME --resource-group $RESOURCE_GROUP_NAME &>/dev/null; then
    echo "Creating storage account: $STORAGE_ACCOUNT_NAME"
    az storage account create \
        --name $STORAGE_ACCOUNT_NAME \
        --resource-group $RESOURCE_GROUP_NAME \
        --location $LOCATION \
        --sku Standard_LRS \
        --kind StorageV2 \
        --allow-shared-key-access false \
        --allow-blob-public-access false
else
    echo "Storage account $STORAGE_ACCOUNT_NAME already exists"
fi

# Assign Storage Blob Data Contributor role to managed identity
echo "Assigning Storage Blob Data Contributor role to managed identity"
az role assignment create --assignee $IDENTITY_OBJECT_ID --role "Storage Blob Data Contributor" --scope "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT_NAME" || true

# Create blob container
if ! az storage container show --name $BLOB_CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME --auth-mode login &>/dev/null; then
    echo "Creating blob container: $BLOB_CONTAINER_NAME"
    az storage container create --name $BLOB_CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME --auth-mode login
else
    echo "Blob container $BLOB_CONTAINER_NAME already exists"
fi

# Create PostgreSQL Flexible Server
if ! az postgres flexible-server show --name $POSTGRESQL_SERVER_NAME --resource-group $RESOURCE_GROUP_NAME &>/dev/null; then
    echo "Creating PostgreSQL flexible server: $POSTGRESQL_SERVER_NAME"
    az postgres flexible-server create \
        --name $POSTGRESQL_SERVER_NAME \
        --resource-group $RESOURCE_GROUP_NAME \
        --location $LOCATION \
        --admin-user pgadmin \
        --admin-password "TempPassword123!" \
        --sku-name Standard_B1ms \
        --tier Burstable \
        --storage-size 32 \
        --version 14 \
        --microsoft-entra-auth Enabled \
        --yes
else
    echo "PostgreSQL flexible server $POSTGRESQL_SERVER_NAME already exists"
fi

# Configure PostgreSQL firewall rules
echo "Configuring PostgreSQL firewall rules"
az postgres flexible-server firewall-rule create --name allow-azure-services --server-name $POSTGRESQL_SERVER_NAME --resource-group $RESOURCE_GROUP_NAME --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0 || true

# Create database
if ! az postgres flexible-server db show --server-name $POSTGRESQL_SERVER_NAME --resource-group $RESOURCE_GROUP_NAME --database-name $DATABASE_NAME &>/dev/null; then
    echo "Creating database: $DATABASE_NAME"
    az postgres flexible-server db create --server-name $POSTGRESQL_SERVER_NAME --resource-group $RESOURCE_GROUP_NAME --database-name $DATABASE_NAME
else
    echo "Database $DATABASE_NAME already exists"
fi

# Add managed identity as Azure AD admin for PostgreSQL (required for Azure AD authentication)
echo "Setting up Azure AD admin for PostgreSQL"
az postgres flexible-server ad-admin create --resource-group $RESOURCE_GROUP_NAME --server-name $POSTGRESQL_SERVER_NAME --display-name $USER_IDENTITY_NAME --object-id $IDENTITY_OBJECT_ID --type ServicePrincipal || true

# Create database user for managed identity and grant privileges
echo "Creating database user for managed identity"
CONNECTION_STRING="host=$POSTGRESQL_SERVER_NAME.postgres.database.azure.com port=5432 dbname=$DATABASE_NAME user=pgadmin password=TempPassword123! sslmode=require"

# Create SQL commands to add managed identity user and grant privileges
SQL_COMMANDS="CREATE USER \"$USER_IDENTITY_NAME\" WITH LOGIN;
GRANT ALL PRIVILEGES ON DATABASE $DATABASE_NAME TO \"$USER_IDENTITY_NAME\";
GRANT ALL PRIVILEGES ON SCHEMA public TO \"$USER_IDENTITY_NAME\";
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO \"$USER_IDENTITY_NAME\";
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO \"$USER_IDENTITY_NAME\";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO \"$USER_IDENTITY_NAME\";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO \"$USER_IDENTITY_NAME\";"

# Execute SQL commands (this requires psql client, which may not be available in all environments)
# Alternative: Store these commands for manual execution or use Azure Cloud Shell
echo "Note: Database user creation commands stored for execution:"
echo "$SQL_COMMANDS"

# Create Service Bus namespace
if ! az servicebus namespace show --name $SERVICEBUS_NAMESPACE --resource-group $RESOURCE_GROUP_NAME &>/dev/null; then
    echo "Creating Service Bus namespace: $SERVICEBUS_NAMESPACE"
    az servicebus namespace create --name $SERVICEBUS_NAMESPACE --resource-group $RESOURCE_GROUP_NAME --location $LOCATION --sku Standard
else
    echo "Service Bus namespace $SERVICEBUS_NAMESPACE already exists"
fi

# Create Service Bus queue
if ! az servicebus queue show --name $SERVICEBUS_QUEUE_NAME --namespace-name $SERVICEBUS_NAMESPACE --resource-group $RESOURCE_GROUP_NAME &>/dev/null; then
    echo "Creating Service Bus queue: $SERVICEBUS_QUEUE_NAME"
    az servicebus queue create --name $SERVICEBUS_QUEUE_NAME --namespace-name $SERVICEBUS_NAMESPACE --resource-group $RESOURCE_GROUP_NAME
else
    echo "Service Bus queue $SERVICEBUS_QUEUE_NAME already exists"
fi

# Assign Service Bus Data Owner role to managed identity
echo "Assigning Service Bus Data Owner role to managed identity"
az role assignment create --assignee $IDENTITY_OBJECT_ID --role "Azure Service Bus Data Owner" --scope "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.ServiceBus/namespaces/$SERVICEBUS_NAMESPACE" || true

# Create Container Registry
if ! az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP_NAME &>/dev/null; then
    echo "Creating Azure Container Registry: $ACR_NAME"
    az acr create --name $ACR_NAME --resource-group $RESOURCE_GROUP_NAME --location $LOCATION --sku Basic --admin-enabled false
else
    echo "Azure Container Registry $ACR_NAME already exists"
fi

# Assign AcrPull role to managed identity
echo "Assigning AcrPull role to managed identity"
az role assignment create --assignee $IDENTITY_OBJECT_ID --role "AcrPull" --scope "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.ContainerRegistry/registries/$ACR_NAME" || true

# Get available AKS versions and select a stable one
echo "Getting available AKS versions..."
AKS_VERSION=$(az aks get-versions --location $LOCATION --query "values[?isPreview==null].version" -o tsv | head -1)
echo "Selected AKS version: $AKS_VERSION"

# Create AKS cluster
if ! az aks show --name $AKS_CLUSTER_NAME --resource-group $RESOURCE_GROUP_NAME &>/dev/null; then
    echo "Creating AKS cluster: $AKS_CLUSTER_NAME"
    az aks create \
        --name $AKS_CLUSTER_NAME \
        --resource-group $RESOURCE_GROUP_NAME \
        --location $LOCATION \
        --kubernetes-version $AKS_VERSION \
        --node-count 2 \
        --node-vm-size Standard_D2s_v3 \
        --enable-oidc-issuer \
        --enable-workload-identity \
        --assign-identity $IDENTITY_ID \
        --generate-ssh-keys
else
    echo "AKS cluster $AKS_CLUSTER_NAME already exists"
fi

# Attach ACR to AKS cluster
echo "Attaching ACR to AKS cluster"
az aks update --name $AKS_CLUSTER_NAME --resource-group $RESOURCE_GROUP_NAME --attach-acr $ACR_NAME

# Get AKS credentials
echo "Getting AKS credentials"
az aks get-credentials --name $AKS_CLUSTER_NAME --resource-group $RESOURCE_GROUP_NAME --overwrite-existing

# Get OIDC issuer URL for workload identity
OIDC_ISSUER_URL=$(az aks show --name $AKS_CLUSTER_NAME --resource-group $RESOURCE_GROUP_NAME --query "oidcIssuerProfile.issuerUrl" -o tsv)
echo "OIDC Issuer URL: $OIDC_ISSUER_URL"

# Store configuration values in Key Vault
echo "Storing configuration values in Key Vault"
az keyvault secret set --vault-name $KEYVAULT_NAME --name "AZURE-STORAGE-ACCOUNT-NAME" --value $STORAGE_ACCOUNT_NAME || true
az keyvault secret set --vault-name $KEYVAULT_NAME --name "AZURE-STORAGE-BLOB-CONTAINER-NAME" --value $BLOB_CONTAINER_NAME || true
az keyvault secret set --vault-name $KEYVAULT_NAME --name "AZURE-CLIENT-ID" --value $IDENTITY_CLIENT_ID || true
az keyvault secret set --vault-name $KEYVAULT_NAME --name "AZURE-SERVICEBUS-NAMESPACE" --value "${SERVICEBUS_NAMESPACE}.servicebus.windows.net" || true
az keyvault secret set --vault-name $KEYVAULT_NAME --name "POSTGRESQL-SERVER-NAME" --value $POSTGRESQL_SERVER_NAME || true
az keyvault secret set --vault-name $KEYVAULT_NAME --name "DATABASE-NAME" --value $DATABASE_NAME || true
# Store PostgreSQL connection string for managed identity access
POSTGRES_CONNECTION_STRING="jdbc:postgresql://$POSTGRESQL_SERVER_NAME.postgres.database.azure.com:5432/$DATABASE_NAME?sslmode=require"
az keyvault secret set --vault-name $KEYVAULT_NAME --name "POSTGRESQL-CONNECTION-STRING" --value "$POSTGRES_CONNECTION_STRING" || true
# Store traditional connection string with admin credentials (for initial setup)
POSTGRES_ADMIN_CONNECTION_STRING="jdbc:postgresql://$POSTGRESQL_SERVER_NAME.postgres.database.azure.com:5432/$DATABASE_NAME?sslmode=require&user=pgadmin&password=TempPassword123!"
az keyvault secret set --vault-name $KEYVAULT_NAME --name "POSTGRESQL-ADMIN-CONNECTION-STRING" --value "$POSTGRES_ADMIN_CONNECTION_STRING" || true

echo ""
echo "=================================================="
echo "DEPLOYMENT COMPLETED SUCCESSFULLY!"
echo "=================================================="
echo "Resource Group: $RESOURCE_GROUP_NAME"
echo "AKS Cluster: $AKS_CLUSTER_NAME"
echo "Container Registry: $ACR_NAME"
echo "Storage Account: $STORAGE_ACCOUNT_NAME"
echo "PostgreSQL Server: $POSTGRESQL_SERVER_NAME"
echo "Service Bus Namespace: $SERVICEBUS_NAMESPACE"
echo "Key Vault: $KEYVAULT_NAME"
echo "Managed Identity: $USER_IDENTITY_NAME"
echo "Client ID: $IDENTITY_CLIENT_ID"
echo "OIDC Issuer URL: $OIDC_ISSUER_URL"
echo ""
echo "Next steps:"
echo "1. Configure workload identity for your Kubernetes service accounts"
echo "2. Build and push your Docker images to ACR"
echo "3. Deploy your applications to AKS"
echo "=================================================="