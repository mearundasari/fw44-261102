#!/usr/bin/env bash
# Title: App Launchers & Quick Access
# Description: Configures Super+Return for Terminal, Alt+Space for Vicinae, Super+E for Files, Super+I for Settings.
# Sudo: false
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_HELPER="$SCRIPT_DIR/../resources/common.sh"

if [ -f "$COMMON_HELPER" ]; then
    source "$COMMON_HELPER"
else
    echo "Warning: common.sh helper not found. Custom keybinding helpers may fail."
fi

echo "Configuring application launcher shortcuts..."

# Settings: Super+I
gsettings set org.gnome.settings-daemon.plugins.media-keys control-center "['<Super>i']"

# Nautilus (Files): Super+E
gsettings set org.gnome.settings-daemon.plugins.media-keys home "['<Super>e']"

# Free Alt+Space by unbinding window menu
gsettings set org.gnome.desktop.wm.keybindings activate-window-menu "[]"

# Custom Keybinding: Vicinae Launcher -> Alt+Space
if command -v add_custom_keybinding &>/dev/null; then
    add_custom_keybinding "Vicinae Launcher" "vicinae open" "<Alt>space"
    add_custom_keybinding "Ptyxis Terminal" "ptyxis --new-window" "<Super>Return"
else
    echo "Skipping custom keybindings: add_custom_keybinding function missing."
fi

echo "Application launcher shortcuts configured."
