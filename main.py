#!/usr/bin/env python3
"""
Fedora Workstation Post-Reset Setup
Modular GTK4 / Libadwaita Setup Manager with State Tracking & Resume
"""

import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw, Gio, GLib, GObject, Gtk

# Import state manager
RESOURCES_DIR = Path(__file__).resolve().parent / "resources"
sys.path.insert(0, str(RESOURCES_DIR))
import state_manager

APP_ID = "io.github.fedora.workstation.setup"
BASE_DIR = Path(__file__).resolve().parent
LOCK_FILE = RESOURCES_DIR / "runner.lock"

CATEGORY_METADATA = {
    "settings": {
        "title": "Settings",
        "icon": "preferences-system-symbolic",
        "order": 1,
    },
    "fonts": {
        "title": "Fonts",
        "icon": "preferences-desktop-font-symbolic",
        "order": 2,
    },
    "installations": {
        "title": "Installations",
        "icon": "software-properties-symbolic",
        "order": 3,
    },
    "extensions": {
        "title": "Extensions",
        "icon": "application-x-addon-symbolic",
        "order": 4,
    },
    "keybindings": {
        "title": "Keybindings",
        "icon": "preferences-desktop-keyboard-shortcuts-symbolic",
        "order": 5,
    },
}


def parse_script_header(file_path: Path) -> dict:
    match = re.match(r"^(\d{2})_(\d{2})_(.*)\.sh$", file_path.name)
    if match:
        batch = int(match.group(1))
        order = int(match.group(2))
        slug = match.group(3)
    else:
        batch = 99
        order = 99
        slug = file_path.stem

    title = slug.replace("_", " ").title()
    desc = ""
    sudo = False

    try:
        with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
            for line in f:
                line = line.strip()
                if not line.startswith("#"):
                    if line and not line.startswith("#!"):
                        break
                    continue
                cleaned = line.lstrip("#").strip()
                if ":" in cleaned:
                    key, val = cleaned.split(":", 1)
                    key = key.strip().lower()
                    val = val.strip()
                    if key == "title":
                        title = val
                    elif key == "description":
                        desc = val
                    elif key == "sudo":
                        sudo = val.lower() in ("true", "1", "yes")
    except Exception as e:
        print(f"Error parsing {file_path}: {e}", file=sys.stderr)

    rel_path = str(file_path.relative_to(BASE_DIR))

    return {
        "path": file_path,
        "rel_path": rel_path,
        "filename": file_path.name,
        "batch": batch,
        "order": order,
        "title": title,
        "description": desc,
        "sudo": sudo,
    }


def discover_categories(base_dir: Path) -> dict:
    categories = {}
    for entry in sorted(base_dir.iterdir()):
        if not entry.is_dir() or entry.name.startswith(".") or entry.name in ("__pycache__", "resources"):
            continue

        scripts = []
        for file in sorted(entry.glob("*.sh")):
            scripts.append(parse_script_header(file))

        if scripts:
            scripts.sort(key=lambda s: (s["batch"], s["order"], s["filename"]))
            categories[entry.name] = scripts

    return categories


def is_runner_active() -> bool:
    if LOCK_FILE.exists():
        try:
            pid_str = LOCK_FILE.read_text().strip()
            if pid_str:
                pid = int(pid_str)
                os.kill(pid, 0)
                return True
        except (ProcessLookupError, ValueError):
            LOCK_FILE.unlink(missing_ok=True)
            return False
        except PermissionError:
            return True
    return False


def find_terminal_command(command_to_run: str) -> list:
    """Finds an installed terminal emulator and formats launch command."""
    if shutil.which("ptyxis"):
        return ["ptyxis", "--new-window", "--title", "Workstation Setup", "--", "bash", "-c", command_to_run]
    if shutil.which("gnome-terminal"):
        return ["gnome-terminal", "--title", "Workstation Setup", "--", "bash", "-c", command_to_run]
    if shutil.which("kitty"):
        return ["kitty", "--title", "Workstation Setup", "bash", "-c", command_to_run]
    if shutil.which("kgx"):
        return ["kgx", "-e", f"bash -c '{command_to_run}'"]
    if shutil.which("alacritty"):
        return ["alacritty", "-t", "Workstation Setup", "-e", "bash", "-c", command_to_run]
    if shutil.which("xterm"):
        return ["xterm", "-title", "Workstation Setup", "-e", "bash", "-c", command_to_run]
    return None


