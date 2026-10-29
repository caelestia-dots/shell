#!/usr/bin/env python3
"""Run caelestia CLI without broadcasting OSC colour sequences to every PTY.

apply_terms() writes ANSI OSC dumps to all /dev/pts devices. Some clients
(e.g. IDE embedded terminals) surface that as a system notification. We still
persist sequences.txt so new shells can pick up colours, but skip the broadcast.

After colours are applied (including user templates like kitty.conf), push the
palette into open Kitty windows via remote control.
"""

from __future__ import annotations

import os
import runpy
import subprocess
import sys
from pathlib import Path


def _atomic_write(path: Path, text: str) -> None:
    """Temp-file + os.replace: readers never see a half-written file, and the
    rename is what qt6ct's directory-scoped QFileSystemWatcher picks up live."""
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(path.name + ".tmp")
    tmp.write_text(text)
    os.replace(tmp, path)


def _reload_kitty() -> None:
    script = Path.home() / ".config/caelestia/scripts/kitty-reload-colours.sh"
    if not script.is_file():
        return
    try:
        subprocess.run([str(script)], check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except OSError:
        pass


def _sync_kde_icon_theme(mode: str) -> None:
    """kdeglobals [Icons] → Papirus-{mode}.

    Transitional: plasma-integration is still installed (QT_QPA_PLATFORMTHEME
    no longer targets it, but any stray KDE config reader does). Phase 2
    (Plasma uninstall) removes this dual-write.
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


# QPalette::ColorRole enum order (Qt ≥ 6.6: 22 roles, Accent at 21). qt6ct maps
# scheme list index i → ColorRole(i), so this order is the file format.
_QT_ROLE_KEYS = (
    ("WindowText", "onSurface"),
    ("Button", "surfaceContainer"),
    ("Light", "surfaceBright"),
    ("Midlight", "surfaceContainerHigh"),
    ("Dark", "surfaceContainerLowest"),
    ("Mid", "surfaceContainerLow"),
    ("Text", "onSurface"),
    ("BrightText", "onSurface"),
    ("ButtonText", "onSurface"),
    ("Base", "surfaceContainerLowest"),
    ("Window", "surface"),
    ("Shadow", "shadow"),
    ("Highlight", "primary"),
    ("HighlightedText", "onPrimary"),
    ("Link", "primary"),
    ("LinkVisited", "tertiary"),
    ("AlternateBase", "surfaceContainer"),
    ("NoRole", "surface"),
    ("ToolTipBase", "surfaceContainerHighest"),
    ("ToolTipText", "onSurfaceVariant"),
    ("PlaceholderText", "outline"),
    ("Accent", "primary"),
)
# Disabled-state roles that read as text/selection get a muted tone instead.
_QT_DISABLED_MUTED = {
    "WindowText": "outline",
    "Text": "outline",
    "ButtonText": "outline",
    "PlaceholderText": "outlineVariant",
    "HighlightedText": "onSurface",
    "Highlight": "outlineVariant",
    "Accent": "outlineVariant",
}


def _qt6ct_scheme_body(colours: dict[str, str], mode: str) -> str:
    """Build the [ColorScheme] block from the scheme's Material tokens."""

    def token(key: str) -> str:
        # All roles are defined by the scheme generator; the fallback only
        # exists as a guard against scheme drift.
        return f"#{colours.get(key) or colours.get('surface') or '000000'}"

    active = [token(key) for _, key in _QT_ROLE_KEYS]
    inactive = list(active)
    disabled = [
        token(_QT_DISABLED_MUTED.get(role, fallback_key))
        for role, fallback_key in _QT_ROLE_KEYS
    ]

    def line(name: str, values: list[str]) -> str:
        return f"{name}=" + ", ".join(values)

    rows = (line("active_colors", active), line("inactive_colors", inactive), line("disabled_colors", disabled))
    return "[ColorScheme]\n" + "\n".join(rows) + "\n"


def _sync_qt6ct(colours: dict[str, str], mode: str) -> None:
    """Write the qt6ct scheme + config from the scheme's Material tokens.

    qt6ct is our Qt platform theme since leaving QT_QPA_PLATFORMTHEME=kde:
    icon_theme + custom palette live in ~/.config/qt6ct/qt6ct.conf, the palette
    itself in colors/caelestia.conf. Both files are replaced atomically so
    qt6ct's directory watcher applies icon and colour changes to running Qt
    apps (VLC, transmission-qt, …) without restart.
    """
    import configparser

    colors_dir = Path.home() / ".config/qt6ct/colors"
    scheme_path = colors_dir / "caelestia.conf"
    _atomic_write(scheme_path, _qt6ct_scheme_body(colours, mode))

    icon_theme = f"Papirus-{mode.capitalize()}" if mode in ("dark", "light") else "Papirus-Dark"
    conf = Path.home() / ".config/qt6ct/qt6ct.conf"
    parser = configparser.ConfigParser(interpolation=None, strict=False)
    try:
        parser.read(conf, encoding="utf-8")
    except (OSError, configparser.Error):
        parser = configparser.ConfigParser(interpolation=None, strict=False)
    if not parser.has_section("Appearance"):
        parser.add_section("Appearance")
    parser.set("Appearance", "icon_theme", icon_theme)
    parser.set("Appearance", "custom_palette", "true")
    parser.set("Appearance", "color_scheme_path", str(scheme_path))
    parser.set("Appearance", "style", "Fusion")
    import io

    buf = io.StringIO()
    parser.write(buf)
    _atomic_write(conf, buf.getvalue())


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
        "gtk-cursor-theme-name=Adwaita\n"
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
        _sync_qt6ct(colours, mode)
        # OpenCode TUI: theme file + cli.json mode follow the activity scheme.
        _sync_opencode_theme(colours, mode)
        # Templates land inside apply_colours; refresh Kitty after that.
        _reload_kitty()

    theme.apply_terms = apply_terms_quiet
    theme.apply_colours = apply_colours_quiet


def _sync_opencode_theme(colours: dict[str, str], mode: str) -> None:
    """Push the activity scheme into OpenCode's TUI theme files and point
    cli.json at them.

    OpenCode hot-reloads cli.json keywords (theme *name*) but NOT theme file
    contents, so the theme lives under two names (caelestia / caelestia-alt)
    with identical content; each real palette change flips cli.json to the
    other name, which forces running TUIs to re-read and re-apply the theme.
    A no-op (same palette + same mode) is skipped to avoid reload churn.
    """
    import json as _json

    gen = Path(__file__).resolve().parent / "generate-opencode-theme.py"
    themes_dir = Path.home() / ".config/opencode/themes"
    canonical = themes_dir / "caelestia.json"
    naming = {"caelestia": "caelestia.json", "caelestia-alt": "caelestia-alt.json"}
    cli_path = Path.home() / ".config/opencode/cli.json"
    cli, current_name, current_payload = {}, None, ""
    try:
        cli = _json.loads(cli_path.read_text() or "{}") if cli_path.is_file() else {}
        if not isinstance(cli, dict):
            cli = {}
        theme = cli.setdefault("theme", {})
        current_name = theme.get("name") if isinstance(theme, dict) else None
        if current_name in naming:
            current_payload = (themes_dir / naming[current_name]).read_text()
    except (OSError, ValueError):
        return
    try:
        subprocess.run(
            [sys.executable, str(gen), mode],
            input=_json.dumps(colours),
            text=True,
            check=False,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        payload = canonical.read_text()
    except (OSError, ValueError):
        return

    try:
        theme = cli.setdefault("theme", {})
        if current_payload == payload and theme.get("mode") == mode:
            return  # nothing changed; do not churn running TUIs
        if current_name == "caelestia":
            # The TUI shows the canonical; the twin gets the new palette first
            (themes_dir / naming["caelestia-alt"]).write_text(payload)
        # current_name == "caelestia-alt" (or not ours): canonical already holds
        # the new payload because the generator writes it directly.
        theme["name"] = "caelestia-alt" if current_name == "caelestia" else "caelestia"
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
