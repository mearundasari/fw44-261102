#!/usr/bin/env bash
# Title: Vicinae GNOME Extension
# Description: Downloads and installs the Vicinae GNOME Shell extension for launcher integration.
# Sudo: false
set -eo pipefail

echo "Resolving latest Vicinae GNOME extension release..."

TMP_ZIP=$(mktemp --suffix=.zip)
cleanup() {
    rm -f "$TMP_ZIP"
}
trap cleanup EXIT

# Fetch the latest zip download URL from GitHub API
DOWNLOAD_URL=$(curl -fsSL https://api.github.com/repos/vicinaehq/gnome-extension/releases/latest | jq -r '.assets[] | select(.name | endswith(".zip")) | .browser_download_url' | head -n1)

if [ -z "$DOWNLOAD_URL" ] || [ "$DOWNLOAD_URL" = "null" ]; then
    echo "Warning: Failed to query GitHub API for release assets. Falling back to default release asset..."
    DOWNLOAD_URL="https://github.com/vicinaehq/gnome-extension/releases/download/v1.8.1/vicinae%40dagimg-dot.shell-extension-v1.8.1.zip"
fi

echo "Downloading Vicinae GNOME extension from: $DOWNLOAD_URL"
curl -fsSL "$DOWNLOAD_URL" -o "$TMP_ZIP"

# Extract UUID from metadata.json inside the zip
UUID=$(unzip -p "$TMP_ZIP" metadata.json 2>/dev/null | jq -r '.uuid // empty')
if [ -z "$UUID" ]; then
    UUID="vicinae@dagimg-dot"
fi

echo "Installing extension ($UUID)..."
TARGET_DIR="$HOME/.local/share/gnome-shell/extensions/${UUID}"
mkdir -p "$TARGET_DIR"
unzip -qo "$TMP_ZIP" -d "$TARGET_DIR"

# Compile schemas if present
if [ -d "$TARGET_DIR/schemas" ]; then
    glib-compile-schemas "$TARGET_DIR/schemas"
fi

echo "Enabling Vicinae extension ($UUID)..."
gnome-extensions enable "$UUID" || true

# Register in GSettings enabled-extensions list
python3 -c "
import subprocess, ast
uuid = '$UUID'
try:
    raw = subprocess.check_output(['gsettings', 'get', 'org.gnome.shell', 'enabled-extensions']).decode().strip()
    curr = ast.literal_eval(raw.replace('@as ', ''))
    if uuid not in curr:
        curr.append(uuid)
        subprocess.run(['gsettings', 'set', 'org.gnome.shell', 'enabled-extensions', str(curr)], check=True)
except Exception as e:
    pass
"

echo "Vicinae extension ($UUID) installed and enabled successfully."
