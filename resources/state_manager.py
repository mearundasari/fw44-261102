#!/usr/bin/env python3
"""
State manager for Fedora Workstation Setup.
Tracks execution history, task status (success, failed, skipped), and timestamps.
"""

import json
import sys
from datetime import datetime
from pathlib import Path

RESOURCES_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = RESOURCES_DIR.parent
STATE_FILE = RESOURCES_DIR / "state.json"


def load_state() -> dict:
    if not STATE_FILE.exists():
        return {"last_run": None, "history": {}}
    try:
        with open(STATE_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception as e:
        print(f"Warning: Failed to load state file: {e}", file=sys.stderr)
        return {"last_run": None, "history": {}}


def save_state(state: dict):
    try:
        with open(STATE_FILE, "w", encoding="utf-8") as f:
            json.dump(state, f, indent=2)
    except Exception as e:
        print(f"Error: Failed to save state file: {e}", file=sys.stderr)


def record_task(script_rel: str, status: str, exit_code: int = 0, duration: float = 0.0):
    state = load_state()
    now_iso = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    state["last_run"] = now_iso
    state.setdefault("history", {})[script_rel] = {
        "status": status,  # "success", "failed", "skipped"
        "exit_code": int(exit_code),
        "last_executed": now_iso,
        "duration": round(float(duration), 1),
    }
    save_state(state)


def get_task_status(script_rel: str) -> dict:
    state = load_state()
    return state.get("history", {}).get(script_rel, None)


def clear_history():
    save_state({"last_run": None, "history": {}})


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: state_manager.py <command> [args...]")
        sys.exit(1)

    cmd = sys.argv[1]
    if cmd == "record":
        if len(sys.argv) < 6:
            print("Usage: state_manager.py record <script_rel> <status> <exit_code> <duration>")
            sys.exit(1)
        record_task(sys.argv[2], sys.argv[3], int(sys.argv[4]), float(sys.argv[5]))
    elif cmd == "clear":
        clear_history()
        print("History cleared.")
    else:
        print(f"Unknown command: {cmd}")
        sys.exit(1)
