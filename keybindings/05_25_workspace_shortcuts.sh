#!/usr/bin/env bash
# Title: Workspace Navigation & Window Moving
# Description: Binds Super+1..9 to workspaces and Super+Shift+1..9 to move windows (frees default dock app switching).
# Sudo: false
set -eo pipefail

echo "Configuring workspace navigation and window moving shortcuts..."

# 1. Clear default app switching shortcuts (Super+1 through Super+9)
for i in {1..9}; do
  gsettings set org.gnome.shell.keybindings switch-to-application-$i "[]"
done

# 2. Bind Super+1 through Super+9 to switch to workspaces 1 through 9
for i in {1..9}; do
  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-$i "['<Super>$i']"
done

# 3. Move windows across workspaces
for i in {1..9}; do
  gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-$i "['<Super><Shift>$i']"
done

echo "Workspace navigation shortcuts configured successfully."
