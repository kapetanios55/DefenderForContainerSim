# Enhanced Defender for Containers Attack Simulation

> **⚠️ NEW USERS**: This tool requires AKS cluster configuration. See [CUSTOMER-README.md](CUSTOMER-README.md) for quick setup, or run `./customer-setup.ps1`

An enhanced version of Microsoft's Defender for Cloud Attack Simulation tool, specifically adapted for testing Defender for Containers in AKS environments with additional real-world attack scenarios and improved usability.

## Overview

This tool simulates various attack scenarios commonly used in real-world attacks against containerized environments:

### Core Attack Scenarios
- **Reconnaissance** - Gather information about the cluster environment
- **Lateral Movement** - Cluster to cloud movement and IMDS access
- **Secrets Gathering** - Search for sensitive information and credentials
- **Crypto Mining** - Simulate cryptocurrency mining attacks
- **Web Shell** - Exploit web shells for remote access
- **Container Escape** - Attempt container breakout techniques
- **Privilege Escalation** - Escalate privileges within containers
- **Binary Drift** - Execute binaries not in the original image

### Enhanced Features
- **Multi-cluster support** - Target specific AKS clusters by resource ID
- **Enhanced reporting** - Detailed attack logs and timeline
- **Custom scenarios** - Support for user-defined attack scenarios
- **Alert correlation** - Track which attacks trigger which Defender alerts
- **Automated cleanup** - Comprehensive resource cleanup after testing
- **Configuration management** - Easy configuration for different environments

## 🎯 Target AKS Cluster Configuration

**⚠️ IMPORTANT**: This tool requires configuration of your AKS cluster details before use.

### Quick Setup Options:

**Option 1: Environment Variables** (Recommended)
```bash
# Set these environment variables
export AZURE_SUBSCRIPTION_ID="your-subscription-id"
export AZURE_RESOURCE_GROUP="your-resource-group"
export AZURE_CLUSTER_NAME="your-cluster-name"
```

**Option 2: Update Configuration File**
Edit `configs/aks-testing.yaml` with your cluster details

**Option 3: Interactive Prompt**
The script will prompt you for cluster details if not configured

### Find Your Cluster Details:
```bash
# List your AKS clusters
az aks list --output table

# Get specific cluster details
az aks show --name YOUR_CLUSTER_NAME --resource-group YOUR_RESOURCE_GROUP
```

## Prerequisites

1. **Admin permissions** over the target Kubernetes cluster
2. **Defender for Containers** enabled with the sensor installed:
   ```bash
   kubectl get ds microsoft-defender-collector-ds -n kube-system
   ```
3. **Helm 3.x** installed locally for the Microsoft baseline scenarios
4. **Python 3.7+** installed
5. **kubectl** configured for your target cluster:
   ```bash
   az aks get-credentials --name YOUR_CLUSTER_NAME --resource-group YOUR_RESOURCE_GROUP
   ```

## Installation

1. Clone this repository:
   ```bash
   git clone <this-repo>
   cd DefenderForContainers
   ```

2. Install Python dependencies:
   ```bash
   pip install -r requirements.txt
   ```

3. Verify cluster connectivity:
   ```bash
   kubectl cluster-info
   ```

## Quick Start

Run the enhanced simulation:
```bash
python enhanced_simulation.py
```

Or run with specific configuration:
```bash
python enhanced_simulation.py --config configs/aks-testing.yaml
```

## Configuration

The tool supports flexible configuration through YAML files. See `configs/` directory for examples.

## Expected Defender Alerts

| **Scenario** | **Expected Alerts** |
|--------------|-------------------|
| Reconnaissance | Possible Web Shell activity detected, Suspicious Kubernetes service account operation detected, Network scanning tool detected |
| Lateral Movement | Possible Web Shell activity detected, Access to cloud metadata service detected |
| Secrets Gathering | Possible Web Shell activity detected, Sensitive files access detected, Possible secret reconnaissance detected |
| Crypto Mining | Possible Web Shell activity detected, Kubernetes CPU optimization detected, Command within a container accessed `ld.so.preload`, Possible Crypto miners download detected, A drift binary detected executing in the container |
| Container Escape | Privileged container detected, Suspicious mount detected, Container with sensitive volume mount detected |
| Privilege Escalation | Privileged operation detected, Container with high privileges detected |
| Binary Drift | Binary drift detected in container, A drift binary detected executing in the container |

## Best Practices

- **Dedicated Environment**: Run simulations on dedicated test clusters only
- **Monitoring**: Monitor Defender for Containers alerts during testing
- **Cleanup**: Always run cleanup after simulations
- **Documentation**: Document which scenarios trigger which alerts

## Enhanced Scenarios

Beyond the original Microsoft scenarios, this tool includes:

The following enhanced scenarios run as dedicated Kubernetes Jobs and do not require Helm:

- `container-escape` - Privileged workload with host PID, host network, host filesystem, and containerd socket access
- `privilege-escalation` - Privileged container checks for capabilities, writable host paths, service account tokens, and escalation opportunities
- `apt-simulation` - Multi-stage reconnaissance, credential access, discovery, persistence, command-and-control, and impact simulation
- `binary-drift` - Copies and executes a binary from a writable path outside the original image filesystem

Run them directly:

```bash
python enhanced_simulation.py --scenarios container-escape privilege-escalation apt-simulation binary-drift
```

Each Job's output and the consolidated execution report are saved under the timestamped `logs/` directory. The simulation namespace is removed automatically after non-interactive runs.

### Advanced Persistent Threat (APT) Simulation
- Multi-stage attack chains
- Data exfiltration techniques
- Command and control communication

### Real-world Container Attacks
- Supply chain attacks
- Image vulnerabilities exploitation
- Runtime security bypass

### Cloud-Native Threats
- Service mesh exploitation
- Istio/Envoy proxy attacks
- Kubernetes API abuse

## License

MIT License - Based on Microsoft's original Defender for Cloud Attack Simulation
