@echo off
setlocal enabledelayedexpansion

rem Azure Deployment Script for Assets Manager
rem Execute with: deploy-to-azure.cmd -ResourceGroupName "my-rg" -Location "eastus" -Prefix "myapp"

rem Default parameters
set ResourceGroupName=assets-manager-rg
set Location=eastus
set Prefix=assetsapp

rem Parse command line arguments
:parse_args
if "%~1"=="" goto :end_parse_args
if /i "%~1"=="-ResourceGroupName" (
    set ResourceGroupName=%~2
    shift
    shift
    goto :parse_args
)
if /i "%~1"=="-Location" (
    set Location=%~2
    shift
    shift
    goto :parse_args
)
if /i "%~1"=="-Prefix" (
    set Prefix=%~2
    shift
    shift
    goto :parse_args
)
shift
goto :parse_args
:end_parse_args

rem Define resource names
set ContainerName=images
rem Add timestamp suffix to PostgreSQL server name for uniqueness (format that complies with PostgreSQL naming restrictions)
set DATETIME=%date:~-4,4%%date:~-10,2%%date:~-7,2%%time:~0,2%%time:~3,2%%time:~6,2%
set DATETIME=%DATETIME: =0%
set DATETIME=%DATETIME::=0%
set DATETIME=%DATETIME:.=0%
set RandomSuffix=%RANDOM:~-4%
set PostgresServerName=%Prefix%db
set PostgresDBName=assets_manager
set PostgresAdmin=postgresadmin
set ServiceBusNamespace=%Prefix%-servicebus
set QueueName=image-processing
set StorageAccountName=%Prefix%storage
set WebAppName=%Prefix%-web
set WorkerAppName=%Prefix%-worker
set EnvironmentName=%Prefix%-env
set AcrName=%Prefix%registry
set WebServiceConnectorName=web_postgres
set WorkerServiceConnectorName=worker_postgres

echo ===========================================
echo Deploying Assets Manager to Azure
echo ===========================================
echo Resource Group: %ResourceGroupName%
echo Location: %Location%
echo Resources prefix: %Prefix%
echo PostgreSQL Server: %PostgresServerName%
echo ===========================================

rem Check prerequisites
echo Checking prerequisites...
where az >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Azure CLI not found. Please install it: https://docs.microsoft.com/cli/azure/install-azure-cli
    exit /b 1
)

where mvn >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Maven not found. Please install it: https://maven.apache.org/install.html
    exit /b 1
)

where docker >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Docker not found. Please install it: https://docs.docker.com/get-docker/
    exit /b 1
)

echo Please ensure you are logged into Azure before running this script.
echo You can log in by running 'az login' separately if needed.

rem Create resource group
echo Creating resource group...
cmd /c az group create --name %ResourceGroupName% --location %Location%
if %ERRORLEVEL% neq 0 (
    echo Failed to create resource group. Exiting.
    exit /b 1
)
echo Resource group created.

rem Get tenant ID for AAD configuration
for /f "tokens=*" %%i in ('az account show --query tenantId -o tsv') do (
  set TenantId=%%i
)
if not defined TenantId (
    echo Failed to get Tenant ID. Exiting.
    exit /b 1
)

rem Create Azure PostgreSQL server with Microsoft Entra authentication enabled early
echo Creating Azure PostgreSQL server with Microsoft Entra authentication...
set RANDOM_TIME=%TIME:~-5%
set RANDOM_TIME=%RANDOM_TIME:.=%
set randomPassword=Pstpwd01

cmd /c az postgres flexible-server create ^
  --resource-group %ResourceGroupName% ^
  --name %PostgresServerName% ^
  --location %Location% ^
  --admin-user %PostgresAdmin% ^
  --admin-password %randomPassword% ^
  --sku-name Standard_B1ms ^
  --tier Burstable ^
  --storage-size 32 ^
  --version 15 ^
  --yes
