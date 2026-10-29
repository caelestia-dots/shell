#!/usr/bin/env python3
"""Generate ~/.config/opencode/themes/caelestia.json from the current scheme.

Called from scripts/caelestia-quiet.py after each scheme change (colour JSON on
stdin + mode as argv[1]). The theme follows OpenCode V2's hue-based format
($schema https://opencode.ai/theme.json): one shared token tree (`base`) plus a
complete hue palette per mode, plus per-mode token overrides that surface the
scheme colours OpenCode cannot derive (text/bg containers, diff containers,
syntax roles).

The other mode's palette is preserved between runs: the pipeline runs with the
mode of the activity that changed, so dark and light are built up side by side.
"""

from __future__ import annotations

import copy
import json
import math
import sys
from pathlib import Path

from materialyoucolor.hct import Hct
from materialyoucolor.utils.color_utils import argb_from_rgb

THEME_PATH = Path.home() / ".config/opencode/themes/caelestia.json"
LADDER = (100, 200, 300, 400, 500, 600, 700, 800, 900)
TONES_DARK = (96, 93, 87, 79, 69, 57, 46, 33, 21)
TONES_LIGHT = (12, 21, 33, 46, 57, 69, 79, 87, 94)

# Target HCT hue bins for OpenCode's hue names. Sources below get assigned to
# the nearest bin, so the mapping survives any palette (M3, Catppuccin-flavoured
# fidelity variants, …) without hardcoding colour names that may not exist.
HUE_BINS = {"red": 25, "orange": 55, "yellow": 95, "green": 140, "cyan": 195, "blue": 260, "purple": 315}


def clamp(v: float, low: float, high: float) -> float:
    return max(low, min(high, v))


def hct_of(hex_color: str) -> Hct:
    rgb = (int(hex_color[0:2], 16), int(hex_color[2:4], 16), int(hex_color[4:6], 16))
    return Hct.from_int(argb_from_rgb(*rgb))


def tone(hex_color: str) -> float:
    return hct_of(hex_color).tone


def css(h: Hct, tone_value: float) -> str:
    out = Hct.from_hct(h.hue, h.chroma, tone_value).to_rgba()
    r, g, b = out[0], out[1], out[2]
    return f"{r:02x}{g:02x}{b:02x}"


def hue_distance(a: float, b: float) -> float:
    d = abs(a - b) % 360.0
    return min(d, 360.0 - d)


def pick_sources(colours: dict[str, str]) -> dict[str, str]:
    """Assign every OpenCode hue bin the nearest-hue source colour available."""
    wanted = [
        "primaryPaletteKeyColor",
        "secondaryPaletteKeyColor",
        "tertiaryPaletteKeyColor",
        "errorPaletteKeyColor",
    ]
    wanted += [k for k in ("kpositive", "kneutral", "klink") if k in colours]
    wanted += [f"term{i}" for i in range(1, 7) if f"term{i}" in colours]
    names = [n for n in wanted if n in colours]
    if not names:
        return {}
    sources: dict[str, str] = {}
    taken: set[str] = set()
    # Sort bins by their best candidate confidence to make greedy assignment stable.
    probes = {hue: min((hue_distance(hct_of(colours[n]).hue, target), n) for n in names) for hue, target in HUE_BINS.items()}
    for hue in sorted(probes, key=lambda x: probes[x][0]):
        best: tuple[float, str] | None = None
        for name in names:
            if name in taken:
                continue
            dist = hue_distance(hct_of(colours[name]).hue, HUE_BINS[hue])
            if best is None or dist < best[0]:
                best = (dist, name)
        if best is not None:
            taken.add(best[1])
            sources[hue] = colours[best[1]]
    return sources


