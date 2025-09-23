#!/usr/bin/env pwsh
# Enhanced Defender for Containers - Setup Script for Windows
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

Write-Host "=== Enhanced Defender for Containers Setup ===" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Check prerequisites
Write-Host "🔍 Checking prerequisites..." -ForegroundColor Yellow

# Check Python
Write-Host "Checking Python installation..." -NoNewline
try {
    $pythonVersion = python --version 2>&1
    if ($pythonVersion -match "Python ([0-9]+)\.([0-9]+)") {
        $major = [int]$matches[1]
        $minor = [int]$matches[2]
        if ($major -ge 3 -and $minor -ge 7) {
            Write-Host " ✅ Python $($matches[0]) found" -ForegroundColor Green
        } else {
            Write-Host " ❌ Python 3.7+ required, found $($matches[0])" -ForegroundColor Red
            exit 1
        }
    }
} catch {
    Write-Host " ❌ Python not found or not in PATH" -ForegroundColor Red
    Write-Host "Please install Python 3.7+ from https://python.org" -ForegroundColor Yellow
    exit 1
}

# Check kubectl
Write-Host "Checking kubectl..." -NoNewline
try {
    $kubectlVersion = kubectl version --client --short 2>$null
    if ($kubectlVersion) {
        Write-Host " ✅ kubectl found" -ForegroundColor Green
    } else {
        Write-Host " ❌ kubectl not found" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host " ❌ kubectl not found or not in PATH" -ForegroundColor Red
    Write-Host "Please install kubectl: https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/" -ForegroundColor Yellow
    exit 1
}

# Check Helm
Write-Host "Checking Helm..." -NoNewline
try {
    $helmVersion = helm version --short 2>$null
    if ($helmVersion) {
        Write-Host " ✅ Helm found" -ForegroundColor Green
    } else {
        Write-Host " ❌ Helm not found" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host " ❌ Helm not found or not in PATH" -ForegroundColor Red
    Write-Host "Please install Helm: https://helm.sh/docs/intro/install/" -ForegroundColor Yellow
    exit 1
}

# Check Azure CLI (optional)
Write-Host "Checking Azure CLI..." -NoNewline
try {
    $azVersion = az version 2>$null
    if ($azVersion) {
        Write-Host " ✅ Azure CLI found" -ForegroundColor Green
    } else {
        Write-Host " ⚠️  Azure CLI not found (optional)" -ForegroundColor Yellow
    }
} catch {
    Write-Host " ⚠️  Azure CLI not found (optional)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🔧 Setting up Python environment..." -ForegroundColor Yellow

# Install Python dependencies
if (Test-Path "requirements.txt") {
    Write-Host "Installing Python dependencies..."
    try {
        python -m pip install --upgrade pip
        python -m pip install -r requirements.txt
        Write-Host " ✅ Python dependencies installed" -ForegroundColor Green
    } catch {
        Write-Host " ❌ Failed to install Python dependencies" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host " ⚠️  requirements.txt not found, skipping Python dependencies" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🎯 Configuring AKS cluster access..." -ForegroundColor Yellow

# Get AKS cluster credentials - check environment variables first
$subscriptionId = $env:AZURE_SUBSCRIPTION_ID
$resourceGroup = $env:AZURE_RESOURCE_GROUP
$clusterName = $env:AZURE_CLUSTER_NAME

# If environment variables are not set, prompt user
if (-not $subscriptionId) {
    Write-Host ""
    Write-Host "⚠️  AKS CLUSTER CONFIGURATION REQUIRED!" -ForegroundColor Red
    Write-Host "Please provide your AKS cluster details:" -ForegroundColor Yellow
    Write-Host ""
    $subscriptionId = Read-Host "Enter your Azure Subscription ID"
}
if (-not $resourceGroup) {
    $resourceGroup = Read-Host "Enter your Resource Group name"
}
if (-not $clusterName) {
    $clusterName = Read-Host "Enter your AKS Cluster name"
}

# Validate inputs
if (-not $subscriptionId -or -not $resourceGroup -or -not $clusterName) {
    Write-Host "❌ All cluster details are required. Exiting..." -ForegroundColor Red
    exit 1
}

Write-Host "Connecting to AKS cluster: $resourceGroup/$clusterName"

try {
    # Get AKS credentials
    az aks get-credentials --subscription $subscriptionId --resource-group $resourceGroup --name $clusterName --overwrite-existing
    
    # Test cluster connectivity
    $clusterInfo = kubectl cluster-info 2>$null
    if ($clusterInfo) {
        Write-Host " ✅ Successfully connected to AKS cluster" -ForegroundColor Green
        Write-Host "Cluster info:" -ForegroundColor Gray
        Write-Host $clusterInfo -ForegroundColor Gray
    } else {
        Write-Host " ⚠️  Could not verify cluster connectivity" -ForegroundColor Yellow
    }
} catch {
    Write-Host " ⚠️  Could not connect to AKS cluster automatically" -ForegroundColor Yellow
    Write-Host "Please run manually:" -ForegroundColor Yellow
    Write-Host "az aks get-credentials --subscription $subscriptionId --resource-group $resourceGroup --name $clusterName" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "🛡️  Checking Defender for Containers..." -ForegroundColor Yellow

try {
    $defenderPods = kubectl get ds microsoft-defender-collector-ds -n kube-system 2>$null
    if ($defenderPods) {
        Write-Host " ✅ Defender for Containers sensor found" -ForegroundColor Green
    } else {
        Write-Host " ⚠️  Defender for Containers sensor not found" -ForegroundColor Yellow
        Write-Host "Please ensure Defender for Containers is enabled on your AKS cluster" -ForegroundColor Yellow
    }
} catch {
    Write-Host " ⚠️  Could not check Defender sensor status" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📁 Creating log directories..." -ForegroundColor Yellow

# Create logs directory
if (!(Test-Path "logs")) {
    New-Item -ItemType Directory -Path "logs" | Out-Null
    Write-Host " ✅ Created logs directory" -ForegroundColor Green
} else {
    Write-Host " ✅ Logs directory already exists" -ForegroundColor Green
}

Write-Host ""
Write-Host "🎉 Setup completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Run the enhanced simulation: python enhanced_simulation.py" -ForegroundColor White
Write-Host "2. Run with specific config: python enhanced_simulation.py --config configs/aks-testing.yaml" -ForegroundColor White
Write-Host ""
Write-Host "Configuration files:" -ForegroundColor Cyan
Write-Host "- configs/aks-testing.yaml - AKS cluster configuration" -ForegroundColor White
Write-Host "- Enhanced attack scripts in scripts/ directory" -ForegroundColor White
Write-Host ""
Write-Host "Happy testing! 🚀" -ForegroundColor Green