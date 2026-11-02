#!/usr/bin/env bash
# Runner script executed inside the terminal window
set -o pipefail

# ANSI Colors
C_RESET='\033[0m'
C_BOLD='\033[1m'
C_BLUE='\033[34m'
C_CYAN='\033[36m'
C_GREEN='\033[32m'
C_YELLOW='\033[33m'
C_RED='\033[31m'
C_MAGENTA='\033[35m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
STATE_MANAGER="$SCRIPT_DIR/state_manager.py"
LOCK_FILE="$SCRIPT_DIR/runner.lock"

# Input: File containing newline-separated paths to scripts
QUEUE_FILE="$1"

cleanup() {
    rm -f "$LOCK_FILE"
    if [ -n "$SUDO_KEEP_PID" ]; then
        kill "$SUDO_KEEP_PID" 2>/dev/null || true
    fi
}
trap cleanup EXIT

# Check for existing run
if [ -f "$LOCK_FILE" ]; then
    PREV_PID=$(cat "$LOCK_FILE" 2>/dev/null || true)
    if [ -n "$PREV_PID" ] && kill -0 "$PREV_PID" 2>/dev/null; then
        echo -e "${C_RED}[!] Error: Another setup process is currently running (PID $PREV_PID).${C_RESET}"
        read -rp "Press Enter to exit..."
        exit 1
    else
        rm -f "$LOCK_FILE"
    fi
fi
echo "$$" > "$LOCK_FILE"

if [ -z "$QUEUE_FILE" ] || [ ! -f "$QUEUE_FILE" ]; then
    echo -e "${C_RED}Error: Valid script queue file must be provided.${C_RESET}"
    read -rp "Press Enter to exit..."
    exit 1
fi

mapfile -t SCRIPTS < "$QUEUE_FILE"
TOTAL="${#SCRIPTS[@]}"

if [ "$TOTAL" -eq 0 ]; then
    echo -e "${C_YELLOW}No scripts selected to execute.${C_RESET}"
    read -rp "Press Enter to exit..."
    exit 0
fi

clear
echo -e "${C_BOLD}${C_CYAN}======================================================${C_RESET}"
echo -e "${C_BOLD}${C_CYAN}         Fedora Workstation Setup Runner              ${C_RESET}"
echo -e "${C_BOLD}${C_CYAN}======================================================${C_RESET}"
echo -e "Total items to execute: ${C_BOLD}${TOTAL}${C_RESET}"
echo -e "${C_MAGENTA}Tip: Press Ctrl+C at any time to skip a hanging task.${C_RESET}"
echo ""

# Check if any script requires sudo
NEEDS_SUDO=false
for s in "${SCRIPTS[@]}"; do
    if [ -f "$s" ] && grep -qiE '^[#[:space:]]*Sudo:[[:space:]]*true' "$s"; then
        NEEDS_SUDO=true
        break
    fi
done

if [ "$NEEDS_SUDO" = true ]; then
    echo -e "${C_YELLOW}[!] Elevated privileges are required for some tasks.${C_RESET}"
    echo -e "Please authenticate now with your sudo password:"
    if sudo -v; then
        echo -e "${C_GREEN}[✓] Authentication successful.${C_RESET}"
        # Keep sudo alive in background
        while true; do
            sudo -n true
            sleep 50
            kill -0 "$$" || exit
        done 2>/dev/null &
        SUDO_KEEP_PID=$!
    else
        echo -e "${C_RED}[✕] Sudo authentication failed. Aborting.${C_RESET}"
        read -rp "Press Enter to exit..."
        exit 1
    fi
    echo ""
fi

PASSED=0
FAILED=0
SKIPPED=0
declare -a FAILED_ITEMS=()
declare -a SKIPPED_ITEMS=()

START_TIME_ALL=$(date +%s)
INDEX=1

# Intercept SIGINT in the runner to handle skips
INTERRUPTED=0
trap 'INTERRUPTED=1' INT