if %ERRORLEVEL% neq 0 (
    echo Failed to create PostgreSQL server. Exiting.
    exit /b 1
)
echo PostgreSQL server created.

rem Enable Microsoft Entra authentication
echo Enabling Microsoft Entra authentication...
cmd /c az postgres flexible-server update ^
  --resource-group %ResourceGroupName% ^
  --name %PostgresServerName% ^
  --set "authConfig.activeDirectoryAuth=enabled" ^
  --set "authConfig.tenantId=!TenantId!"
if %ERRORLEVEL% neq 0 (
    echo Failed to enable Microsoft Entra authentication. Exiting.
    exit /b 1
)
echo Microsoft Entra authentication enabled.

echo Creating PostgreSQL database...
cmd /c az postgres flexible-server db create ^
  --resource-group %ResourceGroupName% ^
  --server-name %PostgresServerName% ^
  --database-name %PostgresDBName%
if %ERRORLEVEL% neq 0 (
    echo Failed to create PostgreSQL database. Exiting.
    exit /b 1
)
echo PostgreSQL database created.

rem Allow Azure services to access PostgreSQL server
echo Configuring PostgreSQL firewall rules...
cmd /c az postgres flexible-server firewall-rule create ^
  --resource-group %ResourceGroupName% ^
  --name %PostgresServerName% ^
  --rule-name "AllowAzureServices" ^
  --start-ip-address 0.0.0.0 ^
  --end-ip-address 0.0.0.0
if %ERRORLEVEL% neq 0 (
    echo Failed to configure PostgreSQL firewall rules. Exiting.
    exit /b 1
)
echo PostgreSQL firewall rules configured.

rem Create managed identities first
echo Creating managed identities...
cmd /c az identity create ^
  --resource-group %ResourceGroupName% ^
  --name "%WebAppName%-identity"
if %ERRORLEVEL% neq 0 (
    echo Failed to create Web app managed identity. Exiting.
    exit /b 1
)
echo Web app managed identity created.

cmd /c az identity create ^
  --resource-group %ResourceGroupName% ^
  --name "%WorkerAppName%-identity"
if %ERRORLEVEL% neq 0 (
    echo Failed to create Worker app managed identity. Exiting.
    exit /b 1
)
echo Worker app managed identity created.

rem Get identity details early
echo Getting identity details...
for /f "tokens=*" %%i in ('az identity show --resource-group %ResourceGroupName% --name "%WebAppName%-identity" --query id -o tsv') do (
  set WebIdentityId=%%i
)
if not defined WebIdentityId (
    echo Failed to get Web Identity ID. Exiting.
    exit /b 1
)

for /f "tokens=*" %%i in ('az identity show --resource-group %ResourceGroupName% --name "%WebAppName%-identity" --query clientId -o tsv') do (
  set WebIdentityClientId=%%i
)
if not defined WebIdentityClientId (
    echo Failed to get Web Identity Client ID. Exiting.
    exit /b 1
)

for /f "tokens=*" %%i in ('az identity show --resource-group %ResourceGroupName% --name "%WebAppName%-identity" --query principalId -o tsv') do (
  set WebIdentityPrincipalId=%%i
)
if not defined WebIdentityPrincipalId (
    echo Failed to get Web Identity Principal ID. Exiting.
    exit /b 1
)

for /f "tokens=*" %%i in ('az identity show --resource-group %ResourceGroupName% --name "%WorkerAppName%-identity" --query id -o tsv') do (
  set WorkerIdentityId=%%i
)
if not defined WorkerIdentityId (
    echo Failed to get Worker Identity ID. Exiting.
    exit /b 1
)

for /f "tokens=*" %%i in ('az identity show --resource-group %ResourceGroupName% --name "%WorkerAppName%-identity" --query clientId -o tsv') do (
  set WorkerIdentityClientId=%%i
)
if not defined WorkerIdentityClientId (
    echo Failed to get Worker Identity Client ID. Exiting.
    exit /b 1
)

