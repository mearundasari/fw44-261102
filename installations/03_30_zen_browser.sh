#!/usr/bin/env bash
# Title: Zen Browser
# Description: Installs Zen Browser via Flathub.
# Sudo: false
set -eo pipefail

echo "Configuring Flathub remote..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

echo "Installing Zen Browser..."
flatpak install -y --noninteractive flathub app.zen_browser.zen

echo "Zen Browser installed successfully."
