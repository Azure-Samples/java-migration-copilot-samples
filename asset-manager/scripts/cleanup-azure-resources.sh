#!/bin/bash

# Azure Resources Cleanup Script for Assets Manager
# Execute with: ./scripts/cleanup-azure-resources.sh -ResourceGroupName "my-rg"

# Default parameters
RESOURCE_GROUP_NAME="assets-manager-rg"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -ResourceGroupName)
      RESOURCE_GROUP_NAME="$2"
      shift
      shift
      ;;
    *)
      shift
      ;;
  esac
done

echo "==========================================="
echo "Cleanup Azure Resources for Assets Manager"
echo "==========================================="
echo "Resource Group to delete: $RESOURCE_GROUP_NAME"
echo "==========================================="
echo "WARNING: This script will delete the entire resource group and all resources within it."
echo "         This action cannot be undone."
echo "==========================================="

# Check prerequisites
echo "Checking Azure CLI installation..."
if ! command -v az &> /dev/null; then
  echo "Azure CLI not found. Please install it: https://docs.microsoft.com/cli/azure/install-azure-cli"
  exit 1
fi

# Check if resource group exists
echo "Checking if resource group exists..."
if ! az group show --name "$RESOURCE_GROUP_NAME" &> /dev/null; then
  echo "Resource group $RESOURCE_GROUP_NAME does not exist. Nothing to delete."
  exit 0
fi

echo "Resource group $RESOURCE_GROUP_NAME found."
echo "Deleting entire resource group..."
if ! az group delete --name "$RESOURCE_GROUP_NAME" --yes; then
  echo "Failed to delete resource group. Please check for errors."
  exit 1
fi

echo "==========================================="
echo "Resource group $RESOURCE_GROUP_NAME deletion completed."
echo "All resources within the group have been removed."
echo "Cleanup complete!"
echo "==========================================="