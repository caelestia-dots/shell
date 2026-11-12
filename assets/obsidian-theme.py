#!/usr/bin/env python3
"""Installs the Hallownest CSS snippet in every Obsidian vault and enables it in the style's mode."""
import base64
import json
import sys
from pathlib import Path

from hkstyle import palette


def rgb(hex_colour):
    return ", ".join(str(int(hex_colour[i:i + 2], 16)) for i in (1, 3, 5))


p = palette()
assets = Path(__file__).parent
config = Path.home() / ".config" / "obsidian" / "obsidian.json"
if not config.exists():
    sys.exit(0)

font = base64.b64encode((assets / "fonts" / "cinzel" / "Cinzel.ttf").read_bytes()).decode()
charms = "".join(f"    --hk-{n}: {c};\n    --hk-{n}-rgb: {rgb(c)};\n" for n, c in ((n, p[n]) for n in ("grimm", "gold", "unn", "lifeblood")))
css = f"""@font-face {{
    font-family: "Cinzel";
    src: url(data:font/ttf;base64,{font}) format("truetype");
    font-weight: 400 900;
}}

.theme-dark {{
    --hk-accent: {p["accent"]};
    --hk-steel: {p["steel"]};
    --hk-border: {p["steel"]}26;
    --hk-void: {p["void"]};
    --hk-shell: {p["shell"]};
    --hk-card: {p["card"]};
    --hk-text: {p["text"]};
    --hk-subtext: {p["subtext"]};
    --hk-faint: {p["faint"]};
{charms}}}

""" + (assets / "obsidian" / "hallownest.css").read_text()
theme = "moonstone" if p["light"] else "obsidian"
if p["light"]:
    css = css.replace(".theme-dark", ".theme-light")

for vault in json.loads(config.read_text()).get("vaults", {}).values():
    dot = Path(vault["path"]) / ".obsidian"
    if not dot.is_dir():
        continue
    (dot / "snippets").mkdir(exist_ok=True)
    (dot / "snippets" / "hallownest.css").write_text(css)

    appearance_file = dot / "appearance.json"
    appearance = json.loads(appearance_file.read_text() or "{}") if appearance_file.exists() else {}
    snippets = appearance.setdefault("enabledCssSnippets", [])
    if "hallownest" not in snippets or appearance.get("theme") != theme:
        if "hallownest" not in snippets:
            snippets.append("hallownest")
        appearance["theme"] = theme
        appearance_file.write_text(json.dumps(appearance, indent=2))
