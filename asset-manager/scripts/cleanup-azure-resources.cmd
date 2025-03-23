@echo off
setlocal enabledelayedexpansion

rem Azure Resources Cleanup Script for Assets Manager
rem Execute with: .\scripts\cleanup-azure-resources.cmd -ResourceGroupName "my-rg"

rem Default parameters
set ResourceGroupName=assets-manager-rg

rem Parse command line arguments
:parse_args
if "%~1"=="" goto :end_parse_args
if /i "%~1"=="-ResourceGroupName" (
    set ResourceGroupName=%~2
    shift
    shift
    goto :parse_args
)
shift
goto :parse_args
:end_parse_args

echo ===========================================
echo Cleanup Azure Resources for Assets Manager
echo ===========================================
echo Resource Group to delete: %ResourceGroupName%
echo ===========================================
echo WARNING: This script will delete the entire resource group and all resources within it.
echo          This action cannot be undone.
echo ===========================================

rem Check prerequisites
echo Checking Azure CLI installation...
where az >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Azure CLI not found. Please install it: https://docs.microsoft.com/cli/azure/install-azure-cli
    exit /b 1
)

rem Check if resource group exists
echo Checking if resource group exists...
cmd /c az group show --name %ResourceGroupName% >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Resource group %ResourceGroupName% does not exist. Nothing to delete.
    exit /b 0
)

echo Resource group %ResourceGroupName% found.
echo Deleting entire resource group...
cmd /c az group delete --name %ResourceGroupName% --yes
if %ERRORLEVEL% neq 0 (
    echo Failed to delete resource group. Please check for errors.
    exit /b 1
)

echo ===========================================
echo Resource group %ResourceGroupName% deletion completed.
echo All resources within the group have been removed.
echo Cleanup complete!
echo ===========================================