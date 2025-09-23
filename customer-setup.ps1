#!/usr/bin/env pwsh
# Customer Setup Script for Defender for Containers Simulation
# This script helps customers quickly configure their AKS cluster details

param(
    [switch]$Interactive,
    [string]$SubscriptionId,
    [string]$ResourceGroup,
    [string]$ClusterName
)

Write-Host "🛡️  Microsoft Defender for Containers - Attack Simulation Setup" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host ""

# Function to validate Azure CLI
function Test-AzureCLI {
    try {
        $azVersion = az --version 2>$null | Select-Object -First 1
        if ($azVersion) {
            Write-Host "✅ Azure CLI found: $($azVersion.Split()[2])" -ForegroundColor Green
            return $true
        }
    }
    catch {
        Write-Host "❌ Azure CLI not found. Please install Azure CLI first." -ForegroundColor Red
        Write-Host "   Download from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli" -ForegroundColor Yellow
        return $false
    }
    return $false
}

# Function to get cluster info
function Get-ClusterInfo {
    Write-Host "📋 Available AKS clusters in your subscription:" -ForegroundColor Yellow
    Write-Host ""
    
    try {
        az aks list --output table
        Write-Host ""
    }
    catch {
        Write-Host "❌ Failed to list AKS clusters. Make sure you're logged in with 'az login'" -ForegroundColor Red
        return $false
    }
    return $true
}

# Validate Azure CLI
if (-not (Test-AzureCLI)) {
    exit 1
}

# Check if user is logged in
try {
    $account = az account show --output json | ConvertFrom-Json
    Write-Host "✅ Logged in as: $($account.user.name)" -ForegroundColor Green
    Write-Host "✅ Current subscription: $($account.name)" -ForegroundColor Green
    Write-Host ""
}
catch {
    Write-Host "❌ Not logged in to Azure. Please run 'az login' first." -ForegroundColor Red
    exit 1
}

# If parameters provided, use them
if ($SubscriptionId -and $ResourceGroup -and $ClusterName) {
    Write-Host "🎯 Using provided cluster details..." -ForegroundColor Yellow
}
else {
    # Interactive mode or show available clusters
    if (-not (Get-ClusterInfo)) {
        exit 1
    }
    
    if (-not $SubscriptionId) {
        $SubscriptionId = Read-Host "Enter your Azure Subscription ID"
    }
    if (-not $ResourceGroup) {
        $ResourceGroup = Read-Host "Enter your Resource Group name"
    }
    if (-not $ClusterName) {
        $ClusterName = Read-Host "Enter your AKS Cluster name"
    }
}

# Validate inputs
if (-not $SubscriptionId -or -not $ResourceGroup -or -not $ClusterName) {
    Write-Host "❌ All cluster details are required!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🔧 Configuring environment..." -ForegroundColor Yellow

# Set environment variables
$env:AZURE_SUBSCRIPTION_ID = $SubscriptionId
$env:AZURE_RESOURCE_GROUP = $ResourceGroup
$env:AZURE_CLUSTER_NAME = $ClusterName

Write-Host "✅ Environment variables set:" -ForegroundColor Green
Write-Host "   AZURE_SUBSCRIPTION_ID = $SubscriptionId" -ForegroundColor Gray
Write-Host "   AZURE_RESOURCE_GROUP = $ResourceGroup" -ForegroundColor Gray
Write-Host "   AZURE_CLUSTER_NAME = $ClusterName" -ForegroundColor Gray
Write-Host ""

# Test cluster connectivity
Write-Host "🔌 Testing cluster connectivity..." -ForegroundColor Yellow
try {
    az aks get-credentials --subscription $SubscriptionId --resource-group $ResourceGroup --name $ClusterName --overwrite-existing --only-show-errors
    
    # Test kubectl access
    $nodes = kubectl get nodes --no-headers 2>$null
    if ($nodes) {
        $nodeCount = ($nodes | Measure-Object).Count
        Write-Host "✅ Successfully connected to cluster with $nodeCount nodes" -ForegroundColor Green
    }
    else {
        Write-Host "⚠️  kubectl connection issue, but credentials were retrieved" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "❌ Failed to connect to cluster. Please verify cluster details." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🛡️  Checking Defender for Containers..." -ForegroundColor Yellow
try {
    $defenderPods = kubectl get pods -n kube-system -l app=microsoft-defender-collector-ds --no-headers 2>$null
    if ($defenderPods) {
        Write-Host "✅ Defender for Containers sensor detected" -ForegroundColor Green
    }
    else {
        Write-Host "⚠️  Defender for Containers sensor not found!" -ForegroundColor Red
        Write-Host "   Please ensure Defender for Containers is enabled on this cluster" -ForegroundColor Yellow
        Write-Host "   Guide: https://docs.microsoft.com/en-us/azure/defender-for-cloud/defender-for-containers-enable" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "⚠️  Could not check Defender status" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🎯 Setup complete! You can now run the simulation:" -ForegroundColor Green
Write-Host ""
Write-Host "   # Quick start with interactive menu:" -ForegroundColor Cyan
Write-Host "   python enhanced_simulation.py" -ForegroundColor White
Write-Host ""
Write-Host "   # Run specific scenarios:" -ForegroundColor Cyan  
Write-Host "   python enhanced_simulation.py --scenarios recon,secrets" -ForegroundColor White
Write-Host ""
Write-Host "   # Run all scenarios:" -ForegroundColor Cyan
Write-Host "   python enhanced_simulation.py --scenarios all" -ForegroundColor White
Write-Host ""
Write-Host "ℹ️  Environment variables are set for this session only." -ForegroundColor Blue
Write-Host "   To persist them, add them to your PowerShell profile or set them in system environment variables." -ForegroundColor Blue
Write-Host ""