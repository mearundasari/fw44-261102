#!/usr/bin/env bash
# Title: Shell Navigation Shortcuts
# Description: Configures Overview (Super+Tab), App Switcher (Alt+Tab), Grid (Super+S), Quick Settings (Super+A), and Notifications (Super+N).
# Sudo: false
set -eo pipefail

echo "Configuring GNOME Shell navigation shortcuts..."

# App switcher to Alt+Tab so Super+Tab is free for Overview
gsettings set org.gnome.desktop.wm.keybindings switch-applications "['<Alt>Tab']"

# Free Super+N by clearing focus-active-notification
gsettings set org.gnome.shell.keybindings focus-active-notification "@as []"

# Quick Settings panel: Super+A
gsettings set org.gnome.shell.keybindings toggle-quick-settings "['<Super>a']"

# Notifications & Calendar tray: Super+N
gsettings set org.gnome.shell.keybindings toggle-message-tray "['<Super>n']"

# Activities Overview: Super+Tab
gsettings set org.gnome.shell.keybindings toggle-overview "['<Super>Tab']"

# Application View (Grid): Super+S
gsettings set org.gnome.shell.keybindings toggle-application-view "['<Super>s']"

echo "Shell navigation shortcuts configured."
