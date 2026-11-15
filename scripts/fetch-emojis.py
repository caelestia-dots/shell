#!/usr/bin/env python3
"""Generate the launcher emoji picker data from emojibase.

Usage: scripts/fetch-emojis.py [locale ...]

Writes:
  assets/emojis/emojis.json        English data (chars, groups, emoji version, keywords)
  assets/emojis/i18n/<locale>.json Localised keywords (hexcode -> "label tag tag ...")

Any locale available at https://github.com/milesj/emojibase/tree/master/packages/data can be passed,
e.g. `scripts/fetch-emojis.py de ja pt`. English is always generated.
"""

import json
import sys
from pathlib import Path
from urllib.error import HTTPError
from urllib.request import urlopen

BASE = "https://raw.githubusercontent.com/milesj/emojibase/refs/heads/master/packages/data"
ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "emojis"
EXCLUDE = Path(__file__).resolve().parent / "emoji-exclude.txt"

# emojibase group id -> picker group id. Smileys & emotion and people & body are merged (like WhatsApp)
# Groups not listed here (2 = components, None = regional indicators) are dropped.
GROUPS = {0: "people", 1: "people", 3: "nature", 4: "food", 5: "travel", 6: "activities", 7: "objects", 8: "symbols", 9: "flags"}


def fetch(locale: str, file: str = "compact.raw.json") -> list:
    with urlopen(f"{BASE}/{locale}/{file}") as f:
        return json.load(f)


def keywords(emoji: dict) -> str:
    words = [emoji["label"]]
    emoticon = emoji.get("emoticon")
    if isinstance(emoticon, str):
        words.append(emoticon)
    elif emoticon:
        words.extend(emoticon)
    words.extend(emoji.get("tags", []))

    # Dedupe while keeping order
    seen = set()
    return " ".join(w for w in words if not (w.lower() in seen or seen.add(w.lower())))


def load_excluded() -> set:
    if not EXCLUDE.exists():
        return set()
    lines = (l.strip() for l in EXCLUDE.read_text().splitlines())
    return {l.lower() for l in lines if l and not l.startswith("#")}


def main() -> None:
    locales = [l for l in sys.argv[1:] if l != "en"]
    excluded = load_excluded()

    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "i18n").mkdir(exist_ok=True)

    english = fetch("en")

    # The compact data doesn't have the emoji version. The picker uses it to hide emojis the installed font can't render
    versions = {e["hexcode"]: e.get("version", 0) for e in fetch("en", "data.raw.json")}
    kept = []
    used_excludes = set()
    seen_chars = set()
    for e in sorted(english, key=lambda e: e.get("order", 1 << 30)):
        group = GROUPS.get(e.get("group"))
        if group is None:
            continue
        if e["label"].lower() in excluded:
            used_excludes.add(e["label"].lower())
            continue

        # Skin tones are nested under "skins" and intentionally not included, only the default is
        char = e["unicode"]
        key = char.replace("\ufe0f", "")
        if key in seen_chars:
            continue
        seen_chars.add(key)

        kept.append({"c": char, "g": group, "h": e["hexcode"], "v": versions.get(e["hexcode"], 0), "k": keywords(e)})

    for missing in sorted(excluded - used_excludes):
        print(f"warning: exclude entry matched nothing: {missing!r}", file=sys.stderr)

    (OUT / "emojis.json").write_text(json.dumps({"items": kept}, ensure_ascii=False, separators=(",", ":")))
    print(f"en: {len(kept)} emojis")

    hexes = {e["h"] for e in kept}
    for locale in locales:
        try:
            data = fetch(locale)
        except HTTPError as err:
            print(f"{locale}: unavailable ({err.code}), skipping", file=sys.stderr)
            continue

        out = {e["hexcode"]: keywords(e) for e in data if e["hexcode"] in hexes}
        (OUT / "i18n" / f"{locale}.json").write_text(json.dumps(out, ensure_ascii=False, separators=(",", ":")))
        print(f"{locale}: {len(out)} entries")


if __name__ == "__main__":
    main()
