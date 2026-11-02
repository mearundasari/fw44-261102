# Fedora Workstation Setup

A modular, extensible post-installation setup utility for Fedora Workstation (GNOME) built with **Python 3**, **GTK 4**, and **Libadwaita**.

---

## Directory Structure

```text
.
├── main.py                     # Libadwaita GTK 4 application
├── main.sh                     # Shell launcher wrapper
├── README.md                   # Documentation & usage guide
├── resources/                  # Shared libraries, runner & state tracking
│   ├── common.sh               # Reusable bash helpers (logging, keybinding helper)
│   ├── extension_helper.sh     # GNOME extension download & installation tool
│   ├── runner.sh               # Terminal execution engine & interactive skip handler
│   ├── state_manager.py        # History, status tracking & resume persistence
│   └── state.json              # Saved execution results (auto-generated)
├── settings/                   # GNOME interface, DNF config & window manager settings
│   ├── 01_05_dnf_speedup.sh
│   ├── 01_10_dark_mode.sh
│   ├── 01_20_hot_corners.sh
│   ├── 01_30_workspaces.sh
│   └── 01_40_app_switcher.sh
├── fonts/                      # Typography and Nerd Font setup
│   └── 01_10_jetbrains_mono_nerd.sh
├── installations/              # Applications, CLI tools, and package repositories
│   ├── 02_10_tailscale.sh
│   ├── 02_20_syncthing.sh
│   ├── 02_30_kde_connect.sh
│   ├── 02_40_kitty.sh
│   ├── 02_50_yazi.sh
│   ├── 02_60_vicinae.sh
│   ├── 02_70_antigravity.sh
│   ├── 02_80_tableplus.sh
│   ├── 03_10_google_chrome.sh
│   ├── 03_20_vscode.sh
│   ├── 03_30_zen_browser.sh
│   ├── 03_40_obsidian.sh
│   ├── 03_50_localsend.sh
│   └── 03_60_flatseal.sh
├── extensions/                 # GNOME Shell extensions and manager tools
│   ├── 04_10_extension_tools.sh
│   ├── 04_20_appindicator.sh
│   └── 04_30_vicinae_extension.sh
└── keybindings/                # System and application keyboard shortcuts
    ├── 05_10_window_shortcuts.sh
    ├── 05_20_shell_navigation.sh
    ├── 05_25_workspace_shortcuts.sh
    ├── 05_30_app_launchers.sh
    └── 05_40_session_power.sh
```

---

## Features & Workflows

### 1. Single-Instance Protection & Auto-Close
* When you click **"Start Setup"**, the setup manager launches the execution terminal and **closes the GUI window immediately**.
* This completely eliminates the risk of clicking "Start Setup" repeatedly or running multiple instances in parallel.
* A process lockfile (`resources/runner.lock`) additionally guarantees that no two runners can execute simultaneously.

### 2. State Memory & Resuming (`state.json`)
* The runner logs the outcome of every task (`Completed`, `Failed`, or `Skipped`) along with execution time and timestamps.
* When you re-open `main.sh`:
  * **Completed tasks** are visually marked with a green checkmark and **deselected by default**.
  * **Failed & Skipped tasks** are prominently badged in red/yellow and **pre-selected** so you can pick up where you left off.
* Header Controls:
  * **Resume**: One-click select of only pending, failed, or skipped tasks.
  * **All / None**: Fast batch toggles.
  * **Refresh Icon**: Clears execution history if you want to start fresh.

### 3. Skipping Tasks At Runtime (Press `Ctrl+C`)
If an installation is hanging, crawling, or a mirror is down:
* **Press `Ctrl+C` in the terminal**:
  The runner intercepts the interrupt and prompts:
  ```text
  [!] TASK INTERRUPTED: Visual Studio Code
  Options:
    [s] Skip this task and proceed to next (default in 15s)
    [r] Retry this task
    [q] Quit setup entirely
  Choice [s/r/q]:
  ```
* Simply hit **Enter** (or type `s`): the task is marked as `Skipped` in the database, and the runner immediately proceeds to the next task in the batch!
* You can retry skipped tasks at any point later by re-launching `main.sh`.

### 4. DNF Fast Mirror & Timeout Protection (`01_05_dnf_speedup.sh`)
* Automatically enables `fastestmirror=True`, `max_parallel_downloads=10`, and sets strict timeout / transfer speed floors (`minrate=30k`, `timeout=15`).
* If a mirror is dead or unresponsive, DNF automatically drops it within 15 seconds instead of waiting 20 minutes.

---

## Quick Start on a Fresh PC (One-Liner)

After resetting your PC, simply run:

```bash
curl -fsSL https://raw.githubusercontent.com/mearundasari/fw44-261102/main/bootstrap.sh | bash
```

This will automatically:
1. Download all setup folders and scripts to `~/fedora_workstation_setup`.
2. Configure executable permissions.
3. Launch the GTK 4 setup manager GUI.

---

## Local Usage

```bash
./main.sh
# or
python3 main.py
```
