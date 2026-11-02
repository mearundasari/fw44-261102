#!/usr/bin/env bash
# Title: Kitty Terminal
# Description: Installs Kitty fast, feature-rich, GPU-based terminal emulator.
# Sudo: true
set -eo pipefail

echo "Installing Kitty..."
sudo dnf install -y kitty

echo "Kitty installed successfully."
