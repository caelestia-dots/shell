#!/usr/bin/env python3
"""Run caelestia CLI without broadcasting OSC colour sequences to every PTY.

apply_terms() writes ANSI OSC dumps to all /dev/pts devices. Some clients
(e.g. IDE embedded terminals) surface that as a system notification. We still
persist sequences.txt so new shells can pick up colours, but skip the broadcast.

After colours are applied (including user templates like kitty.conf), push the
palette into open Kitty windows via remote control.
"""

from __future__ import annotations

import runpy
import subprocess
import sys
from pathlib import Path


def _reload_kitty() -> None:
    script = Path.home() / ".config/caelestia/scripts/kitty-reload-colours.sh"
    if not script.is_file():
        return
    try:
        subprocess.run([str(script)], check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except OSError:
        pass


def _sync_kde_icon_theme(mode: str) -> None:
    """Quickshell uses QT_QPA_PLATFORMTHEME=kde → QIcon reads kdeglobals [Icons].

    Caelestia sets Papirus via gsettings for GTK; keep KDE/Qt in sync so the
    launcher resolves the same icon set (not leftover Breeze/hicolor).
    """
    import re

    theme_name = f"Papirus-{mode.capitalize()}" if mode in ("dark", "light") else "Papirus-Dark"
    path = Path.home() / ".config/kdeglobals"
    try:
        text = path.read_text() if path.is_file() else ""
    except OSError:
        return

    if "[Icons]" in text:
        text = re.sub(r"(?m)^(\[Icons\]\n)Theme=.*$", rf"\1Theme={theme_name}", text, count=1)
        if not re.search(r"(?m)^\[Icons\]\nTheme=", text):
            text = re.sub(r"(?m)^\[Icons\]\s*$", f"[Icons]\nTheme={theme_name}", text, count=1)
    else:
        text = text.rstrip() + f"\n\n[Icons]\nTheme={theme_name}\n"

    try:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text if text.endswith("\n") else text + "\n")
    except OSError:
        pass


