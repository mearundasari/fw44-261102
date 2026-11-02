#!/usr/bin/env bash
# Title: Flatseal
# Description: Installs Flatseal graphical Flatpak permission manager via Flathub.
# Sudo: false
set -eo pipefail

echo "Configuring Flathub remote..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

echo "Installing Flatseal..."
flatpak install -y --noninteractive flathub com.github.tchx84.Flatseal

echo "Flatseal installed successfully."
