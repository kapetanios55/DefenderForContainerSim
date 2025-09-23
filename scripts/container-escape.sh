#!/bin/bash

# Enhanced Container Escape Simulation
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

echo "=== ENHANCED CONTAINER ESCAPE SIMULATION ==="
echo "Attempting various container escape techniques..."
echo ""

echo "--- Checking Container Runtime ---"
if [ -f /.dockerenv ]; then
    echo "✓ Running in Docker container"
elif [ -f /run/.containerenv ]; then
    echo "✓ Running in Podman container"
else
    echo "✓ Running in container (runtime unknown)"
fi
echo ""

echo "--- Filesystem Escape Attempts ---"
echo "Checking for sensitive host mounts..."

# Check for Docker socket mount
if [ -S /var/run/docker.sock ]; then
    echo "⚠️  Docker socket mounted - potential escape vector!"
    echo "Attempting Docker socket exploitation..."
    if command -v docker >/dev/null 2>&1; then
        echo "Docker client available, attempting container creation..."
        # This would be dangerous in a real scenario
        echo "docker run --rm -it --privileged --pid=host alpine nsenter -t 1 -m -u -n -i sh"
    fi
fi

# Check for host filesystem mounts
echo "Checking for host filesystem mounts..."
mount | grep -E "(hostfs|host|proc|sys)" || echo "No obvious host mounts found"

# Check for /proc access
echo "Checking /proc filesystem access..."
if [ -r /proc/version ]; then
    echo "Host kernel version: $(cat /proc/version | head -c 100)..."
fi

echo ""
echo "--- Privilege Escalation Checks ---"

# Check current capabilities
echo "Current capabilities:"
if command -v capsh >/dev/null 2>&1; then
    capsh --print
elif [ -f /proc/self/status ]; then
    grep Cap /proc/self/status
fi

# Check for setuid binaries
echo "Searching for setuid binaries..."
find / -perm -4000 -type f 2>/dev/null | head -10

echo ""
echo "--- Kernel Exploits ---"
echo "Checking for known vulnerable kernel versions..."
kernel_version=$(uname -r)
echo "Kernel version: $kernel_version"

# Simulate checking for known CVEs (this is educational)
echo "Simulating CVE checks for kernel exploits..."
echo "- CVE-2022-0847 (Dirty Pipe): Checking..."
echo "- CVE-2021-3156 (sudo): Checking..."
echo "- CVE-2019-13272 (ptrace): Checking..."

echo ""
echo "--- Resource Access Attempts ---"

# Try to access host processes
echo "Attempting to access host processes..."
if [ -d /proc/1 ]; then
    echo "PID 1 accessible - checking cmdline:"
    cat /proc/1/cmdline 2>/dev/null | tr '\0' ' ' || echo "Access denied"
fi

# Check for container runtime info
echo "Container runtime information:"
if [ -f /proc/1/cgroup ]; then
    cat /proc/1/cgroup | head -5
fi

echo ""
echo "--- Network Escape Attempts ---"
echo "Checking network configuration..."
ip addr show 2>/dev/null | grep -E "(inet|link)" | head -10

# Check for host network access
echo "Testing host network access..."
if [ -f /proc/net/route ]; then
    echo "Route table accessible"
    cat /proc/net/route | head -5
fi

echo ""
echo "--- Advanced Escape Techniques ---"

# Check for cgroup manipulation
echo "Cgroup manipulation attempts..."
if [ -d /sys/fs/cgroup ]; then
    echo "Cgroup filesystem accessible"
    ls -la /sys/fs/cgroup/ 2>/dev/null | head -5
fi

# Check for namespace information
echo "Namespace information:"
if [ -d /proc/self/ns ]; then
    ls -la /proc/self/ns/
fi

echo ""
echo "--- Container Breakout Summary ---"
echo "This simulation demonstrates various container escape techniques:"
echo "1. Docker socket access (if mounted)"
echo "2. Host filesystem access (if mounted)"
echo "3. Privilege escalation via capabilities"
echo "4. Kernel exploit simulation"
echo "5. Process namespace access"
echo "6. Network namespace manipulation"
echo "7. Cgroup manipulation"
echo ""
echo "Real attackers would exploit these to gain host access!"
echo ""
echo "=== CONTAINER ESCAPE SIMULATION COMPLETED ==="