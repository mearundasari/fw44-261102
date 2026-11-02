#!/usr/bin/env bash
# Title: Vicinae App Launcher
# Description: Enables quadratech188/vicinae COPR repository and installs Vicinae launcher.
# Sudo: true
set -eo pipefail

echo "Enabling COPR repository: quadratech188/vicinae..."
sudo dnf copr enable -y quadratech188/vicinae

echo "Installing Vicinae..."
sudo dnf install -y vicinae

echo "Vicinae installed successfully."
