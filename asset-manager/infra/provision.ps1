<#
.SYNOPSIS
    Provisions Azure infrastructure for assets-manager using Terraform, then deploys to AKS.
.DESCRIPTION
    Steps:
      1. Validate Azure CLI login
      2. Fill in kubernetes_version and node_vm_size placeholders in main.tfvars.json
      3. terraform init → validate → apply
      4. Build and push Docker images to ACR
      5. Apply Kubernetes manifests
      6. Configure Service Connector (AKS → PostgreSQL passwordless)
      7. Verify deployment
.PARAMETER PostgresPassword
    Strong password for the PostgreSQL admin user. Required.
.EXAMPLE
    .\provision.ps1 -PostgresPassword "MyStr0ng!Password"
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$PostgresPassword
)

$ErrorActionPreference = "Stop"
$ScriptDir = $PSScriptRoot
$WorkspaceRoot = Split-Path $ScriptDir -Parent
$K8sDir = Join-Path $WorkspaceRoot "k8s"
$TfvarsFile = Join-Path $ScriptDir "main.tfvars.json"

function Write-Step { param([string]$msg) Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Write-OK   { param([string]$msg) Write-Host "    OK: $msg" -ForegroundColor Green }
function Write-Warn { param([string]$msg) Write-Host "    WARN: $msg" -ForegroundColor Yellow }

# ────────────────────────────────────────────────
# Step 1 – Verify Azure CLI login
# ────────────────────────────────────────────────
Write-Step "Verifying Azure CLI login"
$account = az account show --query "{sub:id,name:name}" -o json 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Not logged in. Running interactive login..." -ForegroundColor Yellow
    az login --tenant "de9dfb27-7122-49ec-8260-826003e96b9e"
    if ($LASTEXITCODE -ne 0) { throw "az login failed" }
}
$accountObj = $account | ConvertFrom-Json
$SubscriptionId = $accountObj.sub
Write-OK "Subscription: $($accountObj.name) ($SubscriptionId)"

# ────────────────────────────────────────────────
# Step 2 – Resolve placeholders in main.tfvars.json
# ────────────────────────────────────────────────
Write-Step "Resolving Kubernetes version and VM SKU for region"
$tfvars = Get-Content $TfvarsFile | ConvertFrom-Json
$Location = $tfvars.location

# Get stable kubernetes version
$k8sVersion = az aks get-versions --location $Location `
    --query "values[?isDefault].version | [0]" -o tsv
if (-not $k8sVersion) {
    # Fallback: use latest non-preview version
    $k8sVersion = az aks get-versions --location $Location `
        --query "sort(values[?!isPreview].version) | [-1]" -o tsv
}
Write-OK "Kubernetes version: $k8sVersion"

