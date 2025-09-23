#!/bin/bash

# Enhanced Privilege Escalation Simulation  
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

echo "=== PRIVILEGE ESCALATION SIMULATION ==="
echo "Simulating various privilege escalation techniques..."
echo ""

echo "--- Current User Context ---"
echo "User: $(whoami)"
echo "UID: $(id -u)"
echo "GID: $(id -g)" 
echo "Groups: $(id -G)"
echo "Full ID info: $(id)"
echo ""

echo "--- Capability Analysis ---"
echo "Checking current capabilities..."
if [ -f /proc/self/status ]; then
    echo "Process capabilities:"
    grep Cap /proc/self/status
fi

# Check for dangerous capabilities
echo ""
echo "Checking for dangerous capabilities..."
if command -v capsh >/dev/null 2>&1; then
    echo "Available capabilities:"
    capsh --print | grep -E "(CAP_SYS_ADMIN|CAP_SYS_PTRACE|CAP_SYS_MODULE|CAP_DAC_OVERRIDE)"
fi

echo ""
echo "--- Sudo Privilege Check ---" 
echo "Checking sudo permissions..."
sudo -l 2>/dev/null || echo "No sudo access or sudo not available"

echo ""
echo "--- SUID/SGID Binary Search ---"
echo "Searching for SUID binaries..."
find / -perm -4000 -type f 2>/dev/null | head -20

echo "Searching for SGID binaries..."
find / -perm -2000 -type f 2>/dev/null | head -10

echo ""
echo "--- Writable File Analysis ---"
echo "Checking for writable system files..."
find /etc -writable -type f 2>/dev/null | head -10
find /usr -writable -type f 2>/dev/null | head -10

echo ""
echo "--- Environment Variable Exploitation ---"
echo "Checking dangerous environment variables..."
env | grep -E "(PATH|LD_|SUDO_|HOME)" | head -10

echo "Testing PATH manipulation..."
export PATH="/tmp:$PATH"
echo "Modified PATH: $PATH"

echo ""
echo "--- Container-Specific Privilege Escalation ---"

# Check for Docker daemon access
if [ -S /var/run/docker.sock ]; then
    echo "⚠️  Docker socket available - testing access..."
    if command -v docker >/dev/null 2>&1; then
        echo "Docker client found - this could allow container escapes!"
        # Don't actually execute dangerous commands
        echo "Potential exploit: docker run --privileged --pid=host ..."
    fi
fi

# Check for Kubernetes service account
if [ -f /var/run/secrets/kubernetes.io/serviceaccount/token ]; then
    echo "⚠️  Kubernetes service account token found!"
    echo "Token location: /var/run/secrets/kubernetes.io/serviceaccount/token"
    echo "Namespace: $(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace 2>/dev/null)"
    echo "Token preview: $(head -c 50 /var/run/secrets/kubernetes.io/serviceaccount/token)..."
fi

echo ""
echo "--- Process and File Descriptor Analysis ---"
echo "Analyzing running processes..."
ps aux | head -10 2>/dev/null || ps | head -10

echo "Checking file descriptors..."
ls -la /proc/self/fd/ | head -10

echo ""
echo "--- Memory and Core Dump Analysis ---"
echo "Checking memory maps..."
if [ -f /proc/self/maps ]; then
    echo "Memory mapping info available"
    head -5 /proc/self/maps
fi

echo "Core pattern: $(cat /proc/sys/kernel/core_pattern 2>/dev/null || echo 'Not accessible')"

echo ""
echo "--- Kernel Module Loading ---"
echo "Checking kernel module capabilities..."
if [ -w /proc/sys/kernel/modprobe ]; then
    echo "⚠️  Can write to modprobe - potential privilege escalation!"
fi

# Check loaded modules
echo "Currently loaded modules:"
lsmod 2>/dev/null | head -10 || echo "lsmod not available"

echo ""
echo "--- Crontab and Scheduled Tasks ---"
echo "Checking crontab access..."
crontab -l 2>/dev/null || echo "No crontab access"

echo "System cron files:"
ls -la /etc/cron* 2>/dev/null | head -10

echo ""
echo "--- Network-based Privilege Escalation ---"
echo "Checking network configuration..."
netstat -tulpn 2>/dev/null | head -10 || ss -tulpn 2>/dev/null | head -10

echo "Checking for privileged ports..."
netstat -tlpn 2>/dev/null | grep -E ":(22|80|443|8080)" || echo "No privileged ports detected"

echo ""
echo "--- Advanced Privilege Escalation Vectors ---"

# Check for container runtime sockets
echo "Checking for container runtime sockets..."
find /var/run -name "*.sock" 2>/dev/null | head -10

# Check for cloud metadata access
echo "Testing cloud metadata service access..."
curl -s -m 5 http://169.254.169.254/metadata/instance?api-version=2021-02-01 -H "Metadata: true" | head -c 200 2>/dev/null || echo "No cloud metadata access"

echo ""
echo "--- Persistence Mechanisms ---"
echo "Checking for persistence opportunities..."

# Check writable startup scripts
echo "Writable startup locations:"
find /etc/init.d /etc/systemd -writable 2>/dev/null | head -5

# Check user's home directory
echo "Home directory permissions:"
ls -la $HOME 2>/dev/null | head -5

echo ""
echo "=== PRIVILEGE ESCALATION SUMMARY ==="
echo "This simulation checked for:"
echo "1. SUID/SGID binaries for privilege escalation"
echo "2. Sudo misconfigurations"
echo "3. Dangerous capabilities"
echo "4. Container escape vectors (Docker socket, etc.)"
echo "5. Kubernetes service account abuse"
echo "6. Environment variable manipulation"
echo "7. Writable system files"
echo "8. Network-based escalation"
echo "9. Persistence mechanisms"
echo ""
echo "Real attackers use these techniques to gain root access!"
echo ""
echo "=== PRIVILEGE ESCALATION SIMULATION COMPLETED ==="