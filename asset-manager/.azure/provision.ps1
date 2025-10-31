# PowerShell script for provisioning Azure resources
$ErrorActionPreference = "Stop"

# Configuration
$LOCATION = "northeurope"
$RESOURCE_TOKEN = "4eis"  # Use existing resource token
$RESOURCE_GROUP_NAME = "rg$RESOURCE_TOKEN"
$AKS_CLUSTER_NAME = "aks$RESOURCE_TOKEN"
$ACR_NAME = "acr$RESOURCE_TOKEN"
$STORAGE_ACCOUNT_NAME = "st$RESOURCE_TOKEN"
$KEYVAULT_NAME = "kv$RESOURCE_TOKEN"
$POSTGRESQL_SERVER_NAME = "psql$RESOURCE_TOKEN"
$SERVICEBUS_NAMESPACE = "sb$RESOURCE_TOKEN"
$USER_IDENTITY_NAME = "id$RESOURCE_TOKEN"
$DATABASE_NAME = "assetsdb"
$SERVICEBUS_QUEUE_NAME = "image-processing"
$BLOB_CONTAINER_NAME = "assets"

Write-Host "Starting deployment with resource token: $RESOURCE_TOKEN" -ForegroundColor Green
Write-Host "Location: $LOCATION" -ForegroundColor Green

# Function to check if Azure resource exists
function Test-AzureResource {
    param($Command)
    $ErrorActionPreference = "SilentlyContinue"
    $null = Invoke-Expression "$Command 2>$null"
    $exists = $LASTEXITCODE -eq 0
    $ErrorActionPreference = "Stop"
    return $exists
}

# Check if resource group exists
Write-Host "Checking resource group: $RESOURCE_GROUP_NAME" -ForegroundColor Cyan
if (Test-AzureResource "az group show --name $RESOURCE_GROUP_NAME --output none") {
    Write-Host "  - Resource group $RESOURCE_GROUP_NAME already exists" -ForegroundColor Yellow
} else {
    Write-Host "  - Creating resource group: $RESOURCE_GROUP_NAME" -ForegroundColor Gray
    az group create --name $RESOURCE_GROUP_NAME --location $LOCATION --output none
    if ($LASTEXITCODE -ne 0) { throw "Failed to create resource group" }
    Write-Host "  - Resource group created successfully" -ForegroundColor Green
}

# Create User-Assigned Managed Identity
Write-Host "Checking managed identity: $USER_IDENTITY_NAME" -ForegroundColor Cyan
if (Test-AzureResource "az identity show --name $USER_IDENTITY_NAME --resource-group $RESOURCE_GROUP_NAME --output none") {
    Write-Host "  - Managed identity $USER_IDENTITY_NAME already exists" -ForegroundColor Yellow
} else {
    Write-Host "  - Creating managed identity: $USER_IDENTITY_NAME" -ForegroundColor Gray
    az identity create --name $USER_IDENTITY_NAME --resource-group $RESOURCE_GROUP_NAME --location $LOCATION --output none
    if ($LASTEXITCODE -ne 0) { throw "Failed to create managed identity" }
    Write-Host "  - Managed identity created successfully" -ForegroundColor Green
}

# Get the managed identity details
$IDENTITY_ID = az identity show --name $USER_IDENTITY_NAME --resource-group $RESOURCE_GROUP_NAME --query id -o tsv
$IDENTITY_CLIENT_ID = az identity show --name $USER_IDENTITY_NAME --resource-group $RESOURCE_GROUP_NAME --query clientId -o tsv
$IDENTITY_OBJECT_ID = az identity show --name $USER_IDENTITY_NAME --resource-group $RESOURCE_GROUP_NAME --query principalId -o tsv

Write-Host "Managed Identity ID: $IDENTITY_ID"
Write-Host "Managed Identity Client ID: $IDENTITY_CLIENT_ID"

# Create Key Vault
Write-Host "Checking Key Vault: $KEYVAULT_NAME" -ForegroundColor Cyan
if (Test-AzureResource "az keyvault show --name $KEYVAULT_NAME --resource-group $RESOURCE_GROUP_NAME --output none") {
    Write-Host "  - Key Vault $KEYVAULT_NAME already exists" -ForegroundColor Yellow
} else {
    Write-Host "  - Creating Key Vault: $KEYVAULT_NAME" -ForegroundColor Gray
    az keyvault create --name $KEYVAULT_NAME --resource-group $RESOURCE_GROUP_NAME --location $LOCATION --enable-rbac-authorization --output none
    if ($LASTEXITCODE -ne 0) { throw "Failed to create Key Vault" }
    Write-Host "  - Key Vault created successfully" -ForegroundColor Green
    Start-Sleep -Seconds 10  # Wait for Key Vault to be ready
}

