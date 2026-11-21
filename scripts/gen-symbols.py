#!/usr/bin/env python3
"""Generate the launcher symbol picker data from Python's Unicode database.

Usage: scripts/gen-symbols.py

Writes:
  assets/symbols/symbols.json  Chars, groups and search keywords

The characters of each group are listed in GROUPS below (pinned ones first, then whole Unicode ranges in code point
order), the keywords are the official Unicode names plus the hand written ALIASES. Nothing is downloaded, so the set of
available characters depends on the Unicode version of the Python running this (`python -c "import unicodedata;
print(unicodedata.unidata_version)"`). Characters without a name, control and formatting characters, spaces and
combining marks are always skipped.
"""

import json
import sys
import unicodedata
from pathlib import Path

OUT = Path(__file__).resolve().parent.parent / "assets" / "symbols"

SKIPPED_CATEGORIES = {"Mn", "Mc", "Me", "Cc", "Cf", "Cs", "Co", "Cn", "Zs", "Zl", "Zp"}

# Picker group id, extra keywords for the whole group, pinned characters, code point ranges (inclusive), skipped chars.
# The order matches the tab order in the picker (see modules/launcher/services/Symbols.qml)
GROUPS = [
    {
        "id": "arrows",
        "words": "arrow",
        "pinned": "←→↑↓↔↕↖↗↘↙⇐⇒⇑⇓⇔⇕↩↪↵↺↻↶↷➜➔➤➡⬅⬆⬇",
        "ranges": [(0x2190, 0x21FF), (0x2794, 0x27BE), (0x2B05, 0x2B07)],
    },
    {
        "id": "math",
        "words": "math",
        "pinned": "±×÷−∓≠≈≡≤≥≪≫∞√∛∜∑∏∫∂∆∇∈∉∋⊂⊃⊆⊇∪∩∧∨¬∀∃∄∅∴∵∝∠⊥∥°¼½¾⅓⅔⅕⅛⁰¹²³⁴⁵⁶⁷⁸⁹⁺⁻⁼⁽⁾ⁿ₀₁₂₃₄₅₆₇₈₉₊₋₌₍₎",
        "ranges": [(0x2200, 0x22FF), (0x2070, 0x208E), (0x2090, 0x209C), (0x2150, 0x215F), (0x00BC, 0x00BE)],
    },
    {
        "id": "greek",
        "words": "greek letter",
        "pinned": "αβγδεζηθικλμνξοπρστυφχψωΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩ",
        "ranges": [(0x0391, 0x03A9), (0x03B1, 0x03C9), (0x03D1, 0x03D6), (0x03F0, 0x03F5), (0x00B5, 0x00B5), (0x2126, 0x2126)],
    },
    {
        "id": "currency",
        "words": "currency money",
        "pinned": "$¢£¤¥€₩₹₽₺₿₪₫₴₦₱₡₲₵₸₼₾₭₮₳₠₣₤฿৳៛﷼؋",
        "ranges": [],
    },
    {
        "id": "text",
        "words": "punctuation",
        "pinned": "«»‹›“”‘’„‚—–…•·‣◦¶§†‡‰‼⁇⁈⁉‽¿¡※⁂¦¨´¸¯©®™℠℗№℃℉ℓ℮ℏℵ",
        "ranges": [(0x2010, 0x2027), (0x2030, 0x203E), (0x2047, 0x2049)],
    },
    {
        "id": "letters",
        "words": "latin letter",
        "pinned": "",
        "ranges": [(0x00C0, 0x00FF), (0x0100, 0x017F), (0x0192, 0x0192), (0x1E9E, 0x1E9E)],
        "skip": "×÷",
    },
    {
        "id": "shapes",
        "words": "shape",
        "pinned": "★☆■□▪▫▲△▴▵▶▷▸▹►▻▼▽▾▿◀◁◂◃◄◅◆◇◈●○◉◎◯◐◑◒◓",
        "ranges": [(0x25A0, 0x25FF)],
    },
    {
        "id": "box",
        "words": "box drawing line border block",
        "pinned": "─│┌┐└┘├┤┬┴┼═║╔╗╚╝╠╣╦╩╬░▒▓█▀▄▌▐",
        "ranges": [(0x2500, 0x259F)],
    },
    {
        "id": "misc",
        "words": "",
        # The keyboard keys are pinned so they win over the arrow range they're also part of
        "pinned": "⌘⌥⇧⌃⎋⌫⌦⏎⇥⇪⏏✓✔✗✘✕✖☐☑☒♥♡♠♣♦♪♫♬☀☁☂☃☺☹☎✉✂✎⚠⚙☠♻☯☮♀♂✿❀❤✈⚑⚐☢☣⚛⚖⚔",
        "ranges": [(0x2600, 0x26FF), (0x2701, 0x2793), (0x2460, 0x2473)],
    },
]

