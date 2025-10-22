@echo off
setlocal enabledelayedexpansion

rem Azure Deployment Script for Assets Manager
rem Execute with: .\scripts\deploy-to-azure.cmd -ResourceGroupName "my-rg" -Location "eastus" -Prefix "myapp"

rem Default parameters
set ResourceGroupName=assets-manager-rg
set Location=eastus2
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
set PostgresServerName=%Prefix%db
set PostgresDBName=assets_manager
set ServiceBusNamespace=%Prefix%-servicebus
set QueueName=image-processing
set StorageAccountName=%Prefix%storage
set ContainerName=images
set WebAppName=%Prefix%-web
set WorkerAppName=%Prefix%-worker
set EnvironmentName=%Prefix%-env
set AcrName=%Prefix%registry
set IdentityName=%Prefix%-identity
set ServiceConnectorName=postgres_connection

echo ===========================================
echo Deploying Assets Manager to Azure
echo ===========================================
echo Resource Group: %ResourceGroupName%
echo Location: %Location%
echo Resources prefix: %Prefix%
echo ===========================================

rem Check prerequisites
echo Checking prerequisites...
where az >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Azure CLI not found. Please install it: https://docs.microsoft.com/cli/azure/install-azure-cli
    exit /b 1
)
echo Prerequisites satisfied.

echo Please ensure you are logged into Azure before running this script.
echo You can log in by running 'az login' separately if needed.

rem Get current subscription ID
for /f "tokens=*" %%i in ('az account show --query id -o tsv') do (
  set SubscriptionId=%%i
)
if not defined SubscriptionId (
    echo Failed to get Subscription ID. Exiting.
    exit /b 1
)
echo Using Subscription ID: !SubscriptionId!

rem Register Microsoft.DBforPostgreSQL provider and wait until completion
echo Registering Microsoft.DBforPostgreSQL provider...
cmd /c az provider register --namespace Microsoft.DBforPostgreSQL --wait
if %ERRORLEVEL% neq 0 (
    echo Failed to register Microsoft.DBforPostgreSQL provider. Exiting.
    exit /b 1
)
echo Microsoft.DBforPostgreSQL provider registration completed.

rem Add Azure CLI extensions
echo Adding/upgrading Azure CLI extensions...
cmd /c az extension add --name containerapp --upgrade
cmd /c az extension add --name rdbms-connect --upgrade
cmd /c az extension add --name serviceconnector-passwordless --upgrade
echo Azure CLI extensions added/upgraded.

rem Create resource group
echo Creating resource group...
cmd /c az group create --name %ResourceGroupName% --location %Location%
if %ERRORLEVEL% neq 0 (
    echo Failed to create resource group. Exiting.
    exit /b 1
)
echo Resource group created.

rem Create Azure PostgreSQL server with Microsoft Entra authentication enabled and database
echo Creating Azure PostgreSQL server with Microsoft Entra authentication and database...
cmd /c az postgres flexible-server create ^
  --resource-group %ResourceGroupName% ^
  --name %PostgresServerName% ^
  --location %Location% ^
  --database-name %PostgresDBName% ^
  --public-access 0.0.0.0 ^
  --sku-name Standard_B1ms ^
  --tier Burstable ^
  --active-directory-auth Enabled
if %ERRORLEVEL% neq 0 (
    echo Failed to create PostgreSQL server and database. Exiting.
    exit /b 1
)
echo PostgreSQL server and database created.

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

rem Create Azure Container Registry
echo Creating Azure Container Registry...
cmd /c az acr create --resource-group %ResourceGroupName% --name %AcrName% --sku Basic
if %ERRORLEVEL% neq 0 (
    echo Failed to create Azure Container Registry. Exiting.
    exit /b 1
)
echo ACR created.
for /f "tokens=*" %%i in ('az acr show --name %AcrName% --resource-group %ResourceGroupName% --query loginServer -o tsv') do (
  set AcrLoginServer=%%i
)
if not defined AcrLoginServer (
    echo Failed to get ACR login server. Exiting.
    exit /b 1
)
echo Using ACR login server: !AcrLoginServer!

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

rem Create managed identity for web and worker apps
echo Creating managed identity...
cmd /c az identity create ^
  --resource-group %ResourceGroupName% ^
  --name "%IdentityName%"
if %ERRORLEVEL% neq 0 (
    echo Failed to create managed identity. Exiting.
    exit /b 1
)
echo Managed identity created.

rem Get identity details
echo Getting identity details...
for /f "tokens=*" %%i in ('az identity show --resource-group %ResourceGroupName% --name "%IdentityName%" --query id -o tsv') do (
  set IdentityId=%%i
)
if not defined IdentityId (
    echo Failed to get Identity ID. Exiting.
    exit /b 1
)

