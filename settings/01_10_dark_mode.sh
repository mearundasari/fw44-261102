#!/usr/bin/env bash
# Title: Dark Mode
# Description: Switches GNOME shell and desktop applications to dark color scheme.
# Sudo: false
set -eo pipefail

echo "Enabling dark mode interface..."
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
echo "Dark mode set successfully."
