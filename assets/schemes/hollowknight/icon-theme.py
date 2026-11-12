#!/usr/bin/env python3
"""Builds YAMIS-Hallownest: a copy of the monochrome YAMIS-Cosmic icon theme tinted with the flavour.

YAMIS draws every glyph in its text colour (#d8dee9) with a dark highlight (#3b4252); both are
swapped for the style and flavour's Soul accent and a dark steel. Source: ~/.local/share/icons/YAMIS-Cosmic.
"""
import re
import shutil
import sys
from pathlib import Path

from hkstyle import palette


def darken(hex_colour, k):
    return "#" + "".join(f"{round(int(hex_colour[i:i + 2], 16) * k):02x}" for i in (1, 3, 5))


def lighten(hex_colour, k):
    return "#" + "".join(f"{round(int(hex_colour[i:i + 2], 16) + (255 - int(hex_colour[i:i + 2], 16)) * k):02x}" for i in (1, 3, 5))


p = palette()
icons = Path.home() / ".local/share/icons"
src = icons / "YAMIS-Cosmic"
dst = icons / "YAMIS-Hallownest"
stamp = dst / ".flavour"
if not src.is_dir() or (stamp.exists() and stamp.read_text().strip() == p["key"]):
    sys.exit(0)

colours = {"#d8dee9": p["accent"], "#3b4252": lighten(p["steel"], 0.45) if p["light"] else darken(p["steel"], 0.35)}
pattern = re.compile("|".join(colours), re.IGNORECASE)


# Qt's SVG renderer ignores the stylesheet's color, so currentColor is written out per element
def inline(tag):
    tag = tag.group(0)
    colour = colours["#3b4252"] if "ColorScheme-Highlight" in tag else colours["#d8dee9"]
    return tag.replace("currentColor", colour)


def tint(svg):
    return re.sub(r"<[^<>]*currentColor[^<>]*>", inline, pattern.sub(lambda m: colours[m.group(0).lower()], svg))


tmp = icons / ".YAMIS-Hallownest.tmp"
shutil.rmtree(tmp, ignore_errors=True)
for f in src.rglob("*"):
    out = tmp / f.relative_to(src)
    if f.is_dir():
        out.mkdir(parents=True, exist_ok=True)
    elif f.suffix == ".svg":
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(tint(f.read_text(encoding="utf-8")), encoding="utf-8")
    else:
        out.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(f, out)

index = tmp / "index.theme"
text = re.sub(r"(?m)^Name=.*$", "Name=YAMIS-Hallownest", index.read_text(encoding="utf-8"))
# Drop inherited themes that aren't installed (Cosmic, pop-icon-theme): Qt warns about each one
dirs = [Path.home() / ".local/share/icons", Path("/usr/share/icons")]
text = re.sub(r"(?m)^Inherits=(.*)$", lambda m: "Inherits=" + ",".join(
    t for t in m.group(1).split(",") if any((d / t).is_dir() for d in dirs)), text)
index.write_text(text, encoding="utf-8")
(tmp / ".flavour").write_text(p["key"])
# Swap in one go so apps never see a half-written theme
shutil.rmtree(dst, ignore_errors=True)
tmp.rename(dst)