for /f "tokens=*" %%i in ('az identity show --resource-group %ResourceGroupName% --name "%IdentityName%" --query clientId -o tsv') do (
  set IdentityClientId=%%i
)
if not defined IdentityClientId (
    echo Failed to get Identity Client ID. Exiting.
    exit /b 1
)

for /f "tokens=*" %%i in ('az identity show --resource-group %ResourceGroupName% --name "%IdentityName%" --query principalId -o tsv') do (
  set IdentityPrincipalId=%%i
)
if not defined IdentityPrincipalId (
    echo Failed to get Identity Principal ID. Exiting.
    exit /b 1
)
echo Identity details retrieved.

rem Assign roles to the managed identity - use the user identity principal ID
echo Assigning roles to managed identity...
rem Storage Blob Data Contributor role
cmd /c az role assignment create ^
  --assignee-object-id !IdentityPrincipalId! ^
  --assignee-principal-type ServicePrincipal ^
  --role "Storage Blob Data Contributor" ^
  --scope "/subscriptions/!SubscriptionId!/resourceGroups/%ResourceGroupName%/providers/Microsoft.Storage/storageAccounts/%StorageAccountName%"
if %ERRORLEVEL% neq 0 (
    echo Failed to assign Storage Blob Data Contributor role to identity. Exiting.
    exit /b 1
)
echo Storage Blob Data Contributor role assigned.

rem Service Bus Data Owner role (needed for resolving 401 issue in web and context.abandon() and context.complete() in ServiceBusListener of worker)
cmd /c az role assignment create ^
  --assignee-object-id !IdentityPrincipalId! ^
  --assignee-principal-type ServicePrincipal ^
  --role "Azure Service Bus Data Owner" ^
  --scope "/subscriptions/!SubscriptionId!/resourceGroups/%ResourceGroupName%/providers/Microsoft.ServiceBus/namespaces/%ServiceBusNamespace%"
if %ERRORLEVEL% neq 0 (
    echo Failed to assign Service Bus Data Owner role to identity. Exiting.
    exit /b 1
)
echo Service Bus Data Owner role assigned.

rem AcrPull role for accessing ACR
cmd /c az role assignment create ^
  --assignee-object-id !IdentityPrincipalId! ^
  --assignee-principal-type ServicePrincipal ^
  --role "acrpull" ^
  --scope "/subscriptions/!SubscriptionId!/resourceGroups/%ResourceGroupName%/providers/Microsoft.ContainerRegistry/registries/%AcrName%"
if %ERRORLEVEL% neq 0 (
    echo Failed to assign AcrPull role to identity. Exiting.
    exit /b 1
)
echo AcrPull role assigned.

