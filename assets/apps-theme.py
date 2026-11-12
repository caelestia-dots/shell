#!/usr/bin/env python3
"""Hallownest colours for zathura and btop, following the style and flavour.

- zathura: ~/.config/zathura/hallownest-colors, included from zathurarc (created if missing).
- btop: ~/.config/btop/themes/hallownest.theme, selected in btop.conf.
Existing configs are backed up once as <file>.bak-hallownest.
"""
import re
import shutil
import sys
from pathlib import Path

from hkstyle import palette

p = palette()
VOID, SHELL, CARD, TEXT, SUBTEXT, FAINT = (p[k] for k in ("void", "shell", "card", "text", "subtext", "faint"))
GRIMM, GOLD = p["grimm"], p["gold"]
accent, steel = p["accent"], p["steel"]
config = Path.home() / ".config"


def backup(path: Path) -> None:
    bak = path.with_name(path.name + ".bak-hallownest")
    if path.exists() and not bak.exists():
        shutil.copy2(path, bak)


def rgba(hex_colour: str, alpha: float) -> str:
    r, g, b = (int(hex_colour[i:i + 2], 16) for i in (1, 3, 5))
    return f"rgba({r},{g},{b},{alpha})"


def zathura() -> None:
    d = config / "zathura"
    d.mkdir(parents=True, exist_ok=True)
    colours = {
        "default-bg": VOID, "default-fg": TEXT,
        "statusbar-bg": SHELL, "statusbar-fg": SUBTEXT,
        "inputbar-bg": CARD, "inputbar-fg": accent,
        "notification-bg": CARD, "notification-fg": TEXT,
        "notification-error-bg": CARD, "notification-error-fg": GRIMM,
        "notification-warning-bg": CARD, "notification-warning-fg": GOLD,
        "highlight-color": rgba(accent, 0.35), "highlight-active-color": rgba(GOLD, 0.45),
        "completion-bg": CARD, "completion-fg": SUBTEXT,
        "completion-highlight-bg": accent, "completion-highlight-fg": VOID,
        "completion-group-bg": SHELL, "completion-group-fg": steel,
        "index-bg": VOID, "index-fg": TEXT, "index-active-bg": CARD, "index-active-fg": accent,
        "render-loading-bg": VOID, "render-loading-fg": steel,
        "recolor-lightcolor": VOID, "recolor-darkcolor": TEXT,
    }
    (d / "hallownest-colors").write_text("".join(f'set {k} "{v}"\n' for k, v in colours.items()))
    rc = d / "zathurarc"
    if not rc.exists():
        rc.write_text("include hallownest-colors\n\n# Dark pages (Ctrl+R toggles), keeping images' hues\nset recolor true\nset recolor-keephue true\nset selection-clipboard clipboard\nset adjust-open width\n")
    elif "include hallownest-colors" not in rc.read_text():
        backup(rc)
        rc.write_text("include hallownest-colors\n" + rc.read_text())


def btop() -> None:
    d = config / "btop"
    conf = d / "btop.conf"
    if not conf.exists():
        return
    (d / "themes").mkdir(exist_ok=True)
    theme = {
        "main_bg": "", "main_fg": TEXT, "title": accent, "hi_fg": accent,
        "selected_bg": CARD, "selected_fg": accent, "inactive_fg": FAINT,
        "graph_text": SUBTEXT, "meter_bg": CARD, "proc_misc": accent,
        "cpu_box": steel, "mem_box": steel, "net_box": steel, "proc_box": steel, "div_line": p["bright"],
        "temp_start": steel, "temp_mid": accent, "temp_end": GRIMM,
        "cpu_start": steel, "cpu_mid": accent, "cpu_end": GRIMM,
        "free_start": FAINT, "free_mid": steel, "free_end": accent,
        "cached_start": FAINT, "cached_mid": steel, "cached_end": accent,
        "available_start": FAINT, "available_mid": steel, "available_end": accent,
        "used_start": steel, "used_mid": accent, "used_end": GRIMM,
        "download_start": FAINT, "download_mid": steel, "download_end": accent,
        "upload_start": FAINT, "upload_mid": GOLD, "upload_end": GRIMM,
        "process_start": steel, "process_mid": accent, "process_end": GRIMM,
    }
    (d / "themes" / "hallownest.theme").write_text("".join(f'theme[{k}]="{v}"\n' for k, v in theme.items()))
    text = conf.read_text()
    if 'color_theme = "hallownest"' not in text:
        backup(conf)
        conf.write_text(re.sub(r'(?m)^color_theme = .*$', 'color_theme = "hallownest"', text))



for apply in (zathura, btop):
    try:
        apply()
    except OSError as e:
        print(f"{apply.__name__}: {e}", file=sys.stderr)