def build_hue_scales(colours: dict[str, str], mode: str, sources: dict[str, str]) -> dict[str, dict[str, str] | str]:
    tones = TONES_DARK if mode == "dark" else TONES_LIGHT
    text_hex = colours.get("onSurface") or colours.get("text") or "ffffff"
    bg_hex = colours.get("background") or colours.get("base") or "000000"
    outline_hex = colours.get("outline") or colours.get("onSurfaceVariant") or text_hex
    overlay2_hex = colours.get("overlay2") or outline_hex
    neutral_hex = colours.get("neutralPaletteKeyColor") or colours.get("neutral_paletteKeyColor") or outline_hex
    # Gray honours the scheme's own anchors so text/background resolve exactly.
    gray_anchor_top = tone(text_hex)
    gray_anchor_bottom = tone(bg_hex)
    gray_anchors = {
        "100": gray_anchor_top,
        "300": tone(outline_hex),
        "500": tone(overlay2_hex),
        "900": gray_anchor_bottom,
    }
    # Interpolate missing steps between available anchors (tone axis).
    gray_scale: dict[str, str] = {}
    anchor_steps = [int(step) for step, value in gray_anchors.items() if value is not None]
    anchor_steps.sort()
    for i, step in enumerate(anchor_steps):
        value = gray_anchors[str(step)]
        next_value = gray_anchors[str(anchor_steps[i + 1])] if i + 1 < len(anchor_steps) else None
        start = LADDER.index(step)
        end = LADDER.index(anchor_steps[i + 1]) if next_value is not None else len(LADDER) - 1
        gray = hct_of(colours.get("neutralPaletteKeyColor", neutral_hex))
        gray = Hct.from_hct(gray.hue, clamp(gray.chroma, 0, 6), value)
        for j, s in enumerate(LADDER[start : end + 1]):
            if j == 0:
                gray_scale[str(s)] = css(gray, value)
            elif next_value is not None:
                frac = (j) / (end - start)
                gray_scale[str(s)] = css(gray, value + (next_value - value) * frac)
            else:
                gray_scale[str(s)] = css(gray, value)
    # Deduplicate toward monotone (anchors may not be monotone in weird schemes);
    # enforce by clamping onward values.
    mono = 255.0 if mode == "dark" else 0.0
    fixed: dict[str, str] = {}
    for s in LADDER:
        h = gray_scale[str(s)]
        t = tone(h)
        t = min(t, mono) if mode == "dark" else max(t, mono)
        fixed[str(s)] = css(Hct.from_hct(hct_of(h).hue, hct_of(h).chroma, t), t)
        mono = t
    gray_scale = fixed

    hue: dict[str, object] = {"gray": gray_scale}
    max_chroma = {"gray": 6, "cyan": 24, "blue": 40, "purple": 40, "red": 44, "orange": 44, "yellow": 36, "green": 36}
    for name in ("red", "orange", "yellow", "green", "cyan", "blue", "purple"):
        src = sources.get(name, colours.get("primaryPaletteKeyColor", colours.get("primary", "#888888")))
        h = hct_of(src)
        h = Hct.from_hct(HUE_BINS[name], clamp(h.chroma, 8, max_chroma[name]), tones[4])
        hue[name] = {str(s): css(h, t) for s, t in zip(LADDER, tones)}
    hue["accent"] = hue.get("orange") if "orange" in sources else hue["blue"]  # placeholder, fixed below
    return hue


PRIMARY_BIN_FALLBACK = "blue"


def finalize_aliases(hue: dict[str, object], sources: dict[str, str], colours: dict[str, str], mode: str) -> None:
    primary_hex = colours.get("primaryPaletteKeyColor") or colours.get("primary") or "#888888"
    primary_h = hct_of(primary_hex).hue
    bin_name = min(HUE_BINS, key=lambda name: hue_distance(primary_h, HUE_BINS[name]))
    # Only keep the alias if the assigned scale really came from a source near
    # the primary hue; otherwise fall back to blue so accents stay "primary-like".
    chosen = bin_name if hue_distance(primary_h, HUE_BINS[bin_name]) < 45 or bin_name in sources else PRIMARY_BIN_FALLBACK
    hue["accent"] = deepcopy_hue(hue, chosen)
    hue["interactive"] = deepcopy_hue(hue, chosen)
    hue["neutral"] = "$hue.gray"


def deepcopy_hue(hue: dict[str, object], name: str) -> dict[str, str] | str:
    value = hue.get(name)
    if isinstance(value, dict):
        return dict(value)  # type: ignore[return-value]
    return "$hue." + name  # type: ignore[return-value]


