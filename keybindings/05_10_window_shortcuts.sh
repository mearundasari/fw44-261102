#!/usr/bin/env bash
# Title: Window Management Shortcuts
# Description: Configures window shortcuts (Super+Q / Alt+F4 to close, Super+D / Alt+F10 to maximize, Super+Shift+D for desktop).
# Sudo: false
set -eo pipefail

echo "Configuring window management shortcuts..."

# Close active window: Alt+F4, Super+Q
gsettings set org.gnome.desktop.wm.keybindings close "['<Alt>F4', '<Super>q']"

# Toggle maximized state: Alt+F10, Super+D
gsettings set org.gnome.desktop.wm.keybindings toggle-maximized "['<Alt>F10', '<Super>d']"

# Show desktop: Super+Shift+D
gsettings set org.gnome.desktop.wm.keybindings show-desktop "['<Super><Shift>d']"

echo "Window management shortcuts configured."