# Extra search keywords for characters whose Unicode name isn't what people would type
ALIASES = {
    "©": "copyright", "®": "registered trademark", "™": "trademark tm", "℠": "service mark sm", "№": "number numero no",
    "°": "degree degrees temperature", "℃": "celsius degree", "℉": "fahrenheit degree", "±": "plus minus",
    "×": "times multiply multiplication cross", "÷": "divide division obelus", "−": "minus subtract", "√": "square root radical",
    "∞": "infinity", "≈": "approximately almost equal", "≠": "not equal", "≤": "less than or equal", "≥": "greater than or equal",
    "∑": "sum summation sigma", "∏": "product", "∫": "integral", "∂": "partial derivative differential", "∆": "delta increment change",
    "∇": "nabla del gradient", "∅": "empty set null", "∈": "element member in", "∴": "therefore", "∵": "because", "¬": "not negation",
    "µ": "micro mu", "Ω": "omega ohm", "π": "pi", "‰": "per mille permille", "§": "section", "¶": "paragraph pilcrow",
    "†": "dagger obelisk", "‡": "double dagger", "•": "bullet dot", "…": "ellipsis dots", "—": "em dash", "–": "en dash",
    "¿": "inverted question mark spanish", "¡": "inverted exclamation mark spanish", "«": "guillemet quote left", "»": "guillemet quote right",
    "“": "quote left double", "”": "quote right double", "‘": "quote left single", "’": "quote right single apostrophe",
    "„": "quote low double", "‽": "interrobang", "※": "reference mark komejirushi", "€": "euro", "£": "pound sterling", "¥": "yen yuan",
    "¢": "cent", "₹": "rupee indian", "₩": "won korean", "₽": "ruble russian", "₿": "bitcoin btc", "₺": "lira turkish", "₱": "peso",
    "₫": "dong vietnamese", "₴": "hryvnia ukrainian", "₪": "shekel new sheqel israeli", "₦": "naira nigerian", "฿": "baht thai",
    "﷼": "rial", "ß": "eszett sharp s german", "æ": "ae ash ligature", "Æ": "ae ash ligature", "œ": "oe ligature", "Œ": "oe ligature",
    "ø": "o slash stroke", "Ø": "o slash stroke", "ð": "eth", "þ": "thorn", "å": "a ring", "Å": "a ring angstrom",
    "⌘": "command cmd mac apple", "⌥": "option alt mac", "⇧": "shift key", "⌃": "control ctrl key", "⎋": "escape esc key",
    "⌫": "backspace delete key", "⌦": "delete forward key", "⏎": "return enter key", "↵": "enter return carriage", "⇥": "tab key",
    "⇪": "caps lock key", "⏏": "eject",
    "✓": "check tick yes done", "✔": "check tick yes done heavy", "✗": "cross x no wrong", "✘": "cross x no wrong heavy",
    "✕": "cross x close", "✖": "cross x close heavy multiplication", "☐": "checkbox empty unchecked", "☑": "checkbox checked tick",
    "☒": "checkbox crossed", "♥": "heart love", "♡": "heart love outline", "❤": "heart love", "★": "star", "☆": "star outline",
    "♪": "music note eighth", "♫": "music notes beamed", "♬": "music notes", "☀": "sun sunny", "☁": "cloud", "☂": "umbrella rain",
    "☃": "snowman snow", "☺": "smile happy face", "☹": "frown sad face", "☎": "telephone phone", "✉": "envelope mail email letter",
    "✂": "scissors cut", "✎": "pencil write edit", "⚠": "warning caution danger", "⚙": "gear settings cog",
    "☠": "skull crossbones death", "♻": "recycle recycling", "☯": "yin yang", "☮": "peace", "♀": "female woman venus", "♂": "male man mars",
    "✿": "flower", "❀": "flower", "✈": "airplane plane flight", "⚑": "flag", "⚐": "flag", "☢": "radioactive nuclear", "☣": "biohazard",
    "⚛": "atom", "⚖": "scales balance justice", "⚔": "swords crossed",
    "←": "left", "→": "right", "↑": "up", "↓": "down", "↔": "left right both horizontal", "↕": "up down both vertical",
    "↩": "return back hook", "⇒": "implies double right", "⇔": "iff double both equivalent",
}


def chars_of(group: dict):
    for ch in group["pinned"]:
        yield ch
    for lo, hi in group["ranges"]:
        for cp in range(lo, hi + 1):
            yield chr(cp)


def usable(ch: str) -> bool:
    if unicodedata.category(ch) in SKIPPED_CATEGORIES:
        return False
    try:
        unicodedata.name(ch)
    except ValueError:
        return False
    return True


def keywords(ch: str, words: str) -> str:
    parts = [unicodedata.name(ch).lower(), ALIASES.get(ch, ""), words, f"u+{ord(ch):04x}", ch]

    # Dedupe whole words while keeping order
    seen = set()
    out = []
    for w in " ".join(p for p in parts if p).split():
        if w not in seen:
            seen.add(w)
            out.append(w)
    return " ".join(out)


def main() -> None:
    # Pinned characters of every group claim theirs first, so a pinned char wins over another group's range
    owner = {}
    for g in GROUPS:
        for ch in g["pinned"]:
            if usable(ch) and ch not in owner:
                owner[ch] = g["id"]
        missing = [ch for ch in g["pinned"] if not usable(ch)]
        if missing:
            print(f"warning: {g['id']}: pinned chars not available in this Unicode version: {''.join(missing)}", file=sys.stderr)

    items = []
    counts = {}
    emitted = set()
    for g in GROUPS:
        skip = set(g.get("skip", ""))
        for ch in chars_of(g):
            if ch in emitted or ch in skip or not usable(ch):
                continue
            if owner.get(ch, g["id"]) != g["id"]:
                continue
            emitted.add(ch)
            items.append({"c": ch, "g": g["id"], "k": keywords(ch, g["words"])})
            counts[g["id"]] = counts.get(g["id"], 0) + 1

    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "i18n").mkdir(exist_ok=True)
    lines = ",\n".join("  " + json.dumps(i, ensure_ascii=False, separators=(",", ":")) for i in items)
    (OUT / "symbols.json").write_text('{"items":[\n' + lines + "\n]}\n")

    print(f"unicode {unicodedata.unidata_version}: {len(items)} symbols")
    for gid, n in counts.items():
        print(f"  {gid}: {n}")


if __name__ == "__main__":
    main()
