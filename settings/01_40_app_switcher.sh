#!/usr/bin/env bash
# Title: Workspace-Isolated App Switcher
# Description: Configures Alt+Tab application switcher to only show apps on the current workspace.
# Sudo: false
set -eo pipefail

echo "Configuring App Switcher for current workspace only..."
gsettings set org.gnome.shell.app-switcher current-workspace-only true
echo "App switcher configured."
