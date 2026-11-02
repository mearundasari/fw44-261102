#!/usr/bin/env bash
# Title: AppIndicator and KStatusNotifierItem Support
# Description: Installs system tray icon support extension via DNF and enables it.
# Sudo: true
set -eo pipefail

echo "Installing AppIndicator extension package..."
sudo dnf install -y gnome-shell-extension-appindicator

echo "Enabling AppIndicator extension in GNOME Shell..."
gnome-extensions enable appindicatorsupport@rgcjonas.gmail.com || true

echo "AppIndicator extension configured."
