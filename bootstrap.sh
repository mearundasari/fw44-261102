#!/usr/bin/env bash
# Fedora Workstation Setup - Bootstrap Installer
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/mearundasari/fw44-261102/main/bootstrap.sh | bash
set -eo pipefail

# ANSI Colors
C_RESET='\033[0m'
C_BOLD='\033[1m'
C_CYAN='\033[36m'
C_GREEN='\033[32m'
C_YELLOW='\033[33m'
C_RED='\033[31m'

# ==============================================================================
# CONFIGURATION
GITHUB_USER="${GITHUB_USER:-mearundasari}"
GITHUB_REPO="${GITHUB_REPO:-fw44-261102}"
BRANCH="${BRANCH:-main}"
# ==============================================================================

# Re-open terminal input if script is piped from curl
if [ ! -t 0 ] && [ -e /dev/tty ]; then
    exec </dev/tty
fi

clear
echo -e "${C_BOLD}${C_CYAN}======================================================${C_RESET}"
echo -e "${C_BOLD}${C_CYAN}       Fedora Workstation Setup - Bootstrapper        ${C_RESET}"
echo -e "${C_BOLD}${C_CYAN}======================================================${C_RESET}"
echo ""

# Ensure user replaced the placeholder username
if [ "$GITHUB_USER" = "YOUR_GITHUB_USERNAME" ]; then
    echo -e "${C_YELLOW}Please enter your GitHub username (or set GITHUB_USER env var):${C_RESET}"
    read -rp "GitHub Username: " GITHUB_USER
    if [ -z "$GITHUB_USER" ]; then
        echo -e "${C_RED}Error: GitHub username cannot be empty.${C_RESET}"
        exit 1
    fi
fi

TARGET_DIR="$HOME/fedora_workstation_setup"
TARBALL_URL="https://github.com/${GITHUB_USER}/${GITHUB_REPO}/archive/refs/heads/${BRANCH}.tar.gz"
GIT_URL="https://github.com/${GITHUB_USER}/${GITHUB_REPO}.git"

echo -e "${C_BOLD}[1/4]${C_RESET} Preparing target directory: ${C_CYAN}${TARGET_DIR}${C_RESET}..."
if [ -d "$TARGET_DIR" ]; then
    echo -e "Target directory already exists."
    read -rp "Do you want to overwrite it? [y/N]: " CONFIRM
    if [[ "${CONFIRM,,}" =~ ^(y|yes)$ ]]; then
        rm -rf "$TARGET_DIR"
        mkdir -p "$TARGET_DIR"
    else
        echo -e "Using existing directory without re-downloading."
    fi
else
    mkdir -p "$TARGET_DIR"
fi

# Download repository files
if [ ! -f "$TARGET_DIR/main.py" ]; then
    echo -e "${C_BOLD}[2/4]${C_RESET} Downloading setup repository..."
    if command -v git &>/dev/null; then
        echo -e "Cloning repository with git..."
        git clone --depth 1 -b "$BRANCH" "$GIT_URL" "$TARGET_DIR"
    else
        echo -e "Downloading tarball archive..."
        TMP_TAR=$(mktemp --suffix=.tar.gz)
        curl -fsSL "$TARBALL_URL" -o "$TMP_TAR"
        tar -xzf "$TMP_TAR" -C "$TARGET_DIR" --strip-components=1
        rm -f "$TMP_TAR"
    fi
    echo -e "${C_GREEN}[✓] Download complete.${C_RESET}"
else
    echo -e "${C_BOLD}[2/4]${C_RESET} Setup files already present."
fi

echo -e "${C_BOLD}[3/4]${C_RESET} Setting permissions..."
chmod +x "$TARGET_DIR"/main.sh "$TARGET_DIR"/main.py "$TARGET_DIR"/resources/*.sh "$TARGET_DIR"/*/*.sh 2>/dev/null || true
echo -e "${C_GREEN}[✓] Permissions verified.${C_RESET}"

echo -e "${C_BOLD}[4/4]${C_RESET} Launching Workstation Setup GUI..."
echo ""
cd "$TARGET_DIR"
exec ./main.sh
