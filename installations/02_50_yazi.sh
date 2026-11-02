#!/usr/bin/env bash
# Title: Yazi Terminal File Manager
# Description: Enables lihaohong/yazi COPR repository and installs blazing-fast Yazi file manager.
# Sudo: true
set -eo pipefail

echo "Enabling COPR repository: lihaohong/yazi..."
sudo dnf copr enable -y lihaohong/yazi

echo "Installing Yazi..."
sudo dnf install -y yazi

echo "Yazi installed successfully."
