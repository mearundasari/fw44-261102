#!/usr/bin/env bash
# Helper script to install and enable extensions from extensions.gnome.org
set -eo pipefail

if [ -z "$1" ]; then
    echo "Usage: $(basename "$0") <extension-id-or-uuid>"
    echo "Example: $(basename "$0") 1460"
    echo "Example: $(basename "$0") Vitals@CoreCoding.com"
    exit 1
fi

TARGET_IDENTIFIER="$1"

# Check required dependencies
for cmd in curl jq unzip gnome-shell python3; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "Error: Required command '$cmd' is not installed."
        exit 1
    fi
done

# Detect GNOME Shell major version
SHELL_VER=$(gnome-shell --version | grep -oP '\d+' | head -n 1)
echo "==> Detected GNOME Shell version: $SHELL_VER"

# Query extensions.gnome.org API based on input type (Numeric ID vs UUID)
if [[ "$TARGET_IDENTIFIER" =~ ^[0-9]+$ ]]; then
    API_URL="https://extensions.gnome.org/extension-info/?pk=${TARGET_IDENTIFIER}"
else
    API_URL="https://extensions.gnome.org/extension-info/?uuid=${TARGET_IDENTIFIER}"
fi

echo "==> Fetching extension metadata..."
EXT_INFO=$(curl -sL "$API_URL")

# Validate response
if [ -z "$EXT_INFO" ] || [ "$(echo "$EXT_INFO" | jq -r 'type')" != "object" ]; then
    echo "Error: Failed to fetch metadata for '$TARGET_IDENTIFIER'."
    exit 1
fi

UUID=$(echo "$EXT_INFO" | jq -r '.uuid // empty')
NAME=$(echo "$EXT_INFO" | jq -r '.name // empty')

if [ -z "$UUID" ]; then
    echo "Error: Extension not found for '$TARGET_IDENTIFIER'."
    exit 1
fi

echo "==> Found: $NAME ($UUID)"

# Select the version tag for the current Shell version, or fallback to latest available release
VERSION_TAG=$(echo "$EXT_INFO" | jq -r --arg v "$SHELL_VER" '
  if .shell_version_map[$v] then
    .shell_version_map[$v].pk
  else
    (.shell_version_map | to_entries | sort_by(.value.version | tonumber) | last.value.pk)
  end
')

if [ -z "$VERSION_TAG" ] || [ "$VERSION_TAG" = "null" ]; then
    echo "Error: Could not resolve a compatible download version for $UUID."
    exit 1
fi

DOWNLOAD_URL="https://extensions.gnome.org/download-extension/${UUID}.shell-extension.zip?version_tag=${VERSION_TAG}"
TARGET_DIR="$HOME/.local/share/gnome-shell/extensions/${UUID}"
TMP_ZIP=$(mktemp --suffix=.zip)

echo "==> Downloading extension package..."
curl -sL "$DOWNLOAD_URL" -o "$TMP_ZIP"

echo "==> Extracting to $TARGET_DIR..."
mkdir -p "$TARGET_DIR"
unzip -qo "$TMP_ZIP" -d "$TARGET_DIR"
rm -f "$TMP_ZIP"

# Compile GSettings schemas if present
if [ -d "$TARGET_DIR/schemas" ]; then
    echo "==> Compiling GSettings schemas..."
    glib-compile-schemas "$TARGET_DIR/schemas"
fi

# Register in GSettings enabled-extensions list
echo "==> Enabling extension in GSettings..."
python3 -c "
import subprocess, ast
uuid = '$UUID'
raw = subprocess.check_output(['gsettings', 'get', 'org.gnome.shell', 'enabled-extensions']).decode().strip()
curr = ast.literal_eval(raw.replace('@as ', ''))
if uuid not in curr:
    curr.append(uuid)
    subprocess.run(['gsettings', 'set', 'org.gnome.shell', 'enabled-extensions', str(curr)])
"

echo "==> Successfully installed and enabled $NAME ($UUID)."
