#!/usr/bin/env bash
# Title: LocalSend
# Description: Installs LocalSend cross-platform open source local network file-sharing tool.
# Sudo: false
set -eo pipefail

echo "Configuring Flathub remote..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

echo "Installing LocalSend..."
flatpak install -y --noninteractive flathub localsend

echo "LocalSend installed successfully."
