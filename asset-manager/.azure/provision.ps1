# PowerShell script for provisioning Azure resources
param(
    [string]$Location = "northeurope",
    [string]$ResourceToken = "",
    [string]$DatabaseAdminUser = "pgadmin",
    [string]$DatabaseAdminPassword = "TempPassword123!",
    [string]$DatabaseName = "assetsdb",
    [string]$ServiceBusQueueName = "image-processing",
    [string]$BlobContainerName = "assets"
)

$ErrorActionPreference = "Stop"

# Generate random resource token if not provided
if (-not $ResourceToken) {
    $ResourceToken = (-join ((65..90) + (97..122) + (48..57) | Get-Random -Count 5 | ForEach-Object {[char]$_})).ToLower()
    Write-Host "Generated resource token: $ResourceToken" -ForegroundColor Green
}

# Validate resource token (must be 5 characters, alphanumeric)
if ($ResourceToken.Length -ne 5 -or $ResourceToken -notmatch '^[a-z0-9]+$') {
    throw "Resource token must be exactly 5 alphanumeric characters (lowercase)"
}

# Configuration - following naming convention: {resourcePrefix}{resourceToken}{instance}
$RESOURCE_GROUP_NAME = "rg$ResourceToken"
$AKS_CLUSTER_NAME = "aks$ResourceToken"
$ACR_NAME = "acr$ResourceToken"
$STORAGE_ACCOUNT_NAME = "st$ResourceToken"
$KEYVAULT_NAME = "kv$ResourceToken" 
$POSTGRESQL_SERVER_NAME = "psql$ResourceToken"
$SERVICEBUS_NAMESPACE = "sb$ResourceToken"
$USER_IDENTITY_NAME = "id$ResourceToken"

Write-Host "Starting deployment with resource token: $ResourceToken" -ForegroundColor Green
Write-Host "Location: $Location" -ForegroundColor Green

# Function to check if Azure resource exists using output length
function Test-AzureResource {
    param(
        [string]$Command,
        [string]$ResourceName = ""
    )
    
    $output = & cmd /c "$Command --output tsv 2>nul"
    $exists = ($output -and $output.Length -gt 0)
    
    if ($exists) {
        if ($ResourceName) {
            Write-Host "  - Resource '$ResourceName' already exists" -ForegroundColor Yellow
        }
        return $true
    } else {
        if ($ResourceName) {
            Write-Host "  - Resource '$ResourceName' does not exist, will create" -ForegroundColor Gray
        }
        return $false
    }
}

# Check if resource group exists
Write-Host "Checking resource group: $RESOURCE_GROUP_NAME" -ForegroundColor Cyan
if (-not (Test-AzureResource "az group show --name $RESOURCE_GROUP_NAME" $RESOURCE_GROUP_NAME)) {
    Write-Host "  - Creating resource group: $RESOURCE_GROUP_NAME" -ForegroundColor Gray
    az group create --name $RESOURCE_GROUP_NAME --location $Location --output none
    if ($LASTEXITCODE -ne 0) { throw "Failed to create resource group" }
    Write-Host "  - Resource group created successfully" -ForegroundColor Green
}

