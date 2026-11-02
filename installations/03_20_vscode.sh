#!/usr/bin/env bash
# Title: Visual Studio Code
# Description: Imports Microsoft GPG key, configures VS Code RPM repository, and installs code.
# Sudo: true
set -eo pipefail

echo "Importing Microsoft RPM GPG key..."
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc

echo "Configuring VS Code repository..."
sudo tee /etc/yum.repos.d/vscode.repo > /dev/null <<'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

echo "Installing Visual Studio Code..."
sudo dnf install -y code

echo "Visual Studio Code installed successfully."
