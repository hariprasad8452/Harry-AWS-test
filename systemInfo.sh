#!/bin/bash

# Get system information
echo "===== SYSTEM INFORMATION ====="
echo "Hostname: $(hostname)"
echo "OS: $(uname -o)"
echo "Kernel: $(uname -r)"
echo "Uptime: $(uptime -p)"
echo "CPU: $(lscpu | grep 'Model name' | awk -F: '{print $2}' | xargs)"
echo "Total RAM: $(free -h | awk '/Mem:/ {print $2}')"
echo "Total Swap: $(free -h | awk '/Swap:/ {print $2}')"
echo "--------------------------------"

# Function to check usage and print health
check_health() {
    local usage=$1
    local resource=$2

    if (( $(echo "$usage > 75" | bc -l) )); then
        status="Healthy"
    elif (( $(echo "$usage >= 50" | bc -l) )); then
        status="Moderate"
    else
        status="Not Healthy"
    fi
    printf "%-15s : %-8s (%s%% used)\n" "$resource" "$status" "$usage"
}

# Get storage usage (root partition)
disk_usage=$(df / | awk 'END{print $5}' | tr -d '%')
check_health "$disk_usage" "Disk(/)"

# Get RAM usage
mem_total=$(free | awk '/Mem:/ {print $2}')
mem_used=$(free | awk '/Mem:/ {print $3}')
mem_usage=$(awk "BEGIN {printf \"%.2f\", ($mem_used/$mem_total)*100}")
check_health "$mem_usage" "RAM"

# Get Swap usage
swap_total=$(free | awk '/Swap:/ {print $2}')
swap_used=$(free | awk '/Swap:/ {print $3}')
if [ "$swap_total" -gt 0 ]; then
    swap_usage=$(awk "BEGIN {printf \"%.2f\", ($swap_used/$swap_total)*100}")
else
    swap_usage=0
fi
check_health "$swap_usage" "Swap"

# Get CPU usage (average in last 1 minute)
cpu_idle=$(top -bn1 | grep "Cpu(s)" | awk '{print $8}' | cut -d'.' -f1)
cpu_usage=$((100 - cpu_idle))
check_health "$cpu_usage" "CPU"

echo "--------------------------------"