# Assign Key Vault roles
Write-Host "Assigning Key Vault roles..." -ForegroundColor Cyan
$subscriptionId = az account show --query id -o tsv
$currentUser = az account show --query user.name -o tsv

# Assign Key Vault Secrets Officer role to current user (for storing secrets)
$ErrorActionPreference = "Continue"
Write-Host "  - Assigning Key Vault Secrets Officer role to current user: $currentUser" -ForegroundColor Gray
az role assignment create --assignee $currentUser --role "Key Vault Secrets Officer" --scope "/subscriptions/$subscriptionId/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.KeyVault/vaults/$KEYVAULT_NAME"

# Assign Key Vault Secrets User role to managed identity (for reading secrets)
Write-Host "  - Assigning Key Vault Secrets User role to managed identity" -ForegroundColor Gray
az role assignment create --assignee $IDENTITY_OBJECT_ID --role "Key Vault Secrets User" --scope "/subscriptions/$subscriptionId/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.KeyVault/vaults/$KEYVAULT_NAME"
$ErrorActionPreference = "Stop"

# Wait for role assignments to propagate
Write-Host "Waiting for role assignments to propagate..." -ForegroundColor Gray
Start-Sleep -Seconds 30

# Create Storage Account
if (Test-AzureResource "az storage account show --name $STORAGE_ACCOUNT_NAME --resource-group $RESOURCE_GROUP_NAME --output none") {
    Write-Host "Storage account $STORAGE_ACCOUNT_NAME already exists" -ForegroundColor Yellow
} else {
    Write-Host "Creating storage account: $STORAGE_ACCOUNT_NAME" -ForegroundColor Cyan
    az storage account create `
        --name $STORAGE_ACCOUNT_NAME `
        --resource-group $RESOURCE_GROUP_NAME `
        --location $LOCATION `
        --sku Standard_LRS `
        --kind StorageV2 `
        --allow-shared-key-access false `
        --allow-blob-public-access false
    if ($LASTEXITCODE -ne 0) { throw "Failed to create storage account" }
}

# Assign Storage Blob Data Contributor role to managed identity
Write-Host "Assigning Storage Blob Data Contributor role to managed identity" -ForegroundColor Cyan
$ErrorActionPreference = "Continue"
az role assignment create --assignee $IDENTITY_OBJECT_ID --role "Storage Blob Data Contributor" --scope "/subscriptions/$subscriptionId/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT_NAME"
$ErrorActionPreference = "Stop"
Start-Sleep -Seconds 15  # Wait for role assignment to propagate

# Create blob container
if (Test-AzureResource "az storage container show --name $BLOB_CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME --auth-mode login --output none") {
    Write-Host "Blob container $BLOB_CONTAINER_NAME already exists" -ForegroundColor Yellow
} else {
    Write-Host "Creating blob container: $BLOB_CONTAINER_NAME" -ForegroundColor Cyan
    az storage container create --name $BLOB_CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME --auth-mode login
    if ($LASTEXITCODE -ne 0) { throw "Failed to create blob container" }
}

# Create PostgreSQL Flexible Server
if (Test-AzureResource "az postgres flexible-server show --name $POSTGRESQL_SERVER_NAME --resource-group $RESOURCE_GROUP_NAME --output none") {
    Write-Host "PostgreSQL flexible server $POSTGRESQL_SERVER_NAME already exists" -ForegroundColor Yellow
} else {
    Write-Host "Creating PostgreSQL flexible server: $POSTGRESQL_SERVER_NAME" -ForegroundColor Cyan
    az postgres flexible-server create `
        --name $POSTGRESQL_SERVER_NAME `
        --resource-group $RESOURCE_GROUP_NAME `
        --location $LOCATION `
        --admin-user pgadmin `
        --admin-password "TempPassword123!" `
        --sku-name Standard_B1ms `
        --tier Burstable `
        --storage-size 32 `
        --version 14 `
        --microsoft-entra-auth Enabled `
        --yes
    if ($LASTEXITCODE -ne 0) { throw "Failed to create PostgreSQL server" }
}