BASE_TREE = {
    "categorical": ["accent", "blue", "green", "orange", "red"],
    "text": {
        "base": "$hue.neutral.100",
        "muted": "$hue.neutral.200",
        "faint": "$hue.neutral.300",
        "action": {
            "primary": {"base": "$hue.accent.400", "$hovered": "$hue.accent.300", "$disabled": "$hue.neutral.400", "$selected": "$hue.accent.200"},
            "secondary": {"base": "$hue.neutral.200", "$hovered": "$hue.neutral.100"},
            "destructive": {"base": "$hue.red.400", "$disabled": "$hue.neutral.400"},
        },
        "formfield": {
            "base": "$hue.neutral.100",
            "$hovered": "$hue.interactive.400",
            "$focused": "$hue.interactive.400",
            "$pressed": "$hue.interactive.400",
            "$disabled": "$hue.neutral.300",
            "$selected": "$hue.interactive.400",
        },
        "feedback": {
            "error": {"base": "$hue.red.400"},
            "warning": {"base": "$hue.orange.400"},
            "success": {"base": "$hue.green.400"},
            "info": {"base": "$hue.cyan.400"},
        },
    },
    "background": {
        "base": "$hue.neutral.900",
        "raised": {"base": "$hue.neutral.800", "high": "$hue.neutral.700", "max": "$hue.neutral.600"},
        "action": {
            "primary": {"base": "transparent", "$hovered": "$hue.neutral.700", "$focused": "$hue.interactive.600", "$selected": "transparent"},
            "secondary": {"base": "transparent"},
            "destructive": {"base": "$hue.red.700"},
        },
        "formfield": {"base": "$hue.neutral.900"},
        "feedback": {"error": {"base": "$hue.neutral.900"}, "warning": {"base": "$hue.neutral.900"}, "success": {"base": "$hue.neutral.900"}, "info": {"base": "$hue.neutral.900"}},
    },
    "border": {"base": "$hue.neutral.600"},
    "scrollbar": {"base": "$hue.neutral.600"},
    "diff": {
        "text": {"added": "$hue.green.400", "removed": "$hue.red.400", "context": "$hue.neutral.200", "hunkHeader": "$hue.neutral.200"},
        "background": {"added": "$hue.green.900", "removed": "$hue.red.900", "context": "$hue.neutral.900"},
        "highlight": {"added": "$hue.green.300", "removed": "$hue.red.300"},
        "lineNumber": {"text": "$hue.neutral.400", "background": {"added": "$hue.green.900", "removed": "$hue.red.900"}},
    },
    "syntax": {
        "comment": "$hue.neutral.400",
        "keyword": "$hue.accent.300",
        "function": "$hue.cyan.400",
        "variable": "$hue.neutral.100",
        "string": "$hue.green.400",
        "number": "$hue.orange.400",
        "type": "$hue.purple.400",
        "operator": "$hue.blue.400",
        "punctuation": "$hue.neutral.200",
    },
    "markdown": {
        "text": "$hue.neutral.100",
        "heading": "$hue.accent.300",
        "link": "$hue.cyan.400",
        "linkText": "$hue.cyan.300",
        "code": "$hue.green.400",
        "blockQuote": "$hue.orange.400",
        "emphasis": "$hue.orange.400",
        "strong": "$hue.neutral.100",
        "horizontalRule": "$hue.neutral.400",
        "listItem": "$hue.accent.400",
        "listEnumeration": "$hue.cyan.400",
        "image": "$hue.cyan.300",
        "imageText": "$hue.green.400",
        "codeBlock": "$hue.neutral.100",
    },
}


def scheme_overrides(colours: dict[str, str], mode: str) -> dict:
    """Explicit scheme colours OpenCode better not derive from hue steps.

    Input colours are already normalised without the leading '#'; every value
    below is wrapped again with '#' for OpenCode, which requires '#rrggbb'.
    """
    hex_ = lambda c: f"#{c}" if c else None  # noqa: E731
    darken = mode == "dark"
    container_lows = [colours.get(k) for k in ("surfaceContainerLowest", "surfaceContainerLow", "surfaceContainer", "surfaceContainerHigh", "surfaceContainerHighest")]
    if not all(container_lows):
        container_lows = [colours.get("surfaceDim"), colours.get("surface"), colours.get("surfaceContainer"), colours.get("surfaceContainerHigh"), colours.get("surfaceBright")]
    container_lows = [c for c in container_lows if c]
    if not container_lows:
        return {}
    lowest, low, mid, high, highest = (container_lows + [None] * 5)[:5]

    def fg_container(bg: str, fg_key_on: str, fg_key: str) -> str:
        return colours.get(fg_key_on) or colours.get(fg_key) or colours["onSurface"]

    def on_container(bg: str, prefer: str, fallback: str) -> str:
        return colours.get(prefer) or colours.get(fallback) or colours["onSurface"]

    return {
        "text": {
            "base": colours.get("onSurface") or colours.get("text"),
            "muted": colours.get("onSurfaceVariant") or colours.get("subtext1") or colours.get("outline"),
            "faint": colours.get("outline") or colours.get("overlay2"),
            "action": {
                "primary": {"base": colours.get("primaryDim") or colours.get("primary")},
                "destructive": {"base": colours.get("errorDim") or colours.get("error")},
            },
            "feedback": {
                "error": {"base": colours.get("errorDim") or colours.get("error")},
                "warning": {"base": colours.get("kpositive") or colours.get("term3") or colours.get("peach")},
                "success": {"base": colours.get("klink") or colours.get("term10") or colours.get("sapphire")},
                "info": {"base": colours.get("kneutral") or colours.get("term11") or colours.get("teal")},
            },
        },
        "background": {
            "base": colours.get("background"),
            "raised": {"base": low, "high": high, "max": highest},
            "action": {
                "primary": {"base": colours.get("primaryContainer"), "$hovered": fg_container(low if darken and False else low, "", "")},
                "destructive": {"base": colours.get("errorContainer")},
            },
        },
        "border": {"base": colours.get("outlineVariant") or colours.get("outline")},
        "scrollbar": {"base": colours.get("overlay1") or colours.get("outline")},
        "diff": {
            "background": {
                "added": colours.get("successContainer"),
                "removed": colours.get("errorContainer"),
                "context": mid,
            },
            "lineNumber": {"background": {"added": colours.get("successContainer"), "removed": colours.get("errorContainer")}},
        },
        "syntax": {
            "comment": colours.get("outline"),
            "keyword": colours.get("primaryFixedDim") or colours.get("primary"),
            "function": colours.get("secondaryDim") or colours.get("secondary"),
            "variable": colours.get("onSurface") or colours.get("text"),
            "string": colours.get("success") or colours.get("teal"),
            "number": colours.get("kpositive") or colours.get("term3") or colours.get("peach"),
            "type": colours.get("kvisited") or colours.get("sapphire") or colours.get("sky"),
            "operator": colours.get("kneutralSelection") or colours.get("kneutral") or colours.get("mauve"),
            "punctuation": colours.get("onSurfaceVariant") or colours.get("subtext1"),
        },
        "markdown": {
            "heading": colours.get("primaryDim") or colours.get("primary"),
            "link": colours.get("tertiaryDim") or colours.get("tertiary"),
            "linkText": colours.get("pink") or colours.get("rosewater") or colours.get("tertiary"),
            "code": colours.get("kpositive") or colours.get("peach"),  # inline code accent
            "image": colours.get("sapphire") or colours.get("sky"),
            "imageText": colours.get("teal") or colours.get("sapphire"),
        },
    }


