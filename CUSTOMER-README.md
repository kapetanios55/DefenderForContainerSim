# 🚀 Quick Setup Guide for Customers

**Welcome!** This is the enhanced Microsoft Defender for Containers Attack Simulation tool.

## ⚠️ Before You Start

**This tool requires your AKS cluster configuration!** Don't worry - we've made it super easy.

## 🎯 One-Command Setup (Recommended)

```powershell
# Clone the repository
git clone https://github.com/kapetanios55/DefenderForContainerSim.git
cd DefenderForContainerSim

# Run the automated setup
./customer-setup.ps1
```

The setup script will:
- ✅ Check if you have Azure CLI installed
- ✅ Verify you're logged into Azure
- ✅ Show your available AKS clusters  
- ✅ Set up environment variables
- ✅ Test cluster connectivity
- ✅ Check Defender for Containers status

## 🏃‍♂️ Quick Start After Setup

```bash
# Run all attack scenarios
python enhanced_simulation.py --scenarios all

# Run specific scenarios
python enhanced_simulation.py --scenarios recon,secrets

# Interactive menu
python enhanced_simulation.py
```

## 🔧 Manual Configuration (Alternative)

If you prefer manual setup:

### Method 1: Environment Variables
```powershell
$env:AZURE_SUBSCRIPTION_ID = "your-subscription-id"
$env:AZURE_RESOURCE_GROUP = "your-resource-group"  
$env:AZURE_CLUSTER_NAME = "your-cluster-name"
```

### Method 2: Configuration File
```bash
# Copy template and edit with your details
cp configs/config-template.yaml configs/my-cluster.yaml
# Edit my-cluster.yaml

# Run with custom config
python enhanced_simulation.py --config configs/my-cluster.yaml
```

### Method 3: Interactive Prompts
Just run the script and it will ask for your cluster details:
```bash
python enhanced_simulation.py
```

## 📋 Find Your Cluster Details

```bash
# List all your AKS clusters
az aks list --output table

# Get specific cluster info
az aks show --name YOUR_CLUSTER_NAME --resource-group YOUR_RESOURCE_GROUP
```

## 🛡️ What This Tool Does

Simulates real-world attacks against your AKS cluster to test Defender for Containers:

- **Reconnaissance** - Information gathering
- **Lateral Movement** - Cloud metadata access
- **Secrets Gathering** - Credential searches  
- **Crypto Mining** - Mining simulation
- **Web Shell** - Shell access attempts
- **Container Escape** - Breakout attempts
- **Privilege Escalation** - Permission elevation

## 📊 Expected Results

After running scenarios, you should see alerts in:
- Microsoft Defender for Cloud Security alerts
- Azure Security Center
- Log Analytics workspace

## 🆘 Need Help?

1. **Setup Issues**: Run `./customer-setup.ps1` to diagnose
2. **No Alerts**: Verify Defender for Containers is enabled
3. **Permission Errors**: Ensure you have admin access to the cluster

## 📖 Full Documentation

See [README.md](README.md) for complete technical documentation.

---

**Happy Testing!** 🎯