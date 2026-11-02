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

# Configuration
GITHUB_USER="mearundasari"
GITHUB_REPO="fw44-261102"
BRANCH="main"

TARGET_DIR="$HOME/fedora_workstation_setup"
TARBALL_URL="https://github.com/${GITHUB_USER}/${GITHUB_REPO}/archive/refs/heads/${BRANCH}.tar.gz"
GIT_URL="https://github.com/${GITHUB_USER}/${GITHUB_REPO}.git"

echo -e "${C_BOLD}${C_CYAN}======================================================${C_RESET}"
echo -e "${C_BOLD}${C_CYAN}       Fedora Workstation Setup - Bootstrapper        ${C_RESET}"
echo -e "${C_BOLD}${C_CYAN}======================================================${C_RESET}"
echo ""

# Download repository files
echo -e "${C_BOLD}[1/3]${C_RESET} Fetching setup repository..."

if [ -d "$TARGET_DIR/.git" ]; then
    echo -e "Existing git repository found. Pulling latest updates..."
    git -C "$TARGET_DIR" pull --ff-only 2>/dev/null || true
elif command -v git &>/dev/null && [ ! -d "$TARGET_DIR" ]; then
    echo -e "Cloning repository via git..."
    git clone --depth 1 -b "$BRANCH" "$GIT_URL" "$TARGET_DIR"
else
    echo -e "Downloading and extracting archive..."
    mkdir -p "$TARGET_DIR"
    curl -fsSL "$TARBALL_URL" | tar -xzf - -C "$TARGET_DIR" --strip-components=1
fi

echo -e "${C_GREEN}[✓] Setup files ready in: ${TARGET_DIR}${C_RESET}"

# Ensure execution permissions
echo -e "${C_BOLD}[2/3]${C_RESET} Configuring execution permissions..."
chmod +x "$TARGET_DIR"/main.sh "$TARGET_DIR"/main.py "$TARGET_DIR"/resources/*.sh "$TARGET_DIR"/*/*.sh 2>/dev/null || true
echo -e "${C_GREEN}[✓] Permissions verified.${C_RESET}"

# Launch main setup
echo -e "${C_BOLD}[3/3]${C_RESET} Launching Workstation Setup GUI..."
echo ""
cd "$TARGET_DIR"
exec ./main.sh "$@"