# Verify Standard_D2s_v3 is available; if not, find an alternative 2-vCPU SKU
$vmSkuAvailable = az vm list-skus --location $Location --size Standard_D2s `
    --all --query "[?name=='Standard_D2s_v3'].name" -o tsv
$nodeVmSize = if ($vmSkuAvailable) { "Standard_D2s_v3" } else { "Standard_D2s_v5" }
Write-OK "Node VM size: $nodeVmSize"

# Update tfvars
$tfvars.kubernetes_version    = $k8sVersion
$tfvars.node_vm_size          = $nodeVmSize
$tfvars.postgres_admin_password = $PostgresPassword
$tfvars | ConvertTo-Json -Depth 5 | Set-Content $TfvarsFile
Write-OK "main.tfvars.json updated"

# ────────────────────────────────────────────────
# Step 3 – Terraform init → validate → apply
# ────────────────────────────────────────────────
Push-Location $ScriptDir
try {
    Write-Step "terraform init"
    terraform init
    if ($LASTEXITCODE -ne 0) { throw "terraform init failed" }

    Write-Step "terraform validate"
    terraform validate
    if ($LASTEXITCODE -ne 0) { throw "terraform validate failed" }

    Write-Step "terraform plan"
    terraform plan -var-file="main.tfvars.json" -out="tfplan"
    if ($LASTEXITCODE -ne 0) { throw "terraform plan failed" }

    Write-Step "terraform apply"
    terraform apply -auto-approve "tfplan"
    if ($LASTEXITCODE -ne 0) { throw "terraform apply failed" }

    Write-OK "Infrastructure provisioned successfully"

    # Capture outputs
    $tfOut = terraform output -json | ConvertFrom-Json
} finally {
    Pop-Location
}

$ResourceGroupName       = $tfOut.resource_group_name.value
$AksName                 = $tfOut.aks_name.value
$AksResourceId           = $tfOut.aks_resource_id.value
$AcrLoginServer          = $tfOut.acr_login_server.value
$AcrName                 = $tfOut.acr_name.value
$StorageAccountName      = $tfOut.storage_account_name.value
$BlobContainerName       = $tfOut.blob_container_name.value
$ServiceBusNamespace     = $tfOut.servicebus_namespace.value
$PostgresFqdn            = $tfOut.postgres_fqdn.value
$PostgresServerName      = $tfOut.postgres_server_name.value
$PostgresResourceId      = $tfOut.postgres_resource_id.value
$KeyVaultName            = $tfOut.key_vault_name.value
$WorkloadClientId        = $tfOut.workload_identity_client_id.value
$AksKvIdentityClientId   = $tfOut.aks_kv_identity_client_id.value
$TenantId                = $tfOut.tenant_id.value
$K8sNamespace            = $tfvars.web_namespace
$WebServiceAccount       = $tfvars.web_service_account
$WorkerServiceAccount    = $tfvars.worker_service_account

Write-OK "Outputs captured. Resource group: $ResourceGroupName"

# ────────────────────────────────────────────────
# Step 4 – Build and push Docker images to ACR
# ────────────────────────────────────────────────
Write-Step "Building and pushing Docker images to ACR: $AcrLoginServer"
az acr login --name $AcrName
if ($LASTEXITCODE -ne 0) { throw "az acr login failed" }

Push-Location $WorkspaceRoot
try {
    Write-Host "  Building assets-manager-web..." -ForegroundColor Gray
    docker build -f web/Dockerfile -t "${AcrLoginServer}/assets-manager-web:latest" .
    if ($LASTEXITCODE -ne 0) { throw "docker build web failed" }

    docker push "${AcrLoginServer}/assets-manager-web:latest"
    if ($LASTEXITCODE -ne 0) { throw "docker push web failed" }
    Write-OK "Web image pushed"

    Write-Host "  Building assets-manager-worker..." -ForegroundColor Gray
    docker build -f worker/Dockerfile -t "${AcrLoginServer}/assets-manager-worker:latest" .
    if ($LASTEXITCODE -ne 0) { throw "docker build worker failed" }

    docker push "${AcrLoginServer}/assets-manager-worker:latest"
    if ($LASTEXITCODE -ne 0) { throw "docker push worker failed" }
    Write-OK "Worker image pushed"
} finally {
    Pop-Location
}

# ────────────────────────────────────────────────
# Step 5 – Prepare and apply Kubernetes manifests
# ────────────────────────────────────────────────
Write-Step "Getting AKS credentials"
az aks get-credentials --name $AksName --resource-group $ResourceGroupName --overwrite-existing
if ($LASTEXITCODE -ne 0) { throw "Failed to get AKS credentials" }

# Generate SecretProviderClass manifest (dynamic values)
$secretProviderClass = @"
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: assets-manager-kv-secrets
  namespace: $K8sNamespace
spec:
  provider: azure
  parameters:
    usePodIdentity: "false"
    useVMManagedIdentity: "true"
    userAssignedIdentityID: "$AksKvIdentityClientId"
    keyvaultName: "$KeyVaultName"
    objects: |
      array:
        - |
          objectName: postgres-fqdn
          objectType: secret
        - |
          objectName: postgres-database
          objectType: secret
    tenantId: "$TenantId"
  secretObjects:
    - secretName: assets-manager-pg-secrets
      type: Opaque
      data:
        - objectName: postgres-fqdn
          key: POSTGRES_FQDN
        - objectName: postgres-database
          key: POSTGRES_DATABASE
"@

# Generate ConfigMap for non-secret config
$configMap = @"
apiVersion: v1
kind: ConfigMap
metadata:
  name: assets-manager-config
  namespace: $K8sNamespace
data:
  AZURE_STORAGE_ACCOUNT_NAME: "$StorageAccountName"
  AZURE_STORAGE_BLOB_CONTAINER_NAME: "$BlobContainerName"
  AZURE_CLIENT_ID: "$WorkloadClientId"
  AZURE_SERVICEBUS_NAMESPACE: "$ServiceBusNamespace"
"@

# Write generated manifests
if (-not (Test-Path $K8sDir)) { New-Item -ItemType Directory -Path $K8sDir | Out-Null }
$secretProviderClass | Set-Content (Join-Path $K8sDir "secret-provider-class.yaml")
$configMap           | Set-Content (Join-Path $K8sDir "configmap.yaml")

Write-Step "Applying Kubernetes manifests"

# 1. Namespace
kubectl apply -f (Join-Path $K8sDir "namespace.yaml")
if ($LASTEXITCODE -ne 0) { throw "Failed to apply namespace" }

# 2. Service accounts (for workload identity)
kubectl apply -f (Join-Path $K8sDir "service-accounts.yaml")
if ($LASTEXITCODE -ne 0) { throw "Failed to apply service accounts" }

# 3. ConfigMap and SecretProviderClass
kubectl apply -f (Join-Path $K8sDir "configmap.yaml")
kubectl apply -f (Join-Path $K8sDir "secret-provider-class.yaml")

# 4. Deployments (update image references first)
$webDeployFile    = Join-Path $K8sDir "web-deployment.yaml"
$workerDeployFile = Join-Path $K8sDir "worker-deployment.yaml"

(Get-Content $webDeployFile)    -replace 'ACR_LOGIN_SERVER', $AcrLoginServer | Set-Content $webDeployFile
(Get-Content $workerDeployFile) -replace 'ACR_LOGIN_SERVER', $AcrLoginServer | Set-Content $workerDeployFile

kubectl apply -f $webDeployFile
if ($LASTEXITCODE -ne 0) { throw "Failed to apply web deployment" }

kubectl apply -f $workerDeployFile
if ($LASTEXITCODE -ne 0) { throw "Failed to apply worker deployment" }

# 5. Service (LoadBalancer for web)
kubectl apply -f (Join-Path $K8sDir "web-service.yaml")
if ($LASTEXITCODE -ne 0) { throw "Failed to apply web service" }

Write-OK "Kubernetes manifests applied"

# ────────────────────────────────────────────────
# Step 6 – Service Connector: AKS → PostgreSQL (passwordless)
# ────────────────────────────────────────────────
Write-Step "Configuring Service Connector: AKS → PostgreSQL (passwordless)"
az extension add --name serviceconnector-passwordless --upgrade -y 2>$null

# Connect for web deployment
az aks connection create postgres-flexible `
    --connection "assetsmanager-web-pg" `
    --source-id $AksResourceId `
    --target-id "$PostgresResourceId/databases/$($tfvars.database_name)" `
    --workload-identity "client-id=$WorkloadClientId" "subs-id=$SubscriptionId" `
    --kube-namespace $K8sNamespace `
    --client-type springBoot `
    -y