# Create User-Assigned Managed Identity
Write-Host "Checking managed identity: $USER_IDENTITY_NAME" -ForegroundColor Cyan
if (-not (Test-AzureResource "az identity show --name $USER_IDENTITY_NAME --resource-group $RESOURCE_GROUP_NAME" $USER_IDENTITY_NAME)) {
    Write-Host "  - Creating managed identity: $USER_IDENTITY_NAME" -ForegroundColor Gray
    az identity create --name $USER_IDENTITY_NAME --resource-group $RESOURCE_GROUP_NAME --location $Location --output none
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
if (-not (Test-AzureResource "az keyvault show --name $KEYVAULT_NAME --resource-group $RESOURCE_GROUP_NAME" $KEYVAULT_NAME)) {
    Write-Host "  - Creating Key Vault: $KEYVAULT_NAME" -ForegroundColor Gray
    az keyvault create --name $KEYVAULT_NAME --resource-group $RESOURCE_GROUP_NAME --location $Location --enable-rbac-authorization --default-action Allow --bypass AzureServices --output none
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
Write-Host "Checking storage account: $STORAGE_ACCOUNT_NAME" -ForegroundColor Cyan
if (-not (Test-AzureResource "az storage account show --name $STORAGE_ACCOUNT_NAME --resource-group $RESOURCE_GROUP_NAME" $STORAGE_ACCOUNT_NAME)) {
    Write-Host "  - Creating storage account: $STORAGE_ACCOUNT_NAME" -ForegroundColor Gray
    az storage account create `
        --name $STORAGE_ACCOUNT_NAME `
        --resource-group $RESOURCE_GROUP_NAME `
        --location $Location `
        --sku Standard_LRS `
        --kind StorageV2 `
        --allow-shared-key-access false `
        --allow-blob-public-access false `
        --output none
    if ($LASTEXITCODE -ne 0) { throw "Failed to create storage account" }
    Write-Host "  - Storage account created successfully" -ForegroundColor Green
}

# Assign Storage Blob Data Contributor role to managed identity
Write-Host "Assigning Storage Blob Data Contributor role to managed identity" -ForegroundColor Cyan
try {
    az role assignment create --assignee $IDENTITY_OBJECT_ID --role "Storage Blob Data Contributor" --scope "/subscriptions/$subscriptionId/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT_NAME" --output none
    Write-Host "  - Storage role assignment completed" -ForegroundColor Green
}
catch {
    Write-Host "  - Warning: Storage role assignment may have failed or already exists" -ForegroundColor Yellow
}
Start-Sleep -Seconds 15  # Wait for role assignment to propagate

# Create blob container
Write-Host "Checking blob container: $BlobContainerName" -ForegroundColor Cyan
if (-not (Test-AzureResource "az storage container show --name $BlobContainerName --account-name $STORAGE_ACCOUNT_NAME --auth-mode login" $BlobContainerName)) {
    Write-Host "  - Creating blob container: $BlobContainerName" -ForegroundColor Gray
    az storage container create --name $BlobContainerName --account-name $STORAGE_ACCOUNT_NAME --auth-mode login --output none
    if ($LASTEXITCODE -ne 0) { throw "Failed to create blob container" }
    Write-Host "  - Blob container created successfully" -ForegroundColor Green
}

# Create PostgreSQL Flexible Server
Write-Host "Checking PostgreSQL flexible server: $POSTGRESQL_SERVER_NAME" -ForegroundColor Cyan
if (-not (Test-AzureResource "az postgres flexible-server show --name $POSTGRESQL_SERVER_NAME --resource-group $RESOURCE_GROUP_NAME" $POSTGRESQL_SERVER_NAME)) {
    Write-Host "  - Creating PostgreSQL flexible server: $POSTGRESQL_SERVER_NAME" -ForegroundColor Gray
    az postgres flexible-server create `
        --name $POSTGRESQL_SERVER_NAME `
        --resource-group $RESOURCE_GROUP_NAME `
        --location $Location `
        --admin-user $DatabaseAdminUser `
        --admin-password $DatabaseAdminPassword `
        --sku-name Standard_B1ms `
        --tier Burstable `
        --storage-size 32 `
        --version 14 `
        --microsoft-entra-auth Enabled `
        --yes `
        --output none
    if ($LASTEXITCODE -ne 0) { throw "Failed to create PostgreSQL server" }
    Write-Host "  - PostgreSQL server created successfully" -ForegroundColor Green
}

# Configure PostgreSQL firewall rules
Write-Host "Configuring PostgreSQL firewall rules" -ForegroundColor Cyan
try {
    # Create firewall rule to allow Azure services
    if (-not (Test-AzureResource "az postgres flexible-server firewall-rule show --rule-name allow-azure-services --name $POSTGRESQL_SERVER_NAME --resource-group $RESOURCE_GROUP_NAME" "Firewall rule 'allow-azure-services'")) {
        Write-Host "  - Creating firewall rule to allow Azure services" -ForegroundColor Gray
        az postgres flexible-server firewall-rule create --name $POSTGRESQL_SERVER_NAME --rule-name allow-azure-services --resource-group $RESOURCE_GROUP_NAME --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0 --output none
        if ($LASTEXITCODE -ne 0) { throw "Failed to create firewall rule" }
        Write-Host "  - Firewall rule created successfully" -ForegroundColor Green
    }
}
catch {
    Write-Host "  - Warning: Could not configure firewall rule. This might be expected if already exists." -ForegroundColor Yellow
}

# Create database
Write-Host "Checking database: $DatabaseName" -ForegroundColor Cyan
if (-not (Test-AzureResource "az postgres flexible-server db show --server-name $POSTGRESQL_SERVER_NAME --resource-group $RESOURCE_GROUP_NAME --database-name $DatabaseName" $DatabaseName)) {
    Write-Host "  - Creating database: $DatabaseName" -ForegroundColor Gray
    az postgres flexible-server db create --server-name $POSTGRESQL_SERVER_NAME --resource-group $RESOURCE_GROUP_NAME --database-name $DatabaseName --output none
    if ($LASTEXITCODE -ne 0) { throw "Failed to create database" }
    Write-Host "  - Database created successfully" -ForegroundColor Green
}

# Add managed identity as Azure AD admin for PostgreSQL (required for Azure AD authentication)
Write-Host "Setting up Azure AD admin for PostgreSQL" -ForegroundColor Cyan
try {
    if (-not (Test-AzureResource "az postgres flexible-server ad-admin show --resource-group $RESOURCE_GROUP_NAME --server-name $POSTGRESQL_SERVER_NAME" "Azure AD admin")) {
        Write-Host "  - Adding managed identity as Azure AD admin" -ForegroundColor Gray
        az postgres flexible-server ad-admin create --resource-group $RESOURCE_GROUP_NAME --server-name $POSTGRESQL_SERVER_NAME --display-name $USER_IDENTITY_NAME --object-id $IDENTITY_OBJECT_ID --type ServicePrincipal --output none
        if ($LASTEXITCODE -ne 0) { throw "Failed to create Azure AD admin" }
        Write-Host "  - Azure AD admin created successfully" -ForegroundColor Green
    }
}
catch {
    Write-Host "  - Warning: Could not configure Azure AD admin. This might be expected if already exists." -ForegroundColor Yellow
}

# Create database user for managed identity and grant privileges
Write-Host "Creating database user for managed identity" -ForegroundColor Cyan
$connectionString = "host=$POSTGRESQL_SERVER_NAME.postgres.database.azure.com port=5432 dbname=$DatabaseName user=$DatabaseAdminUser password=$DatabaseAdminPassword sslmode=require"

# Create SQL commands to add managed identity user and grant privileges
$sqlCommands = @"
CREATE USER "$USER_IDENTITY_NAME" WITH LOGIN;
GRANT ALL PRIVILEGES ON DATABASE $DatabaseName TO "$USER_IDENTITY_NAME";
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
Write-Host "Execute these commands after provisioning using: psql or Azure Cloud Shell" -ForegroundColor Gray

# Create Service Bus namespace
Write-Host "Checking Service Bus namespace: $SERVICEBUS_NAMESPACE" -ForegroundColor Cyan
if (-not (Test-AzureResource "az servicebus namespace show --name $SERVICEBUS_NAMESPACE --resource-group $RESOURCE_GROUP_NAME" $SERVICEBUS_NAMESPACE)) {
    Write-Host "  - Creating Service Bus namespace: $SERVICEBUS_NAMESPACE" -ForegroundColor Gray
    az servicebus namespace create --name $SERVICEBUS_NAMESPACE --resource-group $RESOURCE_GROUP_NAME --location $Location --sku Standard --output none
    if ($LASTEXITCODE -ne 0) { throw "Failed to create Service Bus namespace" }
    Write-Host "  - Service Bus namespace created successfully" -ForegroundColor Green
}

# Create Service Bus queue
Write-Host "Checking Service Bus queue: $ServiceBusQueueName" -ForegroundColor Cyan
if (-not (Test-AzureResource "az servicebus queue show --name $ServiceBusQueueName --namespace-name $SERVICEBUS_NAMESPACE --resource-group $RESOURCE_GROUP_NAME" $ServiceBusQueueName)) {
    Write-Host "  - Creating Service Bus queue: $ServiceBusQueueName" -ForegroundColor Gray
    az servicebus queue create --name $ServiceBusQueueName --namespace-name $SERVICEBUS_NAMESPACE --resource-group $RESOURCE_GROUP_NAME --output none
    if ($LASTEXITCODE -ne 0) { throw "Failed to create Service Bus queue" }
    Write-Host "  - Service Bus queue created successfully" -ForegroundColor Green
}

# Assign Service Bus Data Owner role to managed identity
Write-Host "Assigning Service Bus Data Owner role to managed identity" -ForegroundColor Cyan
try {
    az role assignment create --assignee $IDENTITY_OBJECT_ID --role "Azure Service Bus Data Owner" --scope "/subscriptions/$subscriptionId/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.ServiceBus/namespaces/$SERVICEBUS_NAMESPACE" --output none
    Write-Host "  - Service Bus role assignment completed" -ForegroundColor Green
}
catch {
    Write-Host "  - Warning: Service Bus role assignment may have failed or already exists" -ForegroundColor Yellow
}

# Create Container Registry
Write-Host "Checking Azure Container Registry: $ACR_NAME" -ForegroundColor Cyan
if (-not (Test-AzureResource "az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP_NAME" $ACR_NAME)) {
    Write-Host "  - Creating Azure Container Registry: $ACR_NAME" -ForegroundColor Gray
    az acr create --name $ACR_NAME --resource-group $RESOURCE_GROUP_NAME --location $Location --sku Basic --admin-enabled false --output none
    if ($LASTEXITCODE -ne 0) { throw "Failed to create Container Registry" }
    Write-Host "  - Container Registry created successfully" -ForegroundColor Green
}

# Assign AcrPull role to managed identity
Write-Host "Assigning AcrPull role to managed identity" -ForegroundColor Cyan
try {
    az role assignment create --assignee $IDENTITY_OBJECT_ID --role "AcrPull" --scope "/subscriptions/$subscriptionId/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.ContainerRegistry/registries/$ACR_NAME" --output none
    Write-Host "  - ACR role assignment completed" -ForegroundColor Green
}
catch {
    Write-Host "  - Warning: ACR role assignment may have failed or already exists" -ForegroundColor Yellow
}

# Get available AKS versions and select a stable one
Write-Host "Getting available AKS versions..." -ForegroundColor Cyan
$AKS_VERSION = (az aks get-versions --location $Location --query "values[?isPreview==null].version" -o tsv | Select-Object -First 1)
Write-Host "Selected AKS version: $AKS_VERSION" -ForegroundColor Gray

# Create AKS cluster
Write-Host "Checking AKS cluster: $AKS_CLUSTER_NAME" -ForegroundColor Cyan
if (-not (Test-AzureResource "az aks show --name $AKS_CLUSTER_NAME --resource-group $RESOURCE_GROUP_NAME" $AKS_CLUSTER_NAME)) {
    Write-Host "  - Creating AKS cluster: $AKS_CLUSTER_NAME (this may take 10-15 minutes)" -ForegroundColor Gray
    az aks create `
        --name $AKS_CLUSTER_NAME `
        --resource-group $RESOURCE_GROUP_NAME `
        --location $Location `
        --kubernetes-version $AKS_VERSION `
        --node-count 2 `
        --node-vm-size Standard_D2s_v3 `
        --enable-oidc-issuer `
        --enable-workload-identity `
        --assign-identity $IDENTITY_ID `
        --generate-ssh-keys `
        --output none
    if ($LASTEXITCODE -ne 0) { throw "Failed to create AKS cluster" }
    Write-Host "  - AKS cluster created successfully" -ForegroundColor Green
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

# Retry logic for Key Vault secrets (role assignments might need time to propagate)
$maxRetries = 3
$retryCount = 0
$secretsStored = $false

while ($retryCount -lt $maxRetries -and -not $secretsStored) {
    try {
        Write-Host "  - Attempting to store secrets (attempt $($retryCount + 1)/$maxRetries)..." -ForegroundColor Gray
        
        az keyvault secret set --vault-name $KEYVAULT_NAME --name "AZURE-STORAGE-ACCOUNT-NAME" --value $STORAGE_ACCOUNT_NAME --output none
        az keyvault secret set --vault-name $KEYVAULT_NAME --name "AZURE-STORAGE-BLOB-CONTAINER-NAME" --value $BlobContainerName --output none
        az keyvault secret set --vault-name $KEYVAULT_NAME --name "AZURE-CLIENT-ID" --value $IDENTITY_CLIENT_ID --output none
        az keyvault secret set --vault-name $KEYVAULT_NAME --name "AZURE-SERVICEBUS-NAMESPACE" --value "$SERVICEBUS_NAMESPACE.servicebus.windows.net" --output none
        az keyvault secret set --vault-name $KEYVAULT_NAME --name "POSTGRESQL-SERVER-NAME" --value $POSTGRESQL_SERVER_NAME --output none
        az keyvault secret set --vault-name $KEYVAULT_NAME --name "DATABASE-NAME" --value $DatabaseName --output none
        
        # Store PostgreSQL connection string for managed identity access
        $postgresConnectionString = "jdbc:postgresql://$POSTGRESQL_SERVER_NAME.postgres.database.azure.com:5432/$DatabaseName?sslmode=require"
        az keyvault secret set --vault-name $KEYVAULT_NAME --name "POSTGRESQL-CONNECTION-STRING" --value $postgresConnectionString --output none
        
        # Store traditional connection string with admin credentials (for initial setup)
        $postgresAdminConnectionString = "jdbc:postgresql://$POSTGRESQL_SERVER_NAME.postgres.database.azure.com:5432/$DatabaseName?sslmode=require&user=$DatabaseAdminUser&password=$DatabaseAdminPassword"
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

Write-Host ""
Write-Host "=================================================="
Write-Host "DEPLOYMENT COMPLETED SUCCESSFULLY!"
Write-Host "=================================================="
Write-Host "Resource Token: $ResourceToken" -ForegroundColor Yellow
Write-Host "Location: $Location" -ForegroundColor Yellow
Write-Host ""
Write-Host "Created Resources:" -ForegroundColor Green
Write-Host "  Resource Group: $RESOURCE_GROUP_NAME"
Write-Host "  AKS Cluster: $AKS_CLUSTER_NAME"
Write-Host "  Container Registry: $ACR_NAME"
Write-Host "  Storage Account: $STORAGE_ACCOUNT_NAME"
Write-Host "  PostgreSQL Server: $POSTGRESQL_SERVER_NAME"
Write-Host "  Service Bus Namespace: $SERVICEBUS_NAMESPACE"
Write-Host "  Key Vault: $KEYVAULT_NAME"
Write-Host "  Managed Identity: $USER_IDENTITY_NAME"
Write-Host ""
Write-Host "Configuration:" -ForegroundColor Green
Write-Host "  Client ID: $IDENTITY_CLIENT_ID"
Write-Host "  OIDC Issuer URL: $OIDC_ISSUER_URL"
Write-Host "  Database: $DatabaseName"
Write-Host "  Service Bus Queue: $ServiceBusQueueName"
Write-Host "  Blob Container: $BlobContainerName"
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Execute SQL commands in setup-postgres-user.sql to create database user"
Write-Host "2. Configure workload identity for your Kubernetes service accounts"
Write-Host "3. Build and push your Docker images to ACR"
Write-Host "4. Deploy your applications to AKS"
Write-Host ""
Write-Host "To rerun with same token: .\provision.ps1 -ResourceToken '$ResourceToken'" -ForegroundColor Yellow
Write-Host "=================================================="