for /f "tokens=*" %%i in ('az identity show --resource-group %ResourceGroupName% --name "%WorkerAppName%-identity" --query principalId -o tsv') do (
  set WorkerIdentityPrincipalId=%%i
)
if not defined WorkerIdentityPrincipalId (
    echo Failed to get Worker Identity Principal ID. Exiting.
    exit /b 1
)
echo Identity details retrieved.

rem Create Azure Container Registry
echo Creating Azure Container Registry...
cmd /c az acr create --resource-group %ResourceGroupName% --name %AcrName% --sku Basic
if %ERRORLEVEL% neq 0 (
    echo Failed to create Azure Container Registry. Exiting.
    exit /b 1
)
echo ACR created.

cmd /c az acr login --name %AcrName%
if %ERRORLEVEL% neq 0 (
    echo Failed to log in to ACR. Exiting.
    exit /b 1
)
echo Logged in to ACR.

rem Create Azure Service Bus namespace and queue
echo Creating Azure Service Bus namespace...
cmd /c az servicebus namespace create ^
  --resource-group %ResourceGroupName% ^
  --name %ServiceBusNamespace% ^
  --location %Location% ^
  --sku Standard
if %ERRORLEVEL% neq 0 (
    echo Failed to create Service Bus namespace. Exiting.
    exit /b 1
)
echo Service Bus namespace created.

echo Creating Service Bus queue...
cmd /c az servicebus queue create ^
  --resource-group %ResourceGroupName% ^
  --namespace-name %ServiceBusNamespace% ^
  --name %QueueName%
if %ERRORLEVEL% neq 0 (
    echo Failed to create Service Bus queue. Exiting.
    exit /b 1
)
echo Service Bus queue created.

rem Create Azure Storage account and container
echo Creating Azure Storage account...
cmd /c az storage account create ^
  --resource-group %ResourceGroupName% ^
  --name %StorageAccountName% ^
  --location %Location% ^
  --sku Standard_LRS ^
  --kind StorageV2 ^
  --enable-hierarchical-namespace false ^
  --allow-blob-public-access true
if %ERRORLEVEL% neq 0 (
    echo Failed to create Storage account. Exiting.
    exit /b 1
)
echo Storage account created.

echo Creating Blob container...
for /f "tokens=*" %%i in ('az storage account keys list --resource-group %ResourceGroupName% --account-name %StorageAccountName% --query [0].value -o tsv') do (
  set StorageKey=%%i
)
if not defined StorageKey (
    echo Failed to get Storage account key. Exiting.
    exit /b 1
)

cmd /c az storage container create ^
  --name %ContainerName% ^
  --account-name %StorageAccountName% ^
  --account-key !StorageKey! ^
  --public-access container
if %ERRORLEVEL% neq 0 (
    echo Failed to create Blob container. Exiting.
    exit /b 1
)
echo Blob container created.

rem Create Container Apps environment
echo Creating Container Apps environment...
cmd /c az containerapp env create ^
  --resource-group %ResourceGroupName% ^
  --name %EnvironmentName% ^
  --location %Location%
if %ERRORLEVEL% neq 0 (
    echo Failed to create Container Apps environment. Exiting.
    exit /b 1
)
echo Container Apps environment created.

rem Get current subscription ID
for /f "tokens=*" %%i in ('az account show --query id -o tsv') do (
  set SubscriptionId=%%i
)
if not defined SubscriptionId (
    echo Failed to get Subscription ID. Exiting.
    exit /b 1
)
echo Using Subscription ID: !SubscriptionId!

