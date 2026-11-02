#!/usr/bin/env bash
# Title: KDE Connect & Nautilus Integration
# Description: Installs KDE Connect and its Nautilus file-sharing integration for phone-PC sync.
# Sudo: true
set -eo pipefail

echo "Installing KDE Connect packages..."
sudo dnf install -y kde-connect kde-connect-nautilus

echo "KDE Connect installed successfully."