class SetupWindow(Adw.ApplicationWindow):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        self.set_title("Fedora Workstation Setup")
        self.set_default_size(920, 700)

        self.state = state_manager.load_state()
        self.categories = discover_categories(BASE_DIR)
        self.item_entries = []  # list of dicts: {"item": ..., "check": ..., "badge_box": ...}

        self.toast_overlay = Adw.ToastOverlay()
        self.set_content(self.toast_overlay)

        # Toolbar View
        self.toolbar_view = Adw.ToolbarView()
        self.toast_overlay.set_child(self.toolbar_view)

        # Build UI
        self._build_headerbar()
        self._build_tabs()
        self._update_counter()

    def _build_headerbar(self):
        self.header_bar = Adw.HeaderBar()
        self.toolbar_view.add_top_bar(self.header_bar)

        # Left controls: Quick selection buttons
        left_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)

        btn_select_all = Gtk.Button(label="All")
        btn_select_all.set_tooltip_text("Select all tasks across all tabs")
        btn_select_all.connect("clicked", lambda _: self._select_all())
        btn_select_all.add_css_class("flat")
        left_box.append(btn_select_all)

        btn_select_none = Gtk.Button(label="None")
        btn_select_none.set_tooltip_text("Deselect all tasks")
        btn_select_none.connect("clicked", lambda _: self._deselect_all())
        btn_select_none.add_css_class("flat")
        left_box.append(btn_select_none)

        btn_resume = Gtk.Button(label="Resume")
        btn_resume.set_tooltip_text("Select only pending, failed, or skipped tasks")
        btn_resume.connect("clicked", lambda _: self._select_pending_or_failed())
        btn_resume.add_css_class("flat")
        left_box.append(btn_resume)

        self.header_bar.pack_start(left_box)

        # Right controls: History reset, Counter & Start Setup button
        right_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)

        btn_reset_history = Gtk.Button()
        btn_reset_history.set_icon_name("view-refresh-symbolic")
        btn_reset_history.set_tooltip_text("Reset execution history and statuses")
        btn_reset_history.add_css_class("flat")
        btn_reset_history.connect("clicked", lambda _: self._on_clear_history())
        right_box.append(btn_reset_history)

        self.lbl_counter = Gtk.Label(label="0 selected")
        self.lbl_counter.add_css_class("dim-label")
        right_box.append(self.lbl_counter)

        self.btn_run = Gtk.Button(label="Start Setup")
        self.btn_run.add_css_class("suggested-action")
        self.btn_run.add_css_class("pill")
        self.btn_run.connect("clicked", self._on_run_clicked)
        right_box.append(self.btn_run)

        self.header_bar.pack_end(right_box)

        # View Stack & View Switcher in Header Title
        self.view_stack = Adw.ViewStack()
        self.view_switcher_title = Adw.ViewSwitcherTitle(stack=self.view_stack)
        self.header_bar.set_title_widget(self.view_switcher_title)

        # Add ViewSwitcherBar at bottom for narrow windows
        self.view_switcher_bar = Adw.ViewSwitcherBar(stack=self.view_stack)
        self.toolbar_view.add_bottom_bar(self.view_switcher_bar)
        self.view_switcher_title.bind_property(
            "title-visible",
            self.view_switcher_bar,
            "reveal",
            GObject.BindingFlags.SYNC_CREATE,
        )

        self.toolbar_view.set_content(self.view_stack)

    def _build_tabs(self):
        sorted_cat_names = sorted(
            self.categories.keys(),
            key=lambda k: (CATEGORY_METADATA.get(k, {}).get("order", 99), k),
        )

        for cat_name in sorted_cat_names:
            scripts = self.categories[cat_name]
            meta = CATEGORY_METADATA.get(cat_name, {})
            title = meta.get("title", cat_name.capitalize())
            icon = meta.get("icon", "system-run-symbolic")

            page_widget = self._create_category_page(cat_name, title, scripts)
            stack_page = self.view_stack.add_titled(page_widget, cat_name, title)
            stack_page.set_icon_name(icon)

    def _create_category_page(self, cat_name: str, cat_title: str, scripts: list) -> Gtk.Widget:
        scrolled = Gtk.ScrolledWindow()
        scrolled.set_propagate_natural_height(True)
        scrolled.set_vexpand(True)

        pref_page = Adw.PreferencesPage()
        scrolled.set_child(pref_page)

        # Group scripts by batch number
        batches = {}
        for s in scripts:
            batches.setdefault(s["batch"], []).append(s)

        for batch_num in sorted(batches.keys()):
            batch_scripts = batches[batch_num]
            group = Adw.PreferencesGroup()
            group.set_title(f"Batch {batch_num:02d}")
            group.set_description(f"{len(batch_scripts)} task{'s' if len(batch_scripts) > 1 else ''} in execution batch {batch_num:02d}")

            for item in batch_scripts:
                row = Adw.ActionRow()
                row.set_title(GLib.markup_escape_text(item["title"]))
                if item["description"]:
                    row.set_subtitle(GLib.markup_escape_text(item["description"]))

                # Check previous history
                task_status = self.state.get("history", {}).get(item["rel_path"])
                is_completed = task_status and task_status.get("status") == "success"

                # Checkbox: if already completed, default to unchecked; otherwise checked
                check = Gtk.CheckButton()
                check.set_active(not is_completed)
                check.connect("toggled", lambda _: self._update_counter())
                row.add_prefix(check)
                row.set_activatable_widget(check)

                # Suffix badges: Status / Order / Sudo
                suffix_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)

                # Status badge
                status_widget = self._render_status_badge(task_status)
                suffix_box.append(status_widget)

                # Order badge
                lbl_order = Gtk.Label(label=f"Order {item['order']:02d}")
                lbl_order.add_css_class("caption")
                lbl_order.add_css_class("dim-label")
                suffix_box.append(lbl_order)

                # Sudo icon
                if item["sudo"]:
                    img_sudo = Gtk.Image.new_from_icon_name("dialog-password-symbolic")
                    img_sudo.set_tooltip_text("Requires sudo / root permissions")
                    img_sudo.add_css_class("dim-label")
                    suffix_box.append(img_sudo)

                row.add_suffix(suffix_box)
                group.add(row)

                self.item_entries.append({
                    "item": item,
                    "check": check,
                    "suffix_box": suffix_box,
                    "status_widget": status_widget,
                })

            pref_page.add(group)

        return scrolled

    def _render_status_badge(self, task_status: dict) -> Gtk.Widget:
        box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=4)
        if not task_status:
            return box

        status = task_status.get("status")
        if status == "success":
            img = Gtk.Image.new_from_icon_name("checkmark-symbolic")
            img.add_css_class("success")
            lbl = Gtk.Label(label="Completed")
            lbl.add_css_class("success")
            lbl.add_css_class("caption")
            box.append(img)
            box.append(lbl)
            box.set_tooltip_text(f"Completed in {task_status.get('duration', 0)}s on {task_status.get('last_executed', '')}")
        elif status == "failed":
            img = Gtk.Image.new_from_icon_name("dialog-error-symbolic")
            img.add_css_class("error")
            lbl = Gtk.Label(label="Failed")
            lbl.add_css_class("error")
            lbl.add_css_class("caption")
            box.append(img)
            box.append(lbl)
            box.set_tooltip_text(f"Failed with exit code {task_status.get('exit_code', 1)} on {task_status.get('last_executed', '')}")
        elif status == "skipped":
            img = Gtk.Image.new_from_icon_name("dialog-warning-symbolic")
            img.add_css_class("warning")
            lbl = Gtk.Label(label="Skipped")
            lbl.add_css_class("warning")
            lbl.add_css_class("caption")
            box.append(img)
            box.append(lbl)
            box.set_tooltip_text(f"Skipped on {task_status.get('last_executed', '')}")

        return box

    def _select_all(self):
        for entry in self.item_entries:
            entry["check"].set_active(True)
        self._update_counter()

    def _deselect_all(self):
        for entry in self.item_entries:
            entry["check"].set_active(False)
        self._update_counter()

    def _select_pending_or_failed(self):
        """Resumes setup: checks tasks that have not yet succeeded."""
        self.state = state_manager.load_state()
        history = self.state.get("history", {})
        for entry in self.item_entries:
            rel_path = entry["item"]["rel_path"]
            stat = history.get(rel_path)
            is_success = stat and stat.get("status") == "success"
            entry["check"].set_active(not is_success)
        self._update_counter()
        toast = Adw.Toast.new("Selected pending, skipped, and failed tasks.")
        self.toast_overlay.add_toast(toast)

    def _on_clear_history(self):
        state_manager.clear_history()
        self.state = {"last_run": None, "history": {}}

        # Refresh status widgets in rows
        for entry in self.item_entries:
            suffix_box = entry["suffix_box"]
            old_widget = entry["status_widget"]
            suffix_box.remove(old_widget)
            new_widget = self._render_status_badge(None)
            suffix_box.prepend(new_widget)
            entry["status_widget"] = new_widget
            entry["check"].set_active(True)

        self._update_counter()
        toast = Adw.Toast.new("Execution history cleared.")
        self.toast_overlay.add_toast(toast)

    def _update_counter(self):
        total = len(self.item_entries)
        selected = sum(1 for e in self.item_entries if e["check"].get_active())
        history = self.state.get("history", {})
        completed = sum(1 for e in self.item_entries if history.get(e["item"]["rel_path"], {}).get("status") == "success")

        if completed > 0:
            self.lbl_counter.set_text(f"{selected} of {total} selected ({completed} completed)")
        else:
            self.lbl_counter.set_text(f"{selected} of {total} selected")

    def _on_run_clicked(self, _button):
        # 1. Prevent concurrent runs
        if is_runner_active():
            toast = Adw.Toast.new("Setup is already running in an active terminal.")
            self.toast_overlay.add_toast(toast)
            return

        selected_items = [e["item"] for e in self.item_entries if e["check"].get_active()]

        if not selected_items:
            toast = Adw.Toast.new("No tasks selected. Please check at least one task.")
            self.toast_overlay.add_toast(toast)
            return

        # Sort selected items globally by batch then order then path
        selected_items.sort(key=lambda s: (s["batch"], s["order"], str(s["path"])))

        # Create temporary queue file
        with tempfile.NamedTemporaryFile(mode="w", delete=False, prefix="fedora_setup_queue_", suffix=".txt") as qf:
            for item in selected_items:
                qf.write(f"{item['path'].resolve()}\n")
            queue_file_path = qf.name

        runner_script = RESOURCES_DIR / "runner.sh"
        cmd_str = f"bash '{runner_script}' '{queue_file_path}'"

        terminal_cmd = find_terminal_command(cmd_str)
        if not terminal_cmd:
            toast = Adw.Toast.new("Error: No supported terminal emulator found (Ptyxis, Gnome-Terminal, Kitty, etc.).")
            self.toast_overlay.add_toast(toast)
            return

        try:
            # Spawn runner inside terminal
            subprocess.Popen(terminal_cmd)

            # Issue #1: Close the setup manager window immediately upon launching runner
            # This completely avoids running the setup multiple times in parallel.
            self.close()

        except Exception as e:
            toast = Adw.Toast.new(f"Failed to launch terminal: {e}")
            self.toast_overlay.add_toast(toast)


class SetupApplication(Adw.Application):
    def __init__(self):
        super().__init__(
            application_id=APP_ID,
            flags=Gio.ApplicationFlags.DEFAULT_FLAGS,
        )

    def do_activate(self):
        win = self.props.active_window
        if not win:
            win = SetupWindow(application=self)
        win.present()


def main():
    app = SetupApplication()
    return app.run(sys.argv)


if __name__ == "__main__":
    sys.exit(main())
