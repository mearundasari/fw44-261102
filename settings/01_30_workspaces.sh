#!/usr/bin/env bash
# Title: Multi-Monitor Workspaces
# Description: Configures workspaces to span across all connected displays.
# Sudo: false
set -eo pipefail

echo "Configuring workspaces across all monitors..."
gsettings set org.gnome.mutter workspaces-only-on-primary false
echo "Multi-monitor workspaces configured."