# Configure PostgreSQL firewall rules
Write-Host "Configuring PostgreSQL firewall rules" -ForegroundColor Cyan
$ErrorActionPreference = "Continue"
# Create firewall rule to allow Azure services
if (-not (Test-AzureResource "az postgres flexible-server firewall-rule show --name allow-azure-services --server-name $POSTGRESQL_SERVER_NAME --resource-group $RESOURCE_GROUP_NAME --output none")) {
    Write-Host "  - Creating firewall rule to allow Azure services" -ForegroundColor Gray
    az postgres flexible-server firewall-rule create --name $POSTGRESQL_SERVER_NAME --rule-name allow-azure-services --resource-group $RESOURCE_GROUP_NAME --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0
} else {
    Write-Host "  - Firewall rule 'allow-azure-services' already exists" -ForegroundColor Yellow
}
$ErrorActionPreference = "Stop"

# Create database
if (Test-AzureResource "az postgres flexible-server db show --server-name $POSTGRESQL_SERVER_NAME --resource-group $RESOURCE_GROUP_NAME --database-name $DATABASE_NAME --output none") {
    Write-Host "Database $DATABASE_NAME already exists" -ForegroundColor Yellow
} else {
    Write-Host "Creating database: $DATABASE_NAME" -ForegroundColor Cyan
    az postgres flexible-server db create --server-name $POSTGRESQL_SERVER_NAME --resource-group $RESOURCE_GROUP_NAME --database-name $DATABASE_NAME
    if ($LASTEXITCODE -ne 0) { throw "Failed to create database" }
}

# Add managed identity as Azure AD admin for PostgreSQL (required for Azure AD authentication)
Write-Host "Setting up Azure AD admin for PostgreSQL" -ForegroundColor Cyan
$ErrorActionPreference = "Continue"
if (-not (Test-AzureResource "az postgres flexible-server ad-admin show --resource-group $RESOURCE_GROUP_NAME --server-name $POSTGRESQL_SERVER_NAME --output none")) {
    Write-Host "  - Adding managed identity as Azure AD admin" -ForegroundColor Gray
    az postgres flexible-server ad-admin create --resource-group $RESOURCE_GROUP_NAME --server-name $POSTGRESQL_SERVER_NAME --display-name $USER_IDENTITY_NAME --object-id $IDENTITY_OBJECT_ID --type ServicePrincipal
} else {
    Write-Host "  - Azure AD admin already configured" -ForegroundColor Yellow
}
$ErrorActionPreference = "Stop"

# Create database user for managed identity and grant privileges
Write-Host "Creating database user for managed identity" -ForegroundColor Cyan
$connectionString = "host=$POSTGRESQL_SERVER_NAME.postgres.database.azure.com port=5432 dbname=$DATABASE_NAME user=pgadmin password=TempPassword123! sslmode=require"

# Create SQL commands to add managed identity user and grant privileges
$sqlCommands = @"
CREATE USER "$USER_IDENTITY_NAME" WITH LOGIN;
GRANT ALL PRIVILEGES ON DATABASE $DATABASE_NAME TO "$USER_IDENTITY_NAME";
GRANT ALL PRIVILEGES ON SCHEMA public TO "$USER_IDENTITY_NAME";
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO "$USER_IDENTITY_NAME";
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO "$USER_IDENTITY_NAME";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO "$USER_IDENTITY_NAME";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO "$USER_IDENTITY_NAME";
"@

# Store SQL commands in a file for later execution
$sqlFilePath = "$PSScriptRoot\setup-postgres-user.sql"
$sqlCommands | Out-File -FilePath $sqlFilePath -Encoding UTF8
Write-Host "Database user creation commands saved to: $sqlFilePath" -ForegroundColor Gray
Write-Host "Execute these commands manually using: psql or Azure Cloud Shell" -ForegroundColor Gray

# Create Service Bus namespace
if (Test-AzureResource "az servicebus namespace show --name $SERVICEBUS_NAMESPACE --resource-group $RESOURCE_GROUP_NAME --output none") {
    Write-Host "Service Bus namespace $SERVICEBUS_NAMESPACE already exists" -ForegroundColor Yellow
} else {
    Write-Host "Creating Service Bus namespace: $SERVICEBUS_NAMESPACE" -ForegroundColor Cyan
    az servicebus namespace create --name $SERVICEBUS_NAMESPACE --resource-group $RESOURCE_GROUP_NAME --location $LOCATION --sku Standard
    if ($LASTEXITCODE -ne 0) { throw "Failed to create Service Bus namespace" }
}

