#!/usr/bin/env bash
# Title: JetBrains Mono Nerd Font
# Description: Downloads JetBrains Mono Nerd Font, refreshes font cache, and sets as GNOME monospace font.
# Sudo: false
set -eo pipefail

FONT_DIR="$HOME/.local/share/fonts/JetBrainsMonoNerd"
TMP_ARCHIVE="/tmp/JetBrainsMono.tar.xz"
FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz"

echo "Creating font directory: $FONT_DIR..."
mkdir -p "$FONT_DIR"

echo "Downloading JetBrainsMono Nerd Font archive..."
curl -fL "$FONT_URL" -o "$TMP_ARCHIVE"

echo "Extracting font files..."
tar -xf "$TMP_ARCHIVE" -C "$FONT_DIR"
rm -f "$TMP_ARCHIVE"

echo "Refreshing font cache..."
fc-cache -f "$HOME/.local/share/fonts"

echo "Setting GNOME monospace font..."
gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 10'

echo "JetBrains Mono Nerd Font successfully installed and configured."
