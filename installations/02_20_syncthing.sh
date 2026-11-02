#!/usr/bin/env bash
# Title: Syncthing
# Description: Installs continuous file synchronization service via DNF.
# Sudo: true
set -eo pipefail

echo "Installing Syncthing..."
sudo dnf install -y syncthing

echo "Syncthing installed successfully."