if ($LASTEXITCODE -ne 0) { Write-Warn "Service Connector for web failed - check manually" }
else { Write-OK "Service Connector (web → postgres) configured" }

# Connect for worker deployment
az aks connection create postgres-flexible `
    --connection "assetsmanager-worker-pg" `
    --source-id $AksResourceId `
    --target-id "$PostgresResourceId/databases/$($tfvars.database_name)" `
    --workload-identity "client-id=$WorkloadClientId" "subs-id=$SubscriptionId" `
    --kube-namespace $K8sNamespace `
    --client-type springBoot `
    -y
if ($LASTEXITCODE -ne 0) { Write-Warn "Service Connector for worker failed - check manually" }
else { Write-OK "Service Connector (worker → postgres) configured" }

# ────────────────────────────────────────────────
# Step 7 – Verify deployment
# ────────────────────────────────────────────────
Write-Step "Verifying deployment (waiting up to 3 min for pods to be Ready)"
$timeout = 180
$start   = Get-Date
do {
    $pods = kubectl get pods -n $K8sNamespace --no-headers 2>$null
    $running = ($pods | Select-String "Running").Count
    $total   = ($pods | Measure-Object -Line).Lines
    Write-Host "    Pods running: $running / $total" -ForegroundColor Gray
    if ($running -ge $total -and $total -gt 0) { break }
    Start-Sleep -Seconds 10
} while (((Get-Date) - $start).TotalSeconds -lt $timeout)

kubectl get pods -n $K8sNamespace
kubectl get svc  -n $K8sNamespace

$webSvc = kubectl get svc assets-manager-web -n $K8sNamespace -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
if ($webSvc) {
    Write-OK "Web app available at: http://$webSvc"
} else {
    Write-Warn "External IP not yet assigned - run: kubectl get svc -n $K8sNamespace"
}

Write-Step "Deployment complete!"
Write-Host ""
Write-Host "  Resource Group : $ResourceGroupName"        -ForegroundColor White
Write-Host "  AKS Cluster    : $AksName"                  -ForegroundColor White
Write-Host "  ACR            : $AcrLoginServer"           -ForegroundColor White
Write-Host "  Storage Account: $StorageAccountName"       -ForegroundColor White
Write-Host "  Service Bus    : $ServiceBusNamespace"      -ForegroundColor White
Write-Host "  PostgreSQL     : $PostgresFqdn"             -ForegroundColor White
Write-Host "  Key Vault      : $KeyVaultName"             -ForegroundColor White
