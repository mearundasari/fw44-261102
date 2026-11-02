#!/usr/bin/env bash
# Title: Obsidian
# Description: Installs Obsidian markdown knowledge-base and note-taking app via Flathub.
# Sudo: false
set -eo pipefail

echo "Configuring Flathub remote..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

echo "Installing Obsidian..."
flatpak install -y --noninteractive flathub md.obsidian.Obsidian

echo "Obsidian installed successfully."