def prune_missing(overrides: dict) -> dict:
    return {k: v for k, v in overrides.items() if v is not None}


def clean(obj):
    """Recursively drop None/absent values so the JSON validates."""
    if isinstance(obj, dict):
        return {k: clean(v) for k, v in obj.items() if v is not None and k not in (None,)}
    if isinstance(obj, list):
        return [clean(v) for v in obj]
    return obj


def overlay(base: dict, overrides: dict) -> dict:
    out = copy.deepcopy(base)
    for key, value in overrides.items():
        if key is None:
            continue
        if value is None:
            out.pop(key, None)
        elif isinstance(value, dict) and isinstance(out.get(key), dict):
            out[key] = overlay(out[key], value)
        else:
            out[key] = value
    return out


def hash_leaves(obj) -> dict:
    """Add the leading '#' to every leaf colour of the override tree.

    Overrides are built from scheme colours (no '#' in the scheme JSON) and
    never contain hue references, so a blanket prefix is safe.
    """
    if isinstance(obj, dict):
        return {k: hash_leaves(v) for k, v in obj.items()}
    if isinstance(obj, str):
        return f"#{obj}"
    return obj


def generate(mode: str, colours: dict[str, str]) -> dict:
    sources = pick_sources(colours)  # computed once, shared by hue scales and aliases
    hue_section = hash_leaves(build_hue_scales(colours, mode, sources))
    finalize_aliases(hue_section, sources, colours, mode)
    overrides = hash_leaves(prune_missing(scheme_overrides(colours, mode)))
    section: dict = {"hue": hue_section}
    section = overlay(section, overrides)
    return section


def main() -> None:
    try:
        payload = json.loads(sys.stdin.read() or "{}")
    except json.JSONDecodeError as error:
        print(f"opencode-theme: invalid stdin JSON: {error}", file=sys.stderr)
        sys.exit(1)
    mode = sys.argv[1] if len(sys.argv) > 1 else "dark"
    if mode not in ("dark", "light"):
        mode = "dark"

    existing: dict = {}
    if THEME_PATH.is_file():
        try:
            existing = json.loads(THEME_PATH.read_text())
        except json.JSONDecodeError:
            existing = {}

    colours = {k: v.removeprefix("#") for k, v in payload.items() if isinstance(v, str)}
    if not colours.get("primary"):
        print("opencode-theme: no primary colour on stdin, skipping", file=sys.stderr)
        sys.exit(1)

    theme = {"$schema": "https://opencode.ai/theme.json", "base": copy.deepcopy(BASE_TREE)}
    if existing:
        # Preserve the other mode's palette but always refresh the shared tree
        # (it is shared for a reason: keeping a stale base would resurrect
        # token shapes from older generator versions).
        for mode_key in ("light", "dark"):
            if mode_key != mode and mode_key in existing:
                theme[mode_key] = existing[mode_key]
    theme[mode] = generate(mode, colours)

    THEME_PATH.parent.mkdir(parents=True, exist_ok=True)
    THEME_PATH.write_text(json.dumps(theme, indent=2) + "\n")


if __name__ == "__main__":
    main()
