# Create federated identity credential for workload identity
# During Copilot-assisted deployment, the command should be executed automatically in Copilot Chat panel after k8s manifests are generated and before deploying to AKS
# This script is a substitute for Copilot command execution.
# Usage: .\configure-workload-identity.ps1 -ResourceToken <token>

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceToken
)

Write-Host "Creating federated identity credential with resource token: $ResourceToken" -ForegroundColor Cyan

az identity federated-credential create `
    --name 'assets-manager-federated-identity' `
    --identity-name "id$ResourceToken" `
    --resource-group "rg$ResourceToken" `
    --issuer $(az aks show --name "aks$ResourceToken" --resource-group "rg$ResourceToken" --query 'oidcIssuerProfile.issuerUrl' -o tsv) `
    --subject 'system:serviceaccount:assets-manager:assets-manager-sa'

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Federated identity credential created successfully" -ForegroundColor Green
} else {
    Write-Error "Failed to create federated identity credential"
    exit 1
}