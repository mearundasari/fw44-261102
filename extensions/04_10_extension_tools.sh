#!/usr/bin/env bash
# Title: GNOME Extension Management Tools
# Description: Installs Extension Manager and GNOME Extensions apps via Flathub.
# Sudo: false
set -eo pipefail

echo "Configuring Flathub remote..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

echo "Installing Extension Manager & GNOME Extensions..."
flatpak install -y --noninteractive flathub com.mattjakeman.ExtensionManager org.gnome.Extensions

echo "Extension tools installed successfully."
