#!/usr/bin/env bash
# Title: Disable Hot Corners
# Description: Disables top-left hot corner to prevent accidental trigger of Activities Overview.
# Sudo: false
set -eo pipefail

echo "Disabling GNOME hot corners..."
gsettings set org.gnome.desktop.interface enable-hot-corners false
echo "Hot corners disabled."