# Create Service Bus queue
if (Test-AzureResource "az servicebus queue show --name $SERVICEBUS_QUEUE_NAME --namespace-name $SERVICEBUS_NAMESPACE --resource-group $RESOURCE_GROUP_NAME --output none") {
    Write-Host "Service Bus queue $SERVICEBUS_QUEUE_NAME already exists" -ForegroundColor Yellow
} else {
    Write-Host "Creating Service Bus queue: $SERVICEBUS_QUEUE_NAME" -ForegroundColor Cyan
    az servicebus queue create --name $SERVICEBUS_QUEUE_NAME --namespace-name $SERVICEBUS_NAMESPACE --resource-group $RESOURCE_GROUP_NAME
    if ($LASTEXITCODE -ne 0) { throw "Failed to create Service Bus queue" }
}

# Assign Service Bus Data Owner role to managed identity
Write-Host "Assigning Service Bus Data Owner role to managed identity" -ForegroundColor Cyan
$ErrorActionPreference = "Continue"
az role assignment create --assignee $IDENTITY_OBJECT_ID --role "Azure Service Bus Data Owner" --scope "/subscriptions/$subscriptionId/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.ServiceBus/namespaces/$SERVICEBUS_NAMESPACE"
$ErrorActionPreference = "Stop"

# Create Container Registry
if (Test-AzureResource "az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP_NAME --output none") {
    Write-Host "Azure Container Registry $ACR_NAME already exists" -ForegroundColor Yellow
} else {
    Write-Host "Creating Azure Container Registry: $ACR_NAME" -ForegroundColor Cyan
    az acr create --name $ACR_NAME --resource-group $RESOURCE_GROUP_NAME --location $LOCATION --sku Basic --admin-enabled false
    if ($LASTEXITCODE -ne 0) { throw "Failed to create Container Registry" }
}

# Assign AcrPull role to managed identity
Write-Host "Assigning AcrPull role to managed identity" -ForegroundColor Cyan
$ErrorActionPreference = "Continue"
az role assignment create --assignee $IDENTITY_OBJECT_ID --role "AcrPull" --scope "/subscriptions/$subscriptionId/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.ContainerRegistry/registries/$ACR_NAME"
$ErrorActionPreference = "Stop"

# Get available AKS versions and select a stable one
Write-Host "Getting available AKS versions..."
$AKS_VERSION = (az aks get-versions --location $LOCATION --query "values[?isPreview==null].version" -o tsv | Select-Object -First 1)
Write-Host "Selected AKS version: $AKS_VERSION"

# Create AKS cluster
if (Test-AzureResource "az aks show --name $AKS_CLUSTER_NAME --resource-group $RESOURCE_GROUP_NAME --output none") {
    Write-Host "AKS cluster $AKS_CLUSTER_NAME already exists" -ForegroundColor Yellow
} else {
    Write-Host "Creating AKS cluster: $AKS_CLUSTER_NAME (this may take 10-15 minutes)" -ForegroundColor Cyan
    az aks create `
        --name $AKS_CLUSTER_NAME `
        --resource-group $RESOURCE_GROUP_NAME `
        --location $LOCATION `
        --kubernetes-version $AKS_VERSION `
        --node-count 2 `
        --node-vm-size Standard_D2s_v3 `
        --enable-oidc-issuer `
        --enable-workload-identity `
        --assign-identity $IDENTITY_ID `
        --generate-ssh-keys
    if ($LASTEXITCODE -ne 0) { throw "Failed to create AKS cluster" }
}

# Attach ACR to AKS cluster
Write-Host "Attaching ACR to AKS cluster" -ForegroundColor Cyan
az aks update --name $AKS_CLUSTER_NAME --resource-group $RESOURCE_GROUP_NAME --attach-acr $ACR_NAME
if ($LASTEXITCODE -ne 0) { throw "Failed to attach ACR to AKS cluster" }

# Get AKS credentials
Write-Host "Getting AKS credentials" -ForegroundColor Cyan
az aks get-credentials --name $AKS_CLUSTER_NAME --resource-group $RESOURCE_GROUP_NAME --overwrite-existing
if ($LASTEXITCODE -ne 0) { throw "Failed to get AKS credentials" }

# Get OIDC issuer URL for workload identity
$OIDC_ISSUER_URL = az aks show --name $AKS_CLUSTER_NAME --resource-group $RESOURCE_GROUP_NAME --query "oidcIssuerProfile.issuerUrl" -o tsv
Write-Host "OIDC Issuer URL: $OIDC_ISSUER_URL"