rem Create Dockerfiles for both modules
echo Creating Dockerfile for web module...
(
echo FROM eclipse-temurin:21-jre-alpine
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
echo FROM eclipse-temurin:21-jre-alpine
echo WORKDIR /app
echo COPY target/*.jar app.jar
echo ENTRYPOINT ["java", "-jar", "app.jar"]
) > worker\Dockerfile
if %ERRORLEVEL% neq 0 (
    echo Failed to create Worker module Dockerfile. Exiting.
    exit /b 1
)
echo Worker module Dockerfile created.

rem Package and build Docker images
echo Building web and worker modules...
call .\mvnw clean package -DskipTests
if %ERRORLEVEL% neq 0 (
    echo Failed to build web and worker modules. Exiting.
    exit /b 1
)
echo Web and worker modules built.

rem Web module
echo Building web Docker image in ACR...
cmd /c az acr build -t %WebAppName%:latest -r %AcrName% --file .\web\Dockerfile .\web
if %ERRORLEVEL% neq 0 (
    echo Failed to build Web Docker image in ACR. Exiting.
    exit /b 1
)
echo Web Docker image built and pushed to ACR.
rem Worker module
echo Building worker Docker image in ACR...
cmd /c az acr build -t %WorkerAppName%:latest -r %AcrName% --file .\worker\Dockerfile .\worker
if %ERRORLEVEL% neq 0 (
    echo Failed to build Worker Docker image in ACR. Exiting.
    exit /b 1
)
echo Worker Docker image built and pushed to ACR.

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
  --user-assigned !IdentityId! ^
  --registry-identity !IdentityId! ^
  --min-replicas 1 ^
  --max-replicas 3 ^
  --env-vars "AZURE_CLIENT_ID=!IdentityClientId!" ^
              "AZURE_STORAGE_ACCOUNT_NAME=%StorageAccountName%" ^
              "AZURE_STORAGE_BLOB_CONTAINER_NAME=%ContainerName%" ^
              "AZURE_SERVICEBUS_NAMESPACE=%ServiceBusNamespace%"
if %ERRORLEVEL% neq 0 (
    echo Failed to create Web Container App. Exiting.
    exit /b 1
)
echo Web Container App created.

rem Use Service Connector to connect apps to PostgreSQL with user-assigned managed identity
echo Creating Service Connector between Web app and PostgreSQL...
cmd /c az containerapp connection create postgres-flexible ^
  --client-type springBoot ^
  --resource-group %ResourceGroupName% ^
  --name %WebAppName% ^
  --container %WebAppName% ^
  --target-resource-group %ResourceGroupName% ^
  --server %PostgresServerName% ^
  --database %PostgresDBName% ^
  --user-identity client-id=%IdentityClientId% subs-id=!SubscriptionId! ^
  --connection %ServiceConnectorName% ^
  --customized-keys spring.datasource.username=SPRING_DATASOURCE_USERNAME ^
                    spring.datasource.url=SPRING_DATASOURCE_URL ^
                    spring.cloud.azure.credential.managed-identity-enabled=SPRING_CLOUD_AZURE_CREDENTIAL_MANAGEDIDENTITYENABLED ^
                    spring.datasource.azure.passwordless-enabled=SPRING_DATASOURCE_AZURE_PASSWORDLESSENABLED ^
                    spring.cloud.azure.credential.client-id=SPRING_CLOUD_AZURE_CREDENTIAL_CLIENTID ^
  --yes
if %ERRORLEVEL% neq 0 (
    echo Failed to create Service Connector between Web app and PostgreSQL. Exiting.
    exit /b 1
)
echo Web app Service Connector to PostgreSQL created.

REM # Retrieve values for env vars SPRING_DATASOURCE_USERNAME & SPRING_DATASOURCE_URL injected by service connector
cmd /c az containerapp connection show ^
  --connection %ServiceConnectorName% ^
  --resource-group %ResourceGroupName% ^
  --name %WebAppName% ^
  --query "configurations[?name=='SPRING_DATASOURCE_USERNAME'].value" -o tsv > %ServiceConnectorName%-output.txt
set /p SPRING_DATASOURCE_USERNAME=<%ServiceConnectorName%-output.txt
del %ServiceConnectorName%-output.txt
echo Using SPRING_DATASOURCE_USERNAME: !SPRING_DATASOURCE_USERNAME!
if not defined SPRING_DATASOURCE_USERNAME (
    echo Failed to get SPRING_DATASOURCE_USERNAME. Exiting.
    exit /b 1
)
cmd /c az containerapp connection show ^
  --connection %ServiceConnectorName% ^
  --resource-group %ResourceGroupName% ^
  --name %WebAppName% ^
  --query "configurations[?name=='SPRING_DATASOURCE_URL'].value" -o tsv > %ServiceConnectorName%-output.txt
set /p SPRING_DATASOURCE_URL=<%ServiceConnectorName%-output.txt
del %ServiceConnectorName%-output.txt
echo Using SPRING_DATASOURCE_URL: !SPRING_DATASOURCE_URL!
if not defined SPRING_DATASOURCE_URL (
    echo Failed to get SPRING_DATASOURCE_URL. Exiting.
    exit /b 1
)

rem Create Container Apps with user-assigned managed identity and database connection env vars for worker module
echo Creating Container App for worker module...
cmd /c az containerapp create ^
  --resource-group %ResourceGroupName% ^
  --name %WorkerAppName% ^
  --environment %EnvironmentName% ^
  --image !AcrLoginServer!/%WorkerAppName%:latest ^
  --registry-server !AcrLoginServer! ^
  --user-assigned !IdentityId! ^
  --registry-identity !IdentityId! ^
  --min-replicas 1 ^
  --max-replicas 3 ^
  --env-vars "AZURE_CLIENT_ID=!IdentityClientId!" ^
              "AZURE_STORAGE_ACCOUNT_NAME=%StorageAccountName%" ^
              "AZURE_STORAGE_BLOB_CONTAINER_NAME=%ContainerName%" ^
              "AZURE_SERVICEBUS_NAMESPACE=%ServiceBusNamespace%" ^
              "SPRING_DATASOURCE_USERNAME=!SPRING_DATASOURCE_USERNAME!" ^
              "SPRING_DATASOURCE_URL=!SPRING_DATASOURCE_URL!"
if %ERRORLEVEL% neq 0 (
    echo Failed to create Worker Container App. Exiting.
    exit /b 1
)
echo Worker Container App created.

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