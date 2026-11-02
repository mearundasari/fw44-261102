#!/usr/bin/env bash
# Common helper functions for Fedora Workstation Setup

# Colors
C_RESET='\033[0m'
C_BOLD='\033[1m'
C_BLUE='\033[34m'
C_GREEN='\033[32m'
C_YELLOW='\033[33m'
C_RED='\033[31m'
C_CYAN='\033[36m'

log_info() {
    echo -e "${C_BLUE}${C_BOLD}[INFO]${C_RESET} $*"
}

log_success() {
    echo -e "${C_GREEN}${C_BOLD}[OK]${C_RESET} $*"
}

log_warn() {
    echo -e "${C_YELLOW}${C_BOLD}[WARN]${C_RESET} $*"
}

log_error() {
    echo -e "${C_RED}${C_BOLD}[ERROR]${C_RESET} $*"
}

# Function to add or update a custom keybinding safely in GNOME dconf
add_custom_keybinding() {
    local name="$1"
    local command="$2"
    local binding="$3"
    local base_schema="org.gnome.settings-daemon.plugins.media-keys"
    local sub_schema="${base_schema}.custom-keybinding"

    # Check if a binding with this name already exists
    local path_key=""
    local entries
    entries=$(dconf list /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/ 2>/dev/null || true)

    for entry in $entries; do
        local check_path="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/${entry}"
        local entry_name
        entry_name=$(dconf read "${check_path}name" 2>/dev/null || true)
        if [ "$entry_name" = "'$name'" ]; then
            path_key="$check_path"
            break
        fi
    done

    # If not found, find next available index
    if [ -z "$path_key" ]; then
        local idx=0
        while dconf list /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/ 2>/dev/null | grep -q "^custom${idx}/$"; do
            idx=$((idx + 1))
        done
        path_key="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${idx}/"
    fi

    # Fetch current custom-keybindings list from gsettings
    local current
    current=$(gsettings get "$base_schema" custom-keybindings 2>/dev/null || echo "@as []")

    # Append path_key if not already registered
    if [[ "$current" == "@as []" || -z "$current" || "$current" == "[]" ]]; then
        gsettings set "$base_schema" custom-keybindings "['$path_key']"
    elif ! echo "$current" | grep -Fq "'$path_key'"; then
        local updated
        updated="${current%]*}, '$path_key']"
        gsettings set "$base_schema" custom-keybindings "$updated"
    fi

    # Assign attributes
    gsettings set "${sub_schema}:${path_key}" name "$name"
    gsettings set "${sub_schema}:${path_key}" command "$command"
    gsettings set "${sub_schema}:${path_key}" binding "$binding"

    log_success "Bound '${name}' -> ${binding} (${command})"
}
