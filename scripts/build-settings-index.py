#!/usr/bin/env python3
"""Build-time settings index extractor for the nexus settings search.

Parses the nexus page QML files, PageRegistry.qml (page icons/labels) and
PageCompRegistry.qml (page ordering and sub-page nesting) to produce a search
index as JSON. Run at build time (see CMakeLists.txt); the shell loads the
result at runtime via SettingsSearcher.qml.

The output contains three parts:
  - entries:  forward index, one record per setting (title, anchor, nav path)
  - inverted: token -> list of entry indices (classic inverted index)
  - ranking:  token -> {entry index: weight} precomputed match weights

Nothing here is hand-maintained per page: page metadata comes from
PageRegistry, the page tree from PageCompRegistry, and the directory layout is
discovered by walking the pages folder.

Usage: build-settings-index.py <nexus-dir> <output-json>
"""
from __future__ import annotations

import json
import re
import sys
from collections import defaultdict
from functools import lru_cache
from pathlib import Path


@lru_cache(maxsize=None)
def read_lines(path: Path) -> tuple[str, ...]:
    """Read a file's lines, cached so each page file is only read once."""
    return tuple(path.read_text().splitlines())

ROW_RE = re.compile(r'^\s*(ToggleRow|SliderRow|SelectRow|StepperRow|NavRow)\s*\{')
LABEL_RE = re.compile(r'^\s*(?:label|text):\s*qsTr\("([^"]+)"\)')
ANCHOR_RE = re.compile(r'^\s*settingAnchor:\s*"([^"]+)"')
ICON_RE = re.compile(r'^\s*icon:\s*"([^"]+)"')
SKIP_LABELS = {"Muted", "None"}
# Field weights for ranking: a token matching the title counts more than one
# matching the keywords blob.
FIELD_WEIGHT = {"title": 1.0, "keywords": 0.4}
STOPWORDS = {"the", "a", "an", "of", "and", "or", "to", "on", "in", "for"}


def find_pages_dir(nexus: Path) -> Path:
    return nexus / "pages"


def discover_files(nexus: Path) -> dict[str, Path]:
    """component name -> file path, discovered by walking pages/."""
    files: dict[str, Path] = {}
    for p in find_pages_dir(nexus).rglob("*.qml"):
        files[p.stem] = p
    return files


def parse_page_registry(nexus: Path) -> list[tuple[str, str]]:
    """Ordered (icon, label) for each *active* page entry in PageRegistry.
    Commented-out entries are ignored, matching pageComps ordering."""
    text = (nexus / "PageRegistry.qml").read_text()
    out: list[tuple[str, str]] = []
    # Each entry is a { ... } block with label/icon; commented lines start //.
    # Walk brace blocks at the array level.
    in_array = False
    depth = 0
    label = icon = None
    for line in text.splitlines():
        s = line.strip()
        if "pages:" in s and "[" in s:
            in_array = True
            continue
        if not in_array:
            continue
        if s.startswith("//"):
            continue
        if s.startswith("{"):
            depth += 1
            label = icon = None
            continue
        if s.startswith("}"):
            if label is not None:
                out.append((icon or "tune", label))
            depth -= 1
            continue
        if depth >= 1:
            m = LABEL_RE.match(line)
            if m and label is None:
                label = m.group(1)
            mi = ICON_RE.match(line)
            if mi and icon is None:
                icon = mi.group(1)
    return out


def parse_page_comps(nexus: Path) -> list[list[str]]:
    """Per top-level pageComps entry, ordered component names inside it."""
    text = (nexus / "PageCompRegistry.qml").read_text()
    body = text[text.index("pageComps:"):]
    comps: list[list[str]] = []
    current: list[str] | None = None
    for line in body.splitlines():
        if re.match(r"^        Component \{", line):
            current = []
            comps.append(current)
        m = re.search(r"([A-Z][A-Za-z]+)\s*\{\}", line)
        if m and current is not None:
            comps.append(current) if False else current.append(m.group(1))
    return comps


def build_nav_map(nexus: Path, files: dict[str, Path]) -> dict[str, dict]:
    comps = parse_page_comps(nexus)
    registry = parse_page_registry(nexus)

    # Top-level index -> (icon, label) from PageRegistry (same order as pageComps).
    top_meta: dict[int, tuple[str, str]] = {}
    for i, (icon, label) in enumerate(registry):
        top_meta[i] = (icon, label)

    # parentName -> {childPos: (icon, label)} from openSubPage() + nearby NavRow.
    nav_children: dict[str, dict[int, tuple[str, str]]] = {}
    for names in comps:
        for name in names:
            pf = files.get(name)
            if not pf:
                continue
            pending_icon = pending_label = None
            for ln in read_lines(pf):
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

    nav: dict[str, dict] = {}
    for top_idx, names in enumerate(comps):
        if not names:
            continue
        main = names[0]
        main_icon, main_label = top_meta.get(top_idx, ("tune", main))
        nav[main] = {"pageIdx": top_idx, "subPath": [],
                     "crumbIcons": [main_icon], "crumbLabels": [main_label]}
        for pos, (icon, label) in nav_children.get(main, {}).items():
            if pos >= len(names):
                continue
            child = names[pos]
            nav[child] = {"pageIdx": top_idx, "subPath": [pos],
                          "crumbIcons": [main_icon, icon],
                          "crumbLabels": [main_label, label]}
            for gpos, (gicon, glabel) in nav_children.get(child, {}).items():
                if gpos >= len(names):
                    continue
                nav[names[gpos]] = {
                    "pageIdx": top_idx, "subPath": [pos, gpos],
                    "crumbIcons": [main_icon, icon, gicon],
                    "crumbLabels": [main_label, label, glabel]}
    return nav


