#!/usr/bin/env bash
# Title: DNF Download Speedup & Fast Mirror Failover
# Description: Configures fastestmirror, max parallel downloads, and strict mirror timeouts in /etc/dnf/dnf.conf.
# Sudo: true
set -eo pipefail

CONF_FILE="/etc/dnf/dnf.conf"

echo "Configuring DNF package manager download optimizations..."

if [ ! -f "$CONF_FILE" ]; then
    echo "Creating $CONF_FILE..."
    sudo touch "$CONF_FILE"
fi

# Function to ensure a setting exists or update it
set_dnf_opt() {
    local key="$1"
    local val="$2"
    if grep -qiE "^[[:space:]]*${key}[[:space:]]*=" "$CONF_FILE"; then
        sudo sed -i -E "s|^[[:space:]]*${key}[[:space:]]*=.*|${key}=${val}|g" "$CONF_FILE"
    else
        echo "${key}=${val}" | sudo tee -a "$CONF_FILE" > /dev/null
    fi
}

set_dnf_opt "fastestmirror" "True"
set_dnf_opt "max_parallel_downloads" "10"
set_dnf_opt "minrate" "30k"
set_dnf_opt "timeout" "15"

echo "DNF configuration updated:"
grep -E "(fastestmirror|max_parallel_downloads|minrate|timeout)" "$CONF_FILE" || true
echo "DNF optimizations applied successfully."
