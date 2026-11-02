#!/usr/bin/env bash
# Fedora Workstation Setup Launcher
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Verify python3
if ! command -v python3 &>/dev/null; then
    echo "Error: python3 is required but not installed." >&2
    exit 1
fi

# Verify PyGObject and Libadwaita
if ! python3 -c "import gi; gi.require_version('Gtk', '4.0'); gi.require_version('Adw', '1'); from gi.repository import Gtk, Adw" &>/dev/null; then
    echo "Required GNOME/GTK dependencies missing. Installing python3-gobject and libadwaita..." >&2
    sudo dnf install -y python3-gobject libadwaita
fi

exec python3 "$SCRIPT_DIR/main.py" "$@"