def tokenize(text: str) -> list[str]:
    toks: list[str] = []
    # Process word by word (split on whitespace) so we only collapse separators
    # inside a single word like "Wi-Fi" -> "wifi", not across a whole phrase.
    for word in text.lower().split():
        parts = [p for p in re.split(r"[^a-z0-9]+", word) if p]
        for p in parts:
            if p not in STOPWORDS and p not in toks:
                toks.append(p)
        if len(parts) > 1:
            joined = "".join(parts)
            if joined not in toks:
                toks.append(joined)
    return toks


SUBTEXT_RE = re.compile(r'^\s*subtext:\s*qsTr\("([^"]+)"\)')
SECTION_RE = re.compile(r'^\s*SectionHeader\s*\{')


def extract_settings(files: dict[str, Path], nav: dict[str, dict]) -> list[dict]:
    entries: list[dict] = []
    for comp, meta in nav.items():
        pf = files.get(comp)
        if not pf:
            continue
        lines = read_lines(pf)
        section = ""  # text of the most recent SectionHeader
        i = 0
        while i < len(lines):
            # Track the current section header so its words are searchable too.
            if SECTION_RE.match(lines[i]):
                for j in range(i + 1, min(i + 4, len(lines))):
                    m = LABEL_RE.match(lines[j])
                    if m:
                        section = m.group(1)
                        break
            if ROW_RE.match(lines[i]):
                label = anchor = subtext = None
                for j in range(i + 1, min(i + 12, len(lines))):
                    if label is None:
                        m = LABEL_RE.match(lines[j])
                        if m:
                            label = m.group(1)
                    if anchor is None:
                        a = ANCHOR_RE.match(lines[j])
                        if a:
                            anchor = a.group(1)
                    if subtext is None:
                        st = SUBTEXT_RE.match(lines[j])
                        if st:
                            subtext = st.group(1)
                if label and label not in SKIP_LABELS and anchor:
                    # keyword sources: breadcrumb path, section header, subtext.
                    extra = " ".join(meta["crumbLabels"]) + " " + section + " " + (subtext or "")
                    entries.append({
                        "pageIdx": meta["pageIdx"], "subPath": meta["subPath"],
                        "crumbIcons": meta["crumbIcons"],
                        "crumbLabels": meta["crumbLabels"],
                        "title": label, "anchor": anchor,
                        "section": section,
                        "subtext": subtext or "",
                        "keywords": " ".join(sorted(set(tokenize(label + " " + extra)))),
                    })
            i += 1
    return entries


def build_inverted_and_ranking(entries: list[dict]):
    """Classic inverted index + precomputed per-token ranking weights."""
    inverted: dict[str, list[int]] = defaultdict(list)
    ranking: dict[str, dict[int, float]] = defaultdict(dict)
    for idx, e in enumerate(entries):
        fields = {"title": e["title"], "keywords": e["keywords"]}
        seen: set[str] = set()
        for field, text in fields.items():
            weight = FIELD_WEIGHT.get(field, 0.2)
            for tok in tokenize(text):
                if idx not in inverted[tok]:
                    inverted[tok].append(idx)
                # accumulate the strongest field weight for this token/entry
                ranking[tok][idx] = max(ranking[tok].get(idx, 0.0), weight)
                seen.add(tok)
    # sort each posting list by descending rank so runtime can stop early
    for tok, ids in inverted.items():
        ids.sort(key=lambda i: ranking[tok][i], reverse=True)
    return inverted, {t: {str(k): v for k, v in d.items()} for t, d in ranking.items()}


def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__)
        return 1
    nexus = Path(sys.argv[1])
    out = Path(sys.argv[2])
    files = discover_files(nexus)
    nav = build_nav_map(nexus, files)
    entries = extract_settings(files, nav)
    inverted, ranking = build_inverted_and_ranking(entries)
    # keywords were only needed to build the inverted index; the runtime reads
    # the index, not the per-entry keyword blob, so drop it to shrink the JSON.
    for e in entries:
        e.pop("keywords", None)
    out.write_text(json.dumps({
        "version": 2,
        "entries": entries,
        "inverted": inverted,
        "ranking": ranking,
    }, ensure_ascii=False, indent=2))
    print(f"settings index: {len(entries)} entries, "
          f"{len(inverted)} tokens -> {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
