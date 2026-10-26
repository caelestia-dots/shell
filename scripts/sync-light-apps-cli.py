#!/usr/bin/env python3
"""Sync caelestia cli.json theme hooks for shell-dark / apps-light mode."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

# Keep Kitty live-reload when syncing light-apps (do not wipe this hook).
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
    theme["enableGtk"] = not args.light_apps
    theme["enableQt"] = not args.light_apps

    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(cfg, indent=4) + "\n")


if __name__ == "__main__":
    main()
