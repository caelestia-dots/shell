#!/usr/bin/env python3
"""Sync caelestia cli.json theme hooks for shell-dark / apps-light mode."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

# After colours apply, restore prefer-light when the shell asked for light apps.
# GTK/Thunar CSS still updates (enableGtk stays on) so the file manager follows
# the activity scheme; color-scheme prefer-light covers Adwaita/Qt apps.
POST_HOOK = (
    'test -f "${XDG_STATE_HOME:-$HOME/.local/state}/caelestia/force-apps-light" '
    '&& dconf write /org/gnome/desktop/interface/color-scheme "\'prefer-light\'"'
    ' ; "$HOME/.config/caelestia/scripts/kitty-reload-colours.sh" || true'
)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--light-apps", action=argparse.BooleanOptionalAction, required=True)
    args = parser.parse_args()

    path = Path.home() / ".config/caelestia/cli.json"
    cfg: dict = {}
    if path.exists():
        try:
            cfg = json.loads(path.read_text() or "{}")
        except json.JSONDecodeError:
            cfg = {}

    theme = cfg.setdefault("theme", {})
    theme["postHook"] = POST_HOOK
    # Thunar/Material GTK CSS always tracks the activity scheme.
    theme["enableGtk"] = True
    # Skip Qt colour engine while apps should stay light.
    theme["enableQt"] = not args.light_apps

    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(cfg, indent=4) + "\n")


if __name__ == "__main__":
    main()