# Store configuration values in Key Vault
Write-Host "Storing configuration values in Key Vault" -ForegroundColor Cyan
$ErrorActionPreference = "Continue"

# Retry logic for Key Vault secrets (role assignments might need time to propagate)
$maxRetries = 3
$retryCount = 0
$secretsStored = $false

while ($retryCount -lt $maxRetries -and -not $secretsStored) {
    try {
        Write-Host "  - Attempting to store secrets (attempt $($retryCount + 1)/$maxRetries)..." -ForegroundColor Gray
        
        az keyvault secret set --vault-name $KEYVAULT_NAME --name "AZURE-STORAGE-ACCOUNT-NAME" --value $STORAGE_ACCOUNT_NAME --output none
        az keyvault secret set --vault-name $KEYVAULT_NAME --name "AZURE-STORAGE-BLOB-CONTAINER-NAME" --value $BLOB_CONTAINER_NAME --output none
        az keyvault secret set --vault-name $KEYVAULT_NAME --name "AZURE-CLIENT-ID" --value $IDENTITY_CLIENT_ID --output none
        az keyvault secret set --vault-name $KEYVAULT_NAME --name "AZURE-SERVICEBUS-NAMESPACE" --value "$SERVICEBUS_NAMESPACE.servicebus.windows.net" --output none
        az keyvault secret set --vault-name $KEYVAULT_NAME --name "POSTGRESQL-SERVER-NAME" --value $POSTGRESQL_SERVER_NAME --output none
        az keyvault secret set --vault-name $KEYVAULT_NAME --name "DATABASE-NAME" --value $DATABASE_NAME --output none
        
        # Store PostgreSQL connection string for managed identity access
        $postgresConnectionString = "jdbc:postgresql://$POSTGRESQL_SERVER_NAME.postgres.database.azure.com:5432/$DATABASE_NAME?sslmode=require"
        az keyvault secret set --vault-name $KEYVAULT_NAME --name "POSTGRESQL-CONNECTION-STRING" --value $postgresConnectionString --output none
        
        # Store traditional connection string with admin credentials (for initial setup)
        $postgresAdminConnectionString = "jdbc:postgresql://$POSTGRESQL_SERVER_NAME.postgres.database.azure.com:5432/$DATABASE_NAME?sslmode=require&user=pgadmin&password=TempPassword123!"
        az keyvault secret set --vault-name $KEYVAULT_NAME --name "POSTGRESQL-ADMIN-CONNECTION-STRING" --value $postgresAdminConnectionString --output none
        
        $secretsStored = $true
        Write-Host "  - Successfully stored all secrets in Key Vault" -ForegroundColor Green
    }
    catch {
        $retryCount++
        if ($retryCount -lt $maxRetries) {
            Write-Host "  - Failed to store secrets, retrying in 30 seconds..." -ForegroundColor Yellow
            Start-Sleep -Seconds 30
        } else {
            Write-Host "  - Failed to store secrets after $maxRetries attempts. You may need to run this section manually." -ForegroundColor Red
            Write-Host "  - Make sure you have Key Vault Secrets Officer role assigned." -ForegroundColor Red
        }
    }
}

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "=================================================="
Write-Host "DEPLOYMENT COMPLETED SUCCESSFULLY!"
Write-Host "=================================================="
Write-Host "Resource Group: $RESOURCE_GROUP_NAME"
Write-Host "AKS Cluster: $AKS_CLUSTER_NAME"
Write-Host "Container Registry: $ACR_NAME"
Write-Host "Storage Account: $STORAGE_ACCOUNT_NAME"
Write-Host "PostgreSQL Server: $POSTGRESQL_SERVER_NAME"
Write-Host "Service Bus Namespace: $SERVICEBUS_NAMESPACE"
Write-Host "Key Vault: $KEYVAULT_NAME"
Write-Host "Managed Identity: $USER_IDENTITY_NAME"
Write-Host "Client ID: $IDENTITY_CLIENT_ID"
Write-Host "OIDC Issuer URL: $OIDC_ISSUER_URL"
Write-Host ""
Write-Host "Next steps:"
Write-Host "1. Configure workload identity for your Kubernetes service accounts"
Write-Host "2. Build and push your Docker images to ACR"
Write-Host "3. Deploy your applications to AKS"
Write-Host "=================================================="