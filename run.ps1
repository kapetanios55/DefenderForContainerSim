#!/usr/bin/env pwsh
# Enhanced Defender for Containers - Build/Run Script
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

param(
    [string]$Action = "help",
    [string]$Config = "configs/aks-testing.yaml",
    [string[]]$Scenarios = @(),
    [switch]$CleanupOnly
)

function Show-Help {
    Write-Host "Enhanced Defender for Containers - Build/Run Script" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage: .\run.ps1 [ACTION] [OPTIONS]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Actions:" -ForegroundColor Green
    Write-Host "  setup       - Run initial setup and install dependencies"
    Write-Host "  run         - Run enhanced simulation (interactive)"
    Write-Host "  original    - Run original Microsoft simulation"
    Write-Host "  test        - Run test scenarios"
    Write-Host "  cleanup     - Clean up all simulation resources"
    Write-Host "  check       - Check prerequisites and cluster connectivity"
    Write-Host "  help        - Show this help message"
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Green
    Write-Host "  -Config     - Configuration file (default: configs/aks-testing.yaml)"
    Write-Host "  -Scenarios  - Specific scenarios to run (e.g., recon,secrets,crypto)"
    Write-Host "  -CleanupOnly- Only perform cleanup, don't run simulation"
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Yellow
    Write-Host "  .\run.ps1 setup"
    Write-Host "  .\run.ps1 run"
    Write-Host "  .\run.ps1 run -Scenarios recon,secrets"
    Write-Host "  .\run.ps1 cleanup"
    Write-Host "  .\run.ps1 check"
    Write-Host ""
}

function Test-Prerequisites {
    Write-Host "🔍 Checking prerequisites..." -ForegroundColor Yellow
    
    $checks = @(
        @{ Name = "Python"; Command = "python --version" },
        @{ Name = "kubectl"; Command = "kubectl version --client" },
        @{ Name = "Helm"; Command = "helm version" }
    )
    
    $allGood = $true
    
    foreach ($check in $checks) {
        Write-Host "Checking $($check.Name)..." -NoNewline
        try {
            $result = Invoke-Expression $check.Command 2>$null
            if ($result) {
                Write-Host " ✅" -ForegroundColor Green
            } else {
                Write-Host " ❌" -ForegroundColor Red
                $allGood = $false
            }
        } catch {
            Write-Host " ❌" -ForegroundColor Red
            $allGood = $false
        }
    }
    
    # Test cluster connectivity
    Write-Host "Testing cluster connectivity..." -NoNewline
    try {
        $clusterInfo = kubectl cluster-info 2>$null
        if ($clusterInfo) {
            Write-Host " ✅" -ForegroundColor Green
        } else {
            Write-Host " ❌" -ForegroundColor Red
            $allGood = $false
        }
    } catch {
        Write-Host " ❌" -ForegroundColor Red
        $allGood = $false
    }
    
    return $allGood
}

function Run-Setup {
    Write-Host "🔧 Running setup..." -ForegroundColor Yellow
    if (Test-Path "setup.ps1") {
        & .\setup.ps1
    } else {
        Write-Host "❌ setup.ps1 not found" -ForegroundColor Red
        exit 1
    }
}

function Run-Enhanced {
    Write-Host "🚀 Running enhanced simulation..." -ForegroundColor Yellow
    
    $cmd = "python enhanced_simulation.py"
    
    if ($Config -and (Test-Path $Config)) {
        $cmd += " --config $Config"
    }
    
    if ($Scenarios.Count -gt 0) {
        $scenarioList = $Scenarios -join " "
        $cmd += " --scenarios $scenarioList"
    }
    
    if ($CleanupOnly) {
        $cmd += " --cleanup-only"
    }
    
    Write-Host "Executing: $cmd" -ForegroundColor Gray
    Invoke-Expression $cmd
}

function Run-Original {
    Write-Host "🎯 Running original Microsoft simulation..." -ForegroundColor Yellow
    if (Test-Path "simulation.py") {
        python simulation.py
    } else {
        Write-Host "❌ simulation.py not found" -ForegroundColor Red
        exit 1
    }
}

function Run-Test {
    Write-Host "🧪 Running test scenarios..." -ForegroundColor Yellow
    
    $testScenarios = @("recon", "webshell")
    $cmd = "python enhanced_simulation.py --scenarios $($testScenarios -join ' ')"
    
    Write-Host "Executing: $cmd" -ForegroundColor Gray
    Invoke-Expression $cmd
}

function Run-Cleanup {
    Write-Host "🧹 Running cleanup..." -ForegroundColor Yellow
    
    # Enhanced simulation cleanup
    python enhanced_simulation.py --cleanup-only
    
    # Original simulation cleanup (if exists)
    try {
        kubectl delete namespace mdc-simulation --ignore-not-found=true 2>$null
        helm uninstall mdc-simulation 2>$null
    } catch {
        # Ignore errors
    }
    
    Write-Host "✅ Cleanup completed" -ForegroundColor Green
}

# Main execution
switch ($Action.ToLower()) {
    "setup" {
        Run-Setup
    }
    "run" {
        if (!(Test-Prerequisites)) {
            Write-Host "❌ Prerequisites check failed. Run '.\run.ps1 setup' first." -ForegroundColor Red
            exit 1
        }
        Run-Enhanced
    }
    "original" {
        if (!(Test-Prerequisites)) {
            Write-Host "❌ Prerequisites check failed. Run '.\run.ps1 setup' first." -ForegroundColor Red
            exit 1
        }
        Run-Original
    }
    "test" {
        if (!(Test-Prerequisites)) {
            Write-Host "❌ Prerequisites check failed. Run '.\run.ps1 setup' first." -ForegroundColor Red
            exit 1
        }
        Run-Test
    }
    "cleanup" {
        Run-Cleanup
    }
    "check" {
        Test-Prerequisites
    }
    "help" {
        Show-Help
    }
    default {
        Write-Host "❌ Unknown action: $Action" -ForegroundColor Red
        Write-Host ""
        Show-Help
        exit 1
    }
}