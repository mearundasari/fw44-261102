#!/usr/bin/env bash
# Title: TablePlus Database Client
# Description: Downloads TablePlus modern database management AppImage to ~/.local/bin.
# Sudo: false
set -eo pipefail

BIN_DIR="$HOME/.local/bin"
TARGET_APPIMAGE="$BIN_DIR/TablePlus.AppImage"
URL="https://tableplus.com/release/linux/x64/TablePlus-x64.AppImage"

mkdir -p "$BIN_DIR"

echo "Downloading TablePlus AppImage..."
curl -L -o "$TARGET_APPIMAGE" "$URL"

chmod +x "$TARGET_APPIMAGE"
echo "TablePlus AppImage downloaded to $TARGET_APPIMAGE."
