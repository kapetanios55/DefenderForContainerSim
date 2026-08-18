# Quick Start Guide

## 🚀 Get Started in 5 Minutes

### 1. Run Setup
```powershell
.\setup.ps1
```

### 2. Choose Your Simulation

#### Option A: Enhanced Interactive Simulation
```bash
python enhanced_simulation.py
```

#### Option B: Custom Configuration
```bash
python enhanced_simulation.py --config configs/aks-testing.yaml
```

#### Option C: Microsoft Baseline Scenarios
```bash
python enhanced_simulation.py --scenarios recon lateral-mov secrets crypto webshell
```

#### Option D: Include Binary Drift
```bash
python enhanced_simulation.py --scenarios binary-drift
```

#### Option E: Run Implemented Enhanced Scenarios
```bash
python enhanced_simulation.py --scenarios container-escape privilege-escalation apt-simulation binary-drift
```

### 3. Monitor Defender Alerts

While the simulation runs, monitor alerts in:
- **Microsoft Defender for Cloud** > **Security alerts**

### 4. Expected Timeline

| Time | What to Expect |
|------|----------------|
| 0-2 min | Pod deployment and startup |
| 0-5 min | Attack scenario execution |  
| 1-15 min | First Defender alerts can appear |
| 15-60 min | All alerts should be visible |

### 5. Common Defender Alerts

✅ **Immediate alerts (1-5 minutes):**
- Possible Web Shell activity detected
- Network scanning tool detected
- Suspicious command execution

✅ **Delayed alerts (15-60 minutes):**
- Access to cloud metadata service detected
- Possible Crypto miners download detected
- Container with high privileges detected
- Binary drift detected in container

## 🎯 Target AKS Cluster

**CONFIGURATION REQUIRED**: Set your cluster details using environment variables, config file, or interactive prompts  
**Methods**: Environment variables, configs/aks-testing.yaml, or interactive prompts  
**Find clusters**: `az aks list --output table`

## 🔧 Quick Troubleshooting

**Pod creation fails?**
```bash
kubectl get pods -n enhanced-mdc-simulation
kubectl describe pod <pod-name> -n enhanced-mdc-simulation
```

**No alerts appearing?**
- Check Defender for Containers is enabled
- Verify sensor is running: `kubectl get ds microsoft-defender-collector-ds -n kube-system`
- Confirm every sensor pod is ready: `kubectl get pods -n kube-system -l dsName=microsoft-defender-collector`
- Run the five Microsoft baseline scenarios shown above; custom Jobs are not guaranteed to produce the same alerts
- Check **Microsoft Defender for Cloud > Security alerts**, not only the cluster's Container Insights workspace
- Some alerts take up to 1 hour to appear

**Permission errors?**
- Ensure you have admin access to the AKS cluster
- Check kubectl context: `kubectl config current-context`

## 🧹 Cleanup

**Manual cleanup:**
```bash
kubectl delete namespace enhanced-mdc-simulation
```

**Or use cleanup script:**
```bash
python enhanced_simulation.py --cleanup-only
```

## 📊 View Results

Check the `logs/` directory for:
- Execution logs
- Generated reports

## 🆘 Need Help?

1. Check the main [README.md](README.md) for detailed information
2. Review configuration in `configs/aks-testing.yaml`
3. Examine individual attack scripts in `scripts/` directory
