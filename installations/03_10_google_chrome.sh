#!/usr/bin/env bash
# Title: Google Chrome
# Description: Enables Fedora third-party Chrome repository and installs Google Chrome Stable.
# Sudo: true
set -eo pipefail

echo "Enabling Fedora workstation third-party repositories..."
sudo dnf install -y fedora-workstation-repositories

echo "Enabling Google Chrome repository..."
sudo dnf config-manager setopt google-chrome.enabled=1

echo "Installing Google Chrome Stable..."
sudo dnf install -y google-chrome-stable

echo "Google Chrome installed successfully."