for script_path in "${SCRIPTS[@]}"; do
    if [ ! -f "$script_path" ]; then
        echo -e "${C_RED}[✕] Script not found: $script_path${C_RESET}"
        ((FAILED++))
        FAILED_ITEMS+=("$script_path (Not Found)")
        ((INDEX++))
        continue
    fi

    REL_PATH="$(realpath --relative-to="$PROJECT_ROOT" "$script_path")"

    # Read Title if available
    TITLE=$(grep -iE '^[#[:space:]]*Title:' "$script_path" | head -n1 | sed -E 's/^[#[:space:]]*Title:[[:space:]]*//I')
    if [ -z "$TITLE" ]; then
        TITLE="$(basename "$script_path")"
    fi

    RETRY_TASK=true
    while [ "$RETRY_TASK" = true ]; do
        RETRY_TASK=false
        INTERRUPTED=0

        echo -e "${C_CYAN}------------------------------------------------------${C_RESET}"
        echo -e "${C_BOLD}[$INDEX/$TOTAL] Running: ${C_BLUE}${TITLE}${C_RESET}"
        echo -e "${C_BOLD}Path:${C_RESET} ${REL_PATH}"
        echo -e "${C_CYAN}------------------------------------------------------${C_RESET}"

        chmod +x "$script_path"
        
        T_START=$(date +%s)
        
        # Execute script
        bash "$script_path"
        EC=$?
        
        T_END=$(date +%s)
        ELAPSED=$((T_END - T_START))

        # Check if interrupted by Ctrl+C
        if [ "$EC" -eq 130 ] || [ "$INTERRUPTED" -eq 1 ]; then
            echo -e "\n${C_BOLD}${C_YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
            echo -e "${C_BOLD}${C_YELLOW}[!] TASK INTERRUPTED: ${TITLE}${C_RESET}"
            echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo -e "Options:"
            echo -e "  ${C_BOLD}[s]${C_RESET} Skip this task and proceed to next (default in 15s)"
            echo -e "  ${C_BOLD}[r]${C_RESET} Retry this task"
            echo -e "  ${C_BOLD}[q]${C_RESET} Quit setup entirely"
            echo -ne "${C_BOLD}Choice [s/r/q]: ${C_RESET}"

            CHOICE=""
            if [ -t 0 ]; then
                read -r -t 15 CHOICE </dev/tty || CHOICE="s"
            else
                CHOICE="s"
            fi
            echo ""

            case "${CHOICE,,}" in
                r|retry)
                    echo -e "${C_CYAN}[⟳] Retrying task: ${TITLE}...${C_RESET}\n"
                    RETRY_TASK=true
                    continue
                    ;;
                q|quit|abort)
                    echo -e "${C_RED}[✕] Aborting setup by user request.${C_RESET}"
                    python3 "$STATE_MANAGER" record "$REL_PATH" "skipped" 130 "$ELAPSED"
                    ((SKIPPED++))
                    SKIPPED_ITEMS+=("$TITLE")
                    break 2
                    ;;
                *)
                    echo -e "${C_YELLOW}[⏭] Skipping task: ${TITLE} (${ELAPSED}s)${C_RESET}\n"
                    python3 "$STATE_MANAGER" record "$REL_PATH" "skipped" 130 "$ELAPSED"
                    ((SKIPPED++))
                    SKIPPED_ITEMS+=("$TITLE")
                    ;;
            esac
        elif [ "$EC" -eq 0 ]; then
            echo -e "\n${C_GREEN}[✓] SUCCESS:${C_RESET} ${TITLE} (${ELAPSED}s)\n"
            python3 "$STATE_MANAGER" record "$REL_PATH" "success" 0 "$ELAPSED"
            ((PASSED++))
        else
            echo -e "\n${C_RED}[✕] FAILED:${C_RESET} ${TITLE} (Exit Code: $EC, ${ELAPSED}s)\n"
            python3 "$STATE_MANAGER" record "$REL_PATH" "failed" "$EC" "$ELAPSED"
            ((FAILED++))
            FAILED_ITEMS+=("$TITLE (code $EC)")
        fi
    done

    ((INDEX++))
done

END_TIME_ALL=$(date +%s)
TOTAL_TIME=$((END_TIME_ALL - START_TIME_ALL))

echo -e "${C_BOLD}${C_CYAN}======================================================${C_RESET}"
echo -e "${C_BOLD}${C_CYAN}                  Execution Summary                   ${C_RESET}"
echo -e "${C_BOLD}${C_CYAN}======================================================${C_RESET}"
echo -e "Total Tasks:  ${C_BOLD}$TOTAL${C_RESET}"
echo -e "Succeeded:    ${C_GREEN}${C_BOLD}$PASSED${C_RESET}"
if [ "$SKIPPED" -gt 0 ]; then
    echo -e "Skipped:      ${C_YELLOW}${C_BOLD}$SKIPPED${C_RESET}"
fi
if [ "$FAILED" -gt 0 ]; then
    echo -e "Failed:       ${C_RED}${C_BOLD}$FAILED${C_RESET}"
fi
echo -e "Total Time:   ${TOTAL_TIME}s"

if [ "${#SKIPPED_ITEMS[@]}" -gt 0 ]; then
    echo -e "\n${C_YELLOW}${C_BOLD}Skipped items (can be retried later in setup manager):${C_RESET}"
    for item in "${SKIPPED_ITEMS[@]}"; do
        echo -e "  - ${C_YELLOW}$item${C_RESET}"
    done
fi

if [ "${#FAILED_ITEMS[@]}" -gt 0 ]; then
    echo -e "\n${C_RED}${C_BOLD}Failed items:${C_RESET}"
    for item in "${FAILED_ITEMS[@]}"; do
        echo -e "  - ${C_RED}$item${C_RESET}"
    done
fi

echo -e "\n${C_GREEN}${C_BOLD}Setup finished! History has been saved.${C_RESET}"
echo ""
read -rp "Press Enter to close this window..."
