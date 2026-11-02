#!/usr/bin/env bash
# Title: Tailscale
# Description: Installs the Tailscale mesh VPN client and daemon via DNF.
# Sudo: true
set -eo pipefail

echo "Installing Tailscale..."
sudo dnf install -y tailscale

echo "Enabling Tailscale service..."
sudo systemctl enable tailscaled.service || true

echo "Tailscale installed successfully."
