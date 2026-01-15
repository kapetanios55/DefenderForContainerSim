# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
# Enhanced version for AKS Defender for Containers testing

import subprocess
import time
import argparse
import yaml
import os
import sys
from datetime import datetime
from typing import Dict, List, Optional

class EnhancedDefenderSimulation:
    """Enhanced Defender for Containers Attack Simulation"""
    
    def __init__(self, config_file: Optional[str] = None):
        self.load_config(config_file)
        self.setup_logging()
        
    def load_config(self, config_file: Optional[str] = None):
        """Load configuration from file or use defaults"""
        # Check for environment variables first, then use config file or prompt user
        subscription_id = os.environ.get('AZURE_SUBSCRIPTION_ID')
        resource_group = os.environ.get('AZURE_RESOURCE_GROUP')
        cluster_name = os.environ.get('AZURE_CLUSTER_NAME')
        
        if not all([subscription_id, resource_group, cluster_name]):
            print("\n⚠️  CLUSTER CONFIGURATION REQUIRED!")
            print("Please configure your AKS cluster details in one of these ways:")
            print("1. Set environment variables: AZURE_SUBSCRIPTION_ID, AZURE_RESOURCE_GROUP, AZURE_CLUSTER_NAME")
            print("2. Update the configuration in configs/aks-testing.yaml")
            print("3. Update the default_config below and provide values when prompted\n")
            
            if not subscription_id:
                subscription_id = input("Enter your Azure Subscription ID: ").strip()
            if not resource_group:
                resource_group = input("Enter your Resource Group name: ").strip()
            if not cluster_name:
                cluster_name = input("Enter your AKS Cluster name: ").strip()
        
        default_config = {
            "aks_cluster": {
                "subscription_id": subscription_id,
                "resource_group": resource_group, 
                "cluster_name": cluster_name
            },
            "helm": {
                "chart": "oci://ghcr.io/microsoft/defender-for-cloud/attacksimulation/mdc-simulation",
                "release": "enhanced-mdc-simulation",
                "namespace": "enhanced-mdc-simulation"
            },
            "scenarios": {
                "basic": ["recon", "lateral-mov", "secrets", "crypto", "webshell"],
                  "enhanced": ["container-escape", "privilege-escalation", "apt-simulation", "supply-chain", "binary-drift"],
                "all": ["recon", "lateral-mov", "secrets", "crypto", "webshell", "container-escape", 
                      "privilege-escalation", "apt-simulation", "supply-chain", "binary-drift"]
            },
            "timeouts": {
                "pod_creation": 300,
                "scenario_execution": 180
            },
            "monitoring": {
                "alert_check_interval": 60,
                "max_wait_for_alerts": 3600
            }
        }
        
        if config_file and os.path.exists(config_file):
            with open(config_file, 'r') as f:
                user_config = yaml.safe_load(f)
                # Merge configurations
                self.config = {**default_config, **user_config}
        else:
            self.config = default_config
            
        # Set up constants from config
        self.HELM_CHART = self.config["helm"]["chart"]
        self.HELM_RELEASE = self.config["helm"]["release"] 
        self.NAMESPACE = self.config["helm"]["namespace"]
        # Microsoft Helm chart always uses "mdc-simulation" as prefix regardless of release name
        self.ATTACKER = "mdc-simulation-attacker"
        self.VICTIM = "mdc-simulation-victim"
        
    def setup_logging(self):
        """Setup logging directory and files"""
        self.log_dir = f"logs/{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        os.makedirs(self.log_dir, exist_ok=True)
        
    def print_banner(self):
        """Print enhanced banner"""
        banner = """
╔══════════════════════════════════════════════════════════════════════════════╗
║                    Enhanced Defender for Containers                         ║
║                        Attack Simulation Tool                               ║
║                                                                              ║
║  Target AKS: {}/{}                                    ║
║  Namespace: {}                                               ║
╚══════════════════════════════════════════════════════════════════════════════╝
        """.format(
            self.config["aks_cluster"]["resource_group"],
            self.config["aks_cluster"]["cluster_name"],
            self.NAMESPACE
        )
        print(banner)
        
    def check_prerequisites(self) -> bool:
        """Check all prerequisites before running"""
        print("🔍 Checking prerequisites...")
        
        checks = [
            ("kubectl", ["kubectl", "version", "--client"]),
            ("helm", ["helm", "version"]),
            ("python", [sys.executable, "--version"]),
            ("cluster connectivity", ["kubectl", "cluster-info"])
        ]
        
        for check_name, command in checks:
            try:
                result = subprocess.run(command, capture_output=True, text=True, timeout=30)
                if result.returncode == 0:
                    print(f"✅ {check_name}: OK")
                else:
                    print(f"❌ {check_name}: FAILED")
                    return False
            except Exception as e:
                print(f"❌ {check_name}: FAILED - {str(e)}")
                return False
                
        # Check Defender sensor
        try:
            result = subprocess.run([
                "kubectl", "get", "ds", "microsoft-defender-collector-ds", 
                "-n", "kube-system"
            ], capture_output=True, text=True)
            
            if result.returncode == 0:
                print("✅ Defender for Containers sensor: FOUND")
            else:
                print("⚠️  Defender for Containers sensor: NOT FOUND")
                response = input("Continue without Defender sensor? (y/N): ")
                if response.lower() != 'y':
                    return False
                    
        except Exception as e:
            print(f"⚠️  Could not check Defender sensor: {str(e)}")
            
        return True
        
    def show_scenario_menu(self) -> str:
        """Display scenario selection menu"""
        menu = """
Available Attack Scenarios:

🔍 RECONNAISSANCE SCENARIOS:
   1. Basic Recon - Kubernetes API discovery and enumeration
   2. Network Scan - Port scanning and service discovery
   
🔄 LATERAL MOVEMENT SCENARIOS:  
   3. Cloud Metadata - IMDS access and token harvesting
   4. Service Discovery - Internal service enumeration
   
🔐 CREDENTIAL SCENARIOS:
   5. Secret Harvesting - Search for secrets and credentials
   6. Token Theft - Kubernetes service account token theft
   
⛏️  RESOURCE ABUSE SCENARIOS:
   7. Crypto Mining - Cryptocurrency mining simulation
   8. Resource Exhaustion - CPU/Memory consumption attacks
   
💻 EXECUTION SCENARIOS:
   9. Web Shell - Remote command execution via web shell
   10. Reverse Shell - Network-based remote access
   
🚪 ESCAPE SCENARIOS:
   11. Container Escape - Attempt container breakout
   12. Privilege Escalation - Escalate container privileges
   
🎯 ADVANCED SCENARIOS:
   13. APT Simulation - Multi-stage persistent threat
   14. Supply Chain - Malicious image/dependency attacks
    15. Binary Drift - Execute binaries not in original image
   
📦 SCENARIO GROUPS:
    16. Basic Scenarios (1-5) - Original Microsoft scenarios
    17. Enhanced Scenarios (6-15) - Additional real-world attacks  
    18. All Scenarios - Complete attack simulation
   
   0. Exit
"""
        print(menu)
        
        while True:
            choice = input("Select scenario (0-18): ").strip()
            if choice.isdigit() and 0 <= int(choice) <= 18:
                return choice
            print("\u274c Invalid selection. Please choose 0-18.")
            
    def map_scenario_choice(self, choice: str) -> List[str]:
        """Map user choice to scenario list"""
        scenario_map = {
            "1": ["recon"],
            "2": ["network-scan"], 
            "3": ["lateral-mov"],
            "4": ["service-discovery"],
            "5": ["secrets"],
            "6": ["token-theft"],
            "7": ["crypto"],
            "8": ["resource-exhaustion"],
            "9": ["webshell"],
            "10": ["reverse-shell"],
            "11": ["container-escape"],
            "12": ["privilege-escalation"], 
            "13": ["apt-simulation"],
            "14": ["supply-chain"],
            "15": ["binary-drift"],
            "16": self.config["scenarios"]["basic"],
            "17": self.config["scenarios"]["enhanced"],
            "18": self.config["scenarios"]["all"]
        }
        
        return scenario_map.get(choice, [])
        
    def create_namespace(self):
        """Create simulation namespace"""
        print(f"📦 Creating namespace: {self.NAMESPACE}")
        try:
            subprocess.run([
                "kubectl", "create", "namespace", self.NAMESPACE
            ], check=True, capture_output=True)
            print(f"✅ Namespace {self.NAMESPACE} created")
        except subprocess.CalledProcessError:
            # Namespace might already exist
            print(f"ℹ️  Namespace {self.NAMESPACE} already exists")
            
    def deploy_simulation_pods(self, scenarios: List[str]):
        """Deploy attacker and victim pods"""
        print("🚀 Deploying simulation pods...")
        
        # Create namespace first
        self.create_namespace()
        
        # Map scenarios to Microsoft-supported ones for Helm deployment
        microsoft_scenarios = ["recon", "lateral-mov", "secrets", "crypto", "webshell"]
        enhanced_scenarios = ["container-escape", "privilege-escalation", "network-scan", "token-theft", 
                              "resource-exhaustion", "reverse-shell", "apt-simulation", "supply-chain", "service-discovery", "binary-drift"]
        
        # Filter scenarios to only use Microsoft-supported ones for Helm
        helm_scenarios = [s for s in scenarios if s in microsoft_scenarios]
        custom_scenarios = [s for s in scenarios if s in enhanced_scenarios]
        
        # Use "all" for Microsoft scenarios if multiple basic scenarios are selected
        if len(helm_scenarios) >= 3:
            scenario_string = "all"
        elif helm_scenarios:
            scenario_string = ",".join(helm_scenarios)
        else:
            scenario_string = "recon"  # Default fallback
        
        try:
            # Clean up any existing pods
            self.cleanup_pods()
            
            # Install/upgrade helm chart
            helm_command = [
                "helm", "upgrade", "--install", self.HELM_RELEASE, self.HELM_CHART,
                "--namespace", self.NAMESPACE,
                "--set", f"scenario={scenario_string}",
                "--set", f"env.name={self.NAMESPACE}",
                "--timeout", "5m",
                "--wait"
            ]
            
            result = subprocess.run(helm_command, capture_output=True, text=True, timeout=300)
            
            if result.returncode != 0:
                print(f"❌ Failed to deploy helm chart: {result.stderr}")
                raise Exception("Helm deployment failed")
                
            print("✅ Helm chart deployed successfully")
            
        except Exception as e:
            print(f"❌ Deployment error: {str(e)}")
            raise

        # Deploy binary drift workload if requested
        if "binary-drift" in scenarios:
            self.deploy_binary_drift_workload()

    def deploy_binary_drift_workload(self):
        """Deploy a workload that triggers binary drift detection"""
        drift_manifest = os.path.join("Testing", "binary-drift-test.yaml")
        if not os.path.exists(drift_manifest):
            print("\u26a0\ufe0f  Binary drift manifest not found: Testing/binary-drift-test.yaml")
            return

        print("\ud83e\uddea Deploying binary drift workload...")
        try:
            subprocess.run([
                "kubectl", "apply", "-f", drift_manifest, "--validate=false"
            ], check=True, capture_output=True, text=True, timeout=60)
            print("\u2705 Binary drift workload deployed")
        except subprocess.CalledProcessError as e:
            print(f"\u26a0\ufe0f  Binary drift workload deployment failed: {e.stderr.strip()}")
        except Exception as e:
            print(f"\u26a0\ufe0f  Binary drift workload deployment error: {str(e)}")
            
    def wait_for_pods(self):
        """Wait for pods to be ready (not pending)"""
        print("⏳ Waiting for pods to be ready...")
        
        timeout = self.config["timeouts"]["pod_creation"]
        start_time = time.time()
        
        while time.time() - start_time < timeout:
            try:
                # Check attacker pod status  
                attacker_result = subprocess.run([
                    "kubectl", "get", "pod", self.ATTACKER,
                    "-n", self.NAMESPACE,
                    "-o", r'jsonpath="{.status.phase}"'
                ], capture_output=True, text=True)
                
                # Check victim pod status
                victim_result = subprocess.run([
                    "kubectl", "get", "pod", self.VICTIM,
                    "-n", self.NAMESPACE, 
                    "-o", r'jsonpath="{.status.phase}"'
                ], capture_output=True, text=True)
                
                # If either pod is still pending, continue waiting
                if '"Pending"' in (attacker_result.stdout, victim_result.stdout):
                    # Check if containers are creating or failed
                    if attacker_result.stdout == '"Pending"':
                        attacker_waiting = subprocess.run([
                            "kubectl", "get", "pod", self.ATTACKER, "-n", self.NAMESPACE,
                            "-o", r'jsonpath="{.status.containerStatuses[0].state.waiting.reason}"'
                        ], capture_output=True, text=True)
                        
                        if attacker_waiting.stdout not in ['"ContainerCreating"', '"PodInitializing"', '""']:
                            print(f"❌ Attacker pod failed to start: {attacker_waiting.stdout}")
                            return False
                    
                    if victim_result.stdout == '"Pending"':
                        victim_waiting = subprocess.run([
                            "kubectl", "get", "pod", self.VICTIM, "-n", self.NAMESPACE,
                            "-o", r'jsonpath="{.status.containerStatuses[0].state.waiting.reason}"'
                        ], capture_output=True, text=True)
                        
                        if victim_waiting.stdout not in ['"ContainerCreating"', '"PodInitializing"', '""']:
                            print(f"❌ Victim pod failed to start: {victim_waiting.stdout}")
                            return False
                    
                    time.sleep(3)
                    continue
                
                # Check for failed pods
                if '"Failed"' in (attacker_result.stdout, victim_result.stdout):
                    print(f"❌ Pod creation failed:")
                    print(f"  Attacker: {attacker_result.stdout}")
                    print(f"  Victim: {victim_result.stdout}")
                    return False
                
                # Pods are ready (Running, Succeeded, or other non-Pending status)
                print("✅ Pods are ready")
                return True
                
            except Exception as e:
                print(f"⚠️  Error checking pod status: {str(e)}")
                time.sleep(3)
                
        print("❌ Timeout waiting for pods to be ready")
        return False
        return False
        
    def run_scenarios(self, scenarios: List[str]):
        """Execute the attack scenarios"""
        print(f"🎯 Running scenarios: {', '.join(scenarios)}")
        
        try:
            # Follow attacker pod logs like the Microsoft simulation does
            print("📋 Running the scenario...\n")
            
            # Use kubectl logs -f with timeout like Microsoft simulation
            try:
                subprocess.run([
                    "kubectl", "logs", "-f", self.ATTACKER, "-n", self.NAMESPACE
                ], timeout=90)
            except subprocess.TimeoutExpired:
                print("⚠️  Scenario did not complete successfully (timeout)")
                return False
            
            # Check if scenario completed successfully by checking last line
            last_line_result = subprocess.run([
                "kubectl", "logs", "--tail=1", self.ATTACKER, "-n", self.NAMESPACE
            ], text=True, capture_output=True)
            
            if last_line_result.stdout.strip() == "--- Simulation completed ---":
                print("\n✅ Scenario completed successfully")
                return True
            else:
                print("\n❌ Scenario did not complete successfully")
                return False
                
        except Exception as e:
            print(f"❌ Error during scenario execution: {str(e)}")
            return False
            
    def cleanup_pods(self):
        """Clean up simulation pods"""
        print("🧹 Cleaning up simulation pods...")
        
        try:
            # Delete specific pods first
            for pod in [self.ATTACKER, self.VICTIM]:
                subprocess.run([
                    "kubectl", "delete", "pod", pod, 
                    "-n", self.NAMESPACE, 
                    "--ignore-not-found=true"
                ], capture_output=True, timeout=30)
                
            time.sleep(5)
            print("✅ Pods cleaned up")
            
        except Exception as e:
            print(f"⚠️  Error during pod cleanup: {str(e)}")
            
    def cleanup_all(self):
        """Complete cleanup of all simulation resources"""
        print("🧹 Performing complete cleanup...")
        
        try:
            # Uninstall helm release
            subprocess.run([
                "helm", "uninstall", self.HELM_RELEASE, 
                "-n", self.NAMESPACE
            ], capture_output=True, timeout=60)
            
            # Delete namespace
            subprocess.run([
                "kubectl", "delete", "namespace", self.NAMESPACE, 
                "--ignore-not-found=true"
            ], capture_output=True, timeout=120)
            
            print("✅ Complete cleanup finished")
            
        except Exception as e:
            print(f"⚠️  Error during cleanup: {str(e)}")
            
    def generate_report(self, scenarios: List[str], success: bool):
        """Generate execution report"""
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        
        report = f"""
# Defender for Containers Attack Simulation Report

**Generated**: {timestamp}
**Target Cluster**: {self.config['aks_cluster']['resource_group']}/{self.config['aks_cluster']['cluster_name']}
**Namespace**: {self.NAMESPACE}
**Scenarios**: {', '.join(scenarios)}
**Execution Status**: {'✅ SUCCESS' if success else '❌ FAILED'}

## Executed Scenarios

"""
        
        scenario_descriptions = {
            "recon": "Reconnaissance - Kubernetes API discovery and enumeration",
            "lateral-mov": "Lateral Movement - Cloud metadata access and token harvesting", 
            "secrets": "Secret Harvesting - Search for credentials and sensitive files",
            "crypto": "Crypto Mining - Cryptocurrency mining simulation",
            "webshell": "Web Shell - Remote command execution via web shell",
            "container-escape": "Container Escape - Attempt container breakout techniques",
            "privilege-escalation": "Privilege Escalation - Escalate container privileges",
            "binary-drift": "Binary Drift - Execute binaries not in original image"
        }
        
        for scenario in scenarios:
            description = scenario_descriptions.get(scenario, f"Custom scenario: {scenario}")
            report += f"- **{scenario}**: {description}\n"
            
        report += f"""

## Expected Defender Alerts

The following alerts should be triggered in Defender for Containers:

- Possible Web Shell activity detected
- Suspicious Kubernetes service account operation detected  
- Network scanning tool detected
- Access to cloud metadata service detected
- Sensitive files access detected
- Possible secret reconnaissance detected
- Kubernetes CPU optimization detected
- Command within a container accessed ld.so.preload
- Possible Crypto miners download detected
- A drift binary detected executing in the container
- Binary drift detected in container

## Log Files

Execution logs are available in: `{self.log_dir}/`

## Next Steps

1. Monitor Defender for Containers alerts in Azure Security Center
2. Review alert details and investigate detection capabilities
3. Document any gaps in detection for improvement
4. Run cleanup if not already completed: `kubectl delete namespace {self.NAMESPACE}`

---
*Report generated by Enhanced Defender for Containers Attack Simulation*
"""

        report_file = os.path.join(self.log_dir, "execution_report.md")
        with open(report_file, 'w', encoding='utf-8') as f:
            f.write(report)
            
        print(f"📊 Report generated: {report_file}")
        
    def run(self):
        """Main execution flow"""
        try:
            self.print_banner()
            
            if not self.check_prerequisites():
                print("❌ Prerequisites check failed. Exiting.")
                return False
                
            choice = self.show_scenario_menu()
            
            if choice == "0":
                print("👋 Goodbye!")
                return True
                
            scenarios = self.map_scenario_choice(choice)
            
            if not scenarios:
                print("❌ Invalid scenario selection")
                return False
                
            print(f"\n🎯 Selected scenarios: {', '.join(scenarios)}")
            confirm = input("Continue with execution? (y/N): ")
            
            if confirm.lower() != 'y':
                print("❌ Execution cancelled by user")
                return False
                
            # Execute simulation
            self.deploy_simulation_pods(scenarios)
            
            if not self.wait_for_pods():
                print("❌ Pod deployment failed")
                self.cleanup_all()
                return False
                
            success = self.run_scenarios(scenarios)
            
            # Generate report
            self.generate_report(scenarios, success)
            
            # Ask about cleanup
            cleanup = input("\n🧹 Perform cleanup now? (Y/n): ")
            if cleanup.lower() != 'n':
                self.cleanup_all()
            else:
                print(f"⚠️  Remember to clean up manually: kubectl delete namespace {self.NAMESPACE}")
                
            return success
            
        except KeyboardInterrupt:
            print("\n⚠️  Interrupted by user")
            cleanup = input("Perform cleanup before exit? (Y/n): ")
            if cleanup.lower() != 'n':
                self.cleanup_all()
            return False
            
        except Exception as e:
            print(f"❌ Unexpected error: {str(e)}")
            self.cleanup_all()
            return False


def main():
    parser = argparse.ArgumentParser(description='Enhanced Defender for Containers Attack Simulation')
    parser.add_argument('--config', '-c', help='Configuration file path')
    parser.add_argument('--scenarios', '-s', nargs='+', help='Specific scenarios to run')
    parser.add_argument('--cleanup-only', action='store_true', help='Only perform cleanup')
    
    args = parser.parse_args()
    
    simulation = EnhancedDefenderSimulation(args.config)
    
    if args.cleanup_only:
        simulation.cleanup_all()
        return
        
    if args.scenarios:
        # Direct scenario execution
        print(f"🎯 Running scenarios: {', '.join(args.scenarios)}")
        simulation.deploy_simulation_pods(args.scenarios)
        if simulation.wait_for_pods():
            success = simulation.run_scenarios(args.scenarios)
            simulation.generate_report(args.scenarios, success)
        simulation.cleanup_all()
    else:
        # Interactive mode
        simulation.run()


if __name__ == '__main__':
    main()