def _sync_gtk_settings(mode: str) -> None:
    """Point GTK at the correct adw-gtk3 variant and enable live CSS reload."""
    dark = mode == "dark"
    gtk_theme = "adw-gtk3-dark" if dark else "adw-gtk3"
    icon_theme = f"Papirus-{mode.capitalize()}" if mode in ("dark", "light") else "Papirus-Dark"
    prefer = "true" if dark else "false"
    body = (
        "[Settings]\n"
        f"gtk-theme-name={gtk_theme}\n"
        f"gtk-application-prefer-dark-theme={prefer}\n"
        f"gtk-icon-theme-name={icon_theme}\n"
        "gtk-cursor-theme-name=breeze_cursors\n"
        "gtk-cursor-theme-size=24\n"
        "gtk-font-name=Noto Sans 10\n"
        "gtk-modules=colorreload-gtk-module\n"
        "gtk-xft-dpi=98304\n"
    )
    for ver in ("gtk-3.0", "gtk-4.0"):
        path = Path.home() / f".config/{ver}/settings.ini"
        try:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(body)
        except OSError:
            pass

    try:
        subprocess.run(
            ["dconf", "write", "/org/gnome/desktop/interface/gtk-theme", f"'{gtk_theme}'"],
            check=False,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    except OSError:
        pass


def _trigger_gtk_color_reload() -> None:
    """kde-gtk-config's colorreload module watches ~/.config/gtk-3.0/colors.css
    (not gtk.css). Mirror our Material/Thunar styles there and bump a stamp so
    open Thunar windows pick up activity scheme changes live.
    """
    import time

    stamp = f"/* caelestia-reload {time.time_ns()} */\n"
    for ver in ("gtk-3.0", "gtk-4.0"):
        base = Path.home() / f".config/{ver}"
        gtk_css = base / "gtk.css"
        colors = base / "colors.css"
        try:
            if not gtk_css.is_file():
                continue
            # Inline thunar.css so the provider does not depend on @import caching
            text = gtk_css.read_text()
            thunar = base / "thunar.css"
            if thunar.is_file() and '@import "thunar.css"' in text:
                text = text.replace('@import "thunar.css";', thunar.read_text())
            colors.write_text(stamp + text)
        except OSError:
            pass


def _patch_theme() -> None:
    import caelestia.utils.theme as theme
    from caelestia.utils.paths import c_state_dir

    def apply_terms_quiet(sequences: str) -> None:
        state = c_state_dir / "sequences.txt"
        state.parent.mkdir(parents=True, exist_ok=True)
        state.write_text(sequences)

    orig_apply_gtk = theme.apply_gtk

    def apply_gtk_fixed(colours: dict[str, str], mode: str, icon_theme: str | None = None) -> None:
        # Upstream always writes adw-gtk3-dark; use the light variant for light mode.
        orig_apply_gtk(colours, mode, icon_theme)
        _sync_gtk_settings(mode)
        _trigger_gtk_color_reload()
        # apply_gtk sets prefer-{mode}; if light-apps is active, put prefer-light
        # back so Adwaita/Qt apps stay light while Thunar keeps scheme CSS.
        flag = Path.home() / ".local/state/caelestia/force-apps-light"
        if flag.is_file():
            try:
                subprocess.run(
                    ["dconf", "write", "/org/gnome/desktop/interface/color-scheme", "'prefer-light'"],
                    check=False,
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                )
            except OSError:
                pass

    theme.apply_gtk = apply_gtk_fixed

    orig_apply_colours = theme.apply_colours

    def apply_colours_quiet(colours: dict[str, str], mode: str) -> None:
        # Ensure GTK theming is on even if a stale light-apps sync flipped the flag.
        try:
            from caelestia.utils.paths import user_config_path

            if user_config_path.is_file():
                import json

                cfg = json.loads(user_config_path.read_text() or "{}")
                theme_cfg = cfg.setdefault("theme", {})
                if theme_cfg.get("enableGtk") is False:
                    theme_cfg["enableGtk"] = True
                    user_config_path.write_text(json.dumps(cfg, indent=4) + "\n")
        except Exception:
            pass

        orig_apply_colours(colours, mode)
        # Always push GTK/Thunar + colors.css reload stamp (colorreload watches
        # colors.css, not gtk.css — without this, open Thunar keeps stale styles).
        try:
            theme.apply_gtk(colours, mode)
        except Exception:
            pass
        _sync_kde_icon_theme(mode)
        # OpenCode TUI: theme file + cli.json mode follow the activity scheme.
        _sync_opencode_theme(colours, mode)
        # Templates land inside apply_colours; refresh Kitty after that.
        _reload_kitty()

    theme.apply_terms = apply_terms_quiet
    theme.apply_colours = apply_colours_quiet


def _sync_opencode_theme(colours: dict[str, str], mode: str) -> None:
    """Push the activity scheme into OpenCode's TUI theme file and point
    cli.json at it. cli.json edits hot-reload in running TUIs, so switching
    activity mode re-themes open OpenCode windows live.
    """
    import json as _json

    gen = Path(__file__).resolve().parent / "generate-opencode-theme.py"
    try:
        subprocess.run(
            [sys.executable, str(gen), mode],
            input=_json.dumps(colours),
            text=True,
            check=False,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    except OSError:
        return

    cli_path = Path.home() / ".config/opencode/cli.json"
    try:
        cli = _json.loads(cli_path.read_text() or "{}") if cli_path.is_file() else {}
        if not isinstance(cli, dict):
            return
        theme = cli.setdefault("theme", {})
        if theme.get("name") != "caelestia":
            theme["name"] = "caelestia"
        theme["mode"] = mode
        cli_path.write_text(_json.dumps(cli, indent=2) + "\n")
    except (OSError, ValueError):
        pass


def main() -> None:
    _patch_theme()
    # Replace argv so caelestia sees a normal CLI invocation
    sys.argv = ["caelestia", *sys.argv[1:]]
    runpy.run_module("caelestia", run_name="__main__")


if __name__ == "__main__":
    main()
