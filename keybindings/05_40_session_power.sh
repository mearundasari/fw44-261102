#!/usr/bin/env bash
# Title: Session & Power Shortcuts
# Description: Configures chords for Logout (Ctrl+Alt+Del), Power Off prompt, and Reboot prompt.
# Sudo: false
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_HELPER="$SCRIPT_DIR/../resources/common.sh"

if [ -f "$COMMON_HELPER" ]; then
    source "$COMMON_HELPER"
fi

echo "Configuring session and power shortcuts..."

# Logout prompt: Ctrl+Alt+Del, Super+Ctrl+Shift+Alt+M
gsettings set org.gnome.settings-daemon.plugins.media-keys logout "['<Control><Alt>Delete', '<Super><Control><Shift><Alt>m']"

# Power off prompt: Super+Ctrl+Shift+Alt+.
gsettings set org.gnome.settings-daemon.plugins.media-keys power "['<Super><Control><Shift><Alt>period']"

# Reboot prompt: Super+Ctrl+Shift+Alt+/
if command -v add_custom_keybinding &>/dev/null; then
    add_custom_keybinding "Reboot" "gnome-session-quit --reboot" "<Super><Control><Shift><Alt>slash"
fi

echo "Session and power shortcuts configured."
