#!/usr/bin/env python3
"""Build-time settings index extractor for the nexus settings search.

Parses the nexus page QML files and PageCompRegistry.qml to produce a flat
settings index as JSON. Run at build time (see CMakeLists.txt); the shell loads
the result at runtime via SettingsIndex.qml.

Usage: build-settings-index.py <nexus-dir> <output-json>
  nexus-dir   path to modules/nexus
  output-json where to write settings-index.json
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

# Rows that carry a searchable setting and the label property they expose.
ROW_RE = re.compile(r'^\s*(ToggleRow|SliderRow|SelectRow|StepperRow|NavRow)\s*\{')
LABEL_RE = re.compile(r'^\s*(?:label|text):\s*qsTr\("([^"]+)"\)')
ANCHOR_RE = re.compile(r'^\s*settingAnchor:\s*"([^"]+)"')
ICON_RE = re.compile(r'^\s*icon:\s*"([^"]+)"')
# Labels that are too generic to index on their own.
SKIP_LABELS = {"Muted", "None"}

# Page metadata: maps a page component name to its top-level pageComps index,
# icon, and human label. Pulled from PageRegistry; sub-pages add their own icon.
PAGE_META = {
    "WallpaperAndStyle": ("palette", "Wallpaper & style"),
    "NetworkPage": ("wifi", "Network"),
    "BluetoothPage": ("devices_other", "Bluetooth"),
    "AudioPage": ("volume_up", "Audio"),
    "PanelsPage": ("dock_to_bottom", "Panels"),
    "AppsPage": ("apps", "Apps"),
    "ServicesPage": ("build", "Services"),
    "LanguageAndRegion": ("globe", "Language & region"),
}


def parse_page_comps(path: Path) -> list[list[str]]:
    """Return, per top-level pageComps entry, the ordered list of page
    component names inside it (index 0 is the main page, rest are sub-pages)."""
    text = path.read_text()
    # Grab the pageComps array body.
    start = text.index("pageComps:")
    body = text[start:]
    comps: list[list[str]] = []
    depth = 0
    current: list[str] | None = None
    # Walk lines tracking the top-level Component blocks (8-space indent).
    for line in body.splitlines():
        if re.match(r"^        Component \{", line):
            current = []
            comps.append(current)
        m = re.search(r"([A-Z][A-Za-z]+)\s*\{\}", line)
        if m and current is not None:
            current.append(m.group(1))
    return comps


def build_nav_map(nexus: Path) -> dict[str, dict]:
    """Map each page component name -> {pageIdx, subPath, crumbIcons,
    crumbLabels}. Sub-page paths are derived from openSubPage() calls in their
    parent pages plus the pageComps ordering."""
    comps = parse_page_comps(nexus / "PageCompRegistry.qml")

    # Component name -> (top index, position within its StackPage)
    location: dict[str, tuple[int, int]] = {}
    for top_idx, names in enumerate(comps):
        for pos, name in enumerate(names):
            location.setdefault(name, (top_idx, pos))

    # For the main page of each top entry, find openSubPage(N) -> which child,
    # and the NavRow icon/label that triggers it, to build breadcrumbs.
    # Parent page file -> list of (childPos, icon, label)
    def page_file(name: str) -> Path | None:
        for sub in ("", "panels", "panels/taskbar", "services", "apps",
                    "bluetooth", "audio", "wallandstyle"):
            p = nexus / "pages" / sub / f"{name}.qml" if sub else nexus / "pages" / f"{name}.qml"
            if p.exists():
                return p
        return None

    # Build child nav info: parentName -> {childPos: (icon, label)}
    # Scan every page file (main and sub-pages) for openSubPage() calls so deep
    # chains like Taskbar -> Workspaces are captured.
    nav_children: dict[str, dict[int, tuple[str, str]]] = {}
    for names in comps:
        for name in names:
            pf = page_file(name)
            if not pf:
                continue
            lines = pf.read_text().splitlines()
            pending_icon = None
            pending_label = None
            for ln in lines:
                mi = ICON_RE.match(ln)
                if mi:
                    pending_icon = mi.group(1)
                ml = LABEL_RE.match(ln)
                if ml:
                    pending_label = ml.group(1)
                mo = re.search(r"openSubPage\((\d+)\)", ln)
                if mo:
                    pos = int(mo.group(1))
                    nav_children.setdefault(name, {})[pos] = (
                        pending_icon or "tune", pending_label or "")
                    pending_icon = pending_label = None

    # Now assemble nav map per component.
    nav: dict[str, dict] = {}
    for top_idx, names in enumerate(comps):
        if not names:
            continue
        main = names[0]
        main_icon, main_label = PAGE_META.get(main, ("tune", main))
        # main page
        nav[main] = {
            "pageIdx": top_idx, "subPath": [],
            "crumbIcons": [main_icon], "crumbLabels": [main_label],
        }
        # direct children reachable from main via openSubPage
        for pos, (icon, label) in nav_children.get(main, {}).items():
            if pos >= len(names):
                continue
            child = names[pos]
            nav[child] = {
                "pageIdx": top_idx, "subPath": [pos],
                "crumbIcons": [main_icon, icon], "crumbLabels": [main_label, label],
            }
            # grandchildren: children of this child (e.g. Taskbar -> Bar*)
            for gpos, (gicon, glabel) in nav_children.get(child, {}).items():
                if gpos >= len(names):
                    continue
                gchild = names[gpos]
                nav[gchild] = {
                    "pageIdx": top_idx, "subPath": [pos, gpos],
                    "crumbIcons": [main_icon, icon, gicon],
                    "crumbLabels": [main_label, label, glabel],
                }
    return nav


def slug(s: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", s.lower()).strip("-")


def extract_settings(nexus: Path, nav: dict[str, dict]) -> list[dict]:
    entries: list[dict] = []
    for comp, meta in nav.items():
        # find the file for this component
        pf = None
        for sub in ("", "panels", "panels/taskbar", "services", "apps",
                    "bluetooth", "audio", "wallandstyle"):
            p = (nexus / "pages" / sub / f"{comp}.qml") if sub else (nexus / "pages" / f"{comp}.qml")
            if p.exists():
                pf = p
                break
        if not pf:
            continue
        lines = pf.read_text().splitlines()
        i = 0
        while i < len(lines):
            if ROW_RE.match(lines[i]):
                label = anchor = None
                for j in range(i + 1, min(i + 10, len(lines))):
                    if label is None:
                        m = LABEL_RE.match(lines[j])
                        if m:
                            label = m.group(1)
                    if anchor is None:
                        a = ANCHOR_RE.match(lines[j])
                        if a:
                            anchor = a.group(1)
                if label and label not in SKIP_LABELS and anchor:
                    kw = set(label.lower().split())
                    for cl in meta["crumbLabels"]:
                        kw |= set(cl.lower().replace("&", "").split())
                    entries.append({
                        "pageIdx": meta["pageIdx"],
                        "subPath": meta["subPath"],
                        "crumbIcons": meta["crumbIcons"],
                        "crumbLabels": meta["crumbLabels"],
                        "title": label,
                        "anchor": anchor,
                        "keywords": " ".join(sorted(w for w in kw if w)),
                    })
            i += 1
    return entries


def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__)
        return 1
    nexus = Path(sys.argv[1])
    out = Path(sys.argv[2])
    nav = build_nav_map(nexus)
    entries = extract_settings(nexus, nav)
    out.write_text(json.dumps({"version": 1, "entries": entries}, ensure_ascii=False, indent=2))
    print(f"settings index: {len(entries)} entries -> {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