rem Create Dockerfiles for both modules
echo Creating Dockerfile for web module...
(
echo FROM eclipse-temurin:17-jre-alpine
echo WORKDIR /app
echo COPY target/*.jar app.jar
echo EXPOSE 8080
echo ENTRYPOINT ["java", "-jar", "app.jar"]
) > web\Dockerfile
if %ERRORLEVEL% neq 0 (
    echo Failed to create Web module Dockerfile. Exiting.
    exit /b 1
)
echo Web module Dockerfile created.

echo Creating Dockerfile for worker module...
(
echo FROM eclipse-temurin:17-jre-alpine
echo WORKDIR /app
echo COPY target/*.jar app.jar
echo EXPOSE 8081
echo ENTRYPOINT ["java", "-jar", "app.jar"]
) > worker\Dockerfile
if %ERRORLEVEL% neq 0 (
    echo Failed to create Worker module Dockerfile. Exiting.
    exit /b 1
)
echo Worker module Dockerfile created.

rem Package and build Docker images
echo Building web module...
cd /d web
call ..\mvnw clean package -DskipTests
if %ERRORLEVEL% neq 0 (
    echo Failed to build Web module. Exiting.
    cd ..
    exit /b 1
)
cd ..
echo Web module built.

echo Building worker module...
cd /d worker
call ..\mvnw clean package -DskipTests
if %ERRORLEVEL% neq 0 (
    echo Failed to build Worker module. Exiting.
    cd ..
    exit /b 1
)
cd ..
echo Worker module built.

rem Build and push Docker images to ACR
echo Building and pushing Docker images to ACR...
for /f "tokens=*" %%i in ('az acr show --name %AcrName% --resource-group %ResourceGroupName% --query loginServer -o tsv') do (
  set AcrLoginServer=%%i
)
if not defined AcrLoginServer (
    echo Failed to get ACR login server. Exiting.
    exit /b 1
)
echo Using ACR login server: !AcrLoginServer!

rem Web module
echo Building web Docker image...
cd /d web
docker build -t !AcrLoginServer!/%WebAppName%:latest .
if %ERRORLEVEL% neq 0 (
    echo Failed to build Web Docker image. Exiting.
    cd ..
    exit /b 1
)

echo Pushing web Docker image to ACR...
docker push !AcrLoginServer!/%WebAppName%:latest
if %ERRORLEVEL% neq 0 (
    echo Failed to push Web Docker image to ACR. Exiting.
    cd ..
    exit /b 1
)
cd ..
echo Web Docker image pushed to ACR.

rem Worker module
echo Building worker Docker image...
cd /d worker
docker build -t !AcrLoginServer!/%WorkerAppName%:latest .
if %ERRORLEVEL% neq 0 (
    echo Failed to build Worker Docker image. Exiting.
    cd ..
    exit /b 1
)

echo Pushing worker Docker image to ACR...
docker push !AcrLoginServer!/%WorkerAppName%:latest
if %ERRORLEVEL% neq 0 (
    echo Failed to push Worker Docker image to ACR. Exiting.
    cd ..
    exit /b 1
)
cd ..
echo Worker Docker image pushed to ACR.

rem Create Container Apps with user-assigned managed identities
echo Creating Container App for web module...
cmd /c az containerapp create ^
  --resource-group %ResourceGroupName% ^
  --name %WebAppName% ^
  --environment %EnvironmentName% ^
  --image !AcrLoginServer!/%WebAppName%:latest ^
  --registry-server !AcrLoginServer! ^
  --target-port 8080 ^
  --ingress external ^
  --user-assigned !WebIdentityId! ^
  --registry-identity !WebIdentityId! ^
  --min-replicas 1 ^
  --max-replicas 3 ^
  --env-vars "AZURE_CLIENT_ID=!WebIdentityClientId!" ^
              "AZURE_STORAGE_ACCOUNT_NAME=%StorageAccountName%" ^
              "AZURE_STORAGE_BLOB_CONTAINER_NAME=%ContainerName%" ^
              "AZURE_SERVICEBUS_NAMESPACE=%ServiceBusNamespace%"
if %ERRORLEVEL% neq 0 (
    echo Failed to create Web Container App. Exiting.
    exit /b 1
)
echo Web Container App created.

echo Creating Container App for worker module...
cmd /c az containerapp create ^
  --resource-group %ResourceGroupName% ^
  --name %WorkerAppName% ^
  --environment %EnvironmentName% ^
  --image !AcrLoginServer!/%WorkerAppName%:latest ^
  --registry-server !AcrLoginServer! ^
  --target-port 8081 ^
  --ingress internal ^
  --user-assigned !WorkerIdentityId! ^
  --registry-identity !WorkerIdentityId! ^
  --min-replicas 1 ^
  --max-replicas 3 ^
  --env-vars "AZURE_CLIENT_ID=!WorkerIdentityClientId!" ^
              "AZURE_STORAGE_ACCOUNT_NAME=%StorageAccountName%" ^
              "AZURE_STORAGE_BLOB_CONTAINER_NAME=%ContainerName%" ^
              "AZURE_SERVICEBUS_NAMESPACE=%ServiceBusNamespace%"
if %ERRORLEVEL% neq 0 (
    echo Failed to create Worker Container App. Exiting.
    exit /b 1
)
echo Worker Container App created.

rem For user-assigned identities, we already have the identity details
echo Using previously retrieved managed identity details...

rem Set environment variables for the apps - update for user-assigned identity
echo Setting environment variables for Container Apps...
cmd /c az containerapp update ^
  --resource-group %ResourceGroupName% ^
  --name %WebAppName% ^
  --set-env-vars "AZURE_CLIENT_ID=!WebIdentityClientId!"
if %ERRORLEVEL% neq 0 (
    echo Failed to set environment variables for Web Container App.
    exit /b 1
)

cmd /c az containerapp update ^
  --resource-group %ResourceGroupName% ^
  --name %WorkerAppName% ^
  --set-env-vars "AZURE_CLIENT_ID=!WorkerIdentityClientId!"
if %ERRORLEVEL% neq 0 (
    echo Failed to set environment variables for Worker Container App.
    exit /b 1
)
echo Container App environment variables set.

rem Assign roles to the managed identities - use the user identity principal IDs
echo Assigning roles to managed identities...
rem Storage Blob Data Contributor role for both web and worker
cmd /c az role assignment create ^
  --assignee-object-id !WebIdentityPrincipalId! ^
  --assignee-principal-type ServicePrincipal ^
  --role "Storage Blob Data Contributor" ^
  --scope "/subscriptions/!SubscriptionId!/resourceGroups/%ResourceGroupName%/providers/Microsoft.Storage/storageAccounts/%StorageAccountName%"
if %ERRORLEVEL% neq 0 (
    echo Failed to assign Storage Blob Data Contributor role to Web app identity. Exiting.
    exit /b 1
)
echo Web app Storage Blob Data Contributor role assigned.

cmd /c az role assignment create ^
  --assignee-object-id !WorkerIdentityPrincipalId! ^
  --assignee-principal-type ServicePrincipal ^
  --role "Storage Blob Data Contributor" ^
  --scope "/subscriptions/!SubscriptionId!/resourceGroups/%ResourceGroupName%/providers/Microsoft.Storage/storageAccounts/%StorageAccountName%"
if %ERRORLEVEL% neq 0 (
    echo Failed to assign Storage Blob Data Contributor role to Worker app identity. Exiting.
    exit /b 1
)
echo Worker app Storage Blob Data Contributor role assigned.

rem Service Bus Data Sender role for web
cmd /c az role assignment create ^
  --assignee-object-id !WebIdentityPrincipalId! ^
  --assignee-principal-type ServicePrincipal ^
  --role "Azure Service Bus Data Sender" ^
  --scope "/subscriptions/!SubscriptionId!/resourceGroups/%ResourceGroupName%/providers/Microsoft.ServiceBus/namespaces/%ServiceBusNamespace%"
if %ERRORLEVEL% neq 0 (
    echo Failed to assign Service Bus Data Sender role to Web app identity. Exiting.
    exit /b 1
)
echo Web app Service Bus Data Sender role assigned.

rem Service Bus Data Receiver role for worker
cmd /c az role assignment create ^
  --assignee-object-id !WorkerIdentityPrincipalId! ^
  --assignee-principal-type ServicePrincipal ^
  --role "Azure Service Bus Data Receiver" ^
  --scope "/subscriptions/!SubscriptionId!/resourceGroups/%ResourceGroupName%/providers/Microsoft.ServiceBus/namespaces/%ServiceBusNamespace%"
if %ERRORLEVEL% neq 0 (
    echo Failed to assign Service Bus Data Receiver role to Worker app identity. Exiting.
    exit /b 1
)
echo Worker app Service Bus Data Receiver role assigned.

rem Service Bus Data Owner role for worker (needed for context.abandon() and context.complete() in ServiceBusListener)
cmd /c az role assignment create ^
  --assignee-object-id !WorkerIdentityPrincipalId! ^
  --assignee-principal-type ServicePrincipal ^
  --role "Azure Service Bus Data Owner" ^
  --scope "/subscriptions/!SubscriptionId!/resourceGroups/%ResourceGroupName%/providers/Microsoft.ServiceBus/namespaces/%ServiceBusNamespace%"
if %ERRORLEVEL% neq 0 (
    echo Failed to assign Service Bus Data Owner role to Worker app identity. Exiting.
    exit /b 1
)
echo Worker app Service Bus Data Owner role assigned.

rem Use Service Connector to connect apps to PostgreSQL with user-assigned managed identity
echo Creating Service Connector between Web app and PostgreSQL...
cmd /c az containerapp connection create postgres-flexible ^
  --client-type springboot ^
  --resource-group %ResourceGroupName% ^
  --name %WebAppName% ^
  --container %WebAppName% ^
  --target-resource-group %ResourceGroupName% ^
  --server %PostgresServerName% ^
  --database %PostgresDBName% ^
  --user-identity client-id=%WebIdentityClientId% subs-id=!SubscriptionId! ^
  --connection %WebServiceConnectorName%
if %ERRORLEVEL% neq 0 (
    echo Failed to create Service Connector between Web app and PostgreSQL. Exiting.
    exit /b 1
)
echo Web app Service Connector to PostgreSQL created.

echo Creating Service Connector between Worker app and PostgreSQL...
cmd /c az containerapp connection create postgres-flexible ^
  --client-type springboot ^
  --resource-group %ResourceGroupName% ^
  --name %WorkerAppName% ^
  --container %WorkerAppName% ^
  --target-resource-group %ResourceGroupName% ^
  --server %PostgresServerName% ^
  --database %PostgresDBName% ^
  --user-identity client-id=%WorkerIdentityClientId% subs-id=!SubscriptionId! ^
  --connection %WorkerServiceConnectorName%
if %ERRORLEVEL% neq 0 (
    echo Failed to create Service Connector between Worker app and PostgreSQL. Exiting.
    exit /b 1
)
echo Worker app Service Connector to PostgreSQL created.

rem Get the web app URL
for /f "tokens=*" %%i in ('az containerapp show --resource-group %ResourceGroupName% --name %WebAppName% --query properties.configuration.ingress.fqdn -o tsv') do (
  set WebAppUrl=%%i
)
if not defined WebAppUrl (
    echo Failed to get Web Application URL, but deployment is complete.
)

echo ===========================================
echo Deployment complete!
echo ===========================================
echo Resource Group: %ResourceGroupName%
if defined WebAppUrl (
    echo Web Application URL: https://!WebAppUrl!
)
echo Storage Account: %StorageAccountName%
echo Service Bus Namespace: %ServiceBusNamespace%
echo PostgreSQL Server: %PostgresServerName%
echo ===========================================