#!/usr/bin/env python3
"""Installs the Hallownest userChrome in every Zen profile and writes the flavour colours."""
import configparser
import shutil
import sys
from pathlib import Path

from hkstyle import palette

PREF = 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);'

p = palette()
src = Path(__file__).parent / "zen" / "userChrome.css"
zen = Path.home() / ".config" / "zen"
ini = configparser.ConfigParser()
ini.read(zen / "profiles.ini")

colours = f""":root {{
    --hk-accent: {p["accent"]};
    --hk-steel: {p["steel"]};
    --hk-void: {p["void"]};
    --hk-shell: {p["shell"]};
    --hk-card: {p["card"]};
    --hk-text: {p["text"]};
    --hk-subtext: {p["subtext"]};
}}
"""

for section in ini.sections():
    if not section.startswith("Profile") or "Path" not in ini[section]:
        continue
    path = ini[section]["Path"]
    profile = zen / path if ini[section].get("IsRelative", "1") == "1" else Path(path)
    if not profile.is_dir():
        continue
    chrome = profile / "chrome"
    chrome.mkdir(exist_ok=True)
    shutil.copyfile(src, chrome / "userChrome.css")
    (chrome / "hallownest-colors.css").write_text(colours)
    user_js = profile / "user.js"
    text = user_js.read_text() if user_js.exists() else ""
    if PREF not in text:
        user_js.write_text(text + ("\n" if text and not text.endswith("\n") else "") + PREF + "\n")
