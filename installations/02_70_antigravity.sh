#!/usr/bin/env bash
# Title: Google Antigravity CLI
# Description: Installs Antigravity command line interface agent.
# Sudo: false
set -eo pipefail

echo "Installing Antigravity CLI..."
curl -fsSL https://antigravity.google/cli/install.sh | bash

echo "Antigravity CLI setup completed."
