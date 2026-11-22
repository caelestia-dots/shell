#!/usr/bin/env python3
"""Generates the Hollow Knight colour schemes for caelestia-cli from assets/styles.json.

Every style (hallownest, pale, beezone, void, grimm, cityoftears, kingdomsedge, queensgardens) has
the four flavours. Surfaces, text and
terminal greys come from the style's base; primary/secondary/tertiary/error/success from the flavour.
"light" styles get light.txt with dark accents on light surfaces; "mono" styles keep the hallownest
terminal hues so diffs and prompts stay readable.

Output: assets/schemes/hollowknight/<flavour>/<mode>.txt for hallownest and <style>-<flavour>/<mode>.txt
for the rest, which caelestia-cli reads once the folder is linked into its schemes dir (see the README
section in assets/schemes/hollowknight).

Edit assets/styles.json and rerun: python3 scripts/gen-hollowknight-scheme.py
"""

import json
from pathlib import Path

ASSETS = Path(__file__).resolve().parent.parent / "assets"


def rgb(hex_):
    return [int(hex_[i : i + 2], 16) for i in (0, 2, 4)]


def hexc(c):
    return "".join(f"{max(0, min(255, round(v))):02x}" for v in c)


def mix(a, b, t):
    """Mixes colour a towards b by t (0 = a, 1 = b)."""
    ca, cb = rgb(a), rgb(b)
    return hexc([x + (y - x) * t for x, y in zip(ca, cb)])


def accent(name, c, bg, light=False):
    """Material-like tonal roles: a light accent on a dark surface, or the reverse when light."""
    ink, paper = ("ffffff", "000000") if light else ("000000", "ffffff")
    return {
        name: c,
        f"{name}Dim": mix(c, ink, 0.1),
        f"on{name.capitalize()}": mix(c, ink, 0.78),
        f"{name}Container": mix(c, bg, 0.74),
        f"on{name.capitalize()}Container": mix(c, paper, 0.55),
        f"{name}Fixed": mix(c, paper, 0.35),
        f"{name}FixedDim": mix(c, paper, 0.2),
        f"on{name.capitalize()}Fixed": mix(c, ink, 0.78),
        f"on{name.capitalize()}FixedVariant": mix(c, ink, 0.55),
    }


def scheme(style, flavour, terminal):
    b = {k: v.lstrip("#") for k, v in style["base"].items()}
    f = {k: v.lstrip("#") for k, v in style["flavours"][flavour].items()}
    light = style.get("light", False)
    mono = style.get("mono", False)
    ink, paper = ("ffffff", "000000") if light else ("000000", "ffffff")
    tones = {k: v["accent"].lstrip("#") for k, v in terminal["flavours"].items()}
    primary, steel, tertiary, error, success = f["accent"], f["steel"], f["tertiary"], f["error"], f["success"]
    bg = mix(b["void"], b["shell"], 0.5)
    highest = mix(b["button"], b["bright"], 0.4)
    variant = mix(b["subtext"], b["text"], 0.35)
    s = {
        "background": bg,
        "onBackground": b["text"],
        "surface": bg,
        "surfaceDim": bg,
        "surfaceBright": b["bright"],
        "surfaceContainerLowest": b["void"],
        "surfaceContainerLow": b["shell"],
        "surfaceContainer": mix(b["shell"], b["card"], 0.5),
        "surfaceContainerHigh": b["button"],
        "surfaceContainerHighest": highest,
        "onSurface": b["text"],
        "surfaceVariant": highest,
        "onSurfaceVariant": variant,
        "outline": b["outline"],
        "outlineVariant": mix(b["bright"], b["outline"], 0.3),
        "inverseSurface": b["text"],
        "inverseOnSurface": mix(highest, b["bright"], 0.5),
        "shadow": "000000",
        "scrim": "000000",
        "surfaceTint": primary,
    }
    s |= accent("primary", primary, bg, light)
    s["inversePrimary"] = mix(primary, ink, 0.45)
    s |= accent("secondary", steel, bg, light)
    s |= accent("tertiary", tertiary, bg, light)

    s |= {
        "error": error,
        "errorDim": mix(error, ink, 0.1),
        "onError": mix(error, ink, 0.78),
        "errorContainer": mix(error, bg, 0.7),
        "onErrorContainer": mix(error, paper, 0.55),
        "success": success,
        "onSuccess": mix(success, ink, 0.78),
        "successContainer": mix(success, bg, 0.72),
        "onSuccessContainer": mix(success, paper, 0.55),
    }

    for role, c in (("primary", primary), ("secondary", steel), ("tertiary", tertiary)):
        key = mix(c, "000000", 0.35)
        s[f"{role}PaletteKeyColor"] = key
        s[f"{role}_paletteKeyColor"] = key
    s["neutralPaletteKeyColor"] = s["neutral_paletteKeyColor"] = mix(b["outline"], b["void"], 0.2)
    s["neutralVariantPaletteKeyColor"] = s["neutral_variant_paletteKeyColor"] = mix(b["outline"], b["void"], 0.15)
    s["errorPaletteKeyColor"] = mix(error, "000000", 0.35)

    if mono:
        hues = {
            "term0": highest,
            "term1": mix(b["outline"], b["subtext"], 0.25),
            "term2": tones["greenpath"],
            "term3": mix(b["subtext"], b["text"], 0.2),
            "term4": mix(b["outline"], b["subtext"], 0.55),
            "term5": mix(b["subtext"], b["text"], 0.4),
            "term6": tones["lifeblood"],
            "term7": mix(b["text"], b["subtext"], 0.2),
            "term8": mix(b["outline"], b["void"], 0.3),
            "term9": mix(b["outline"], b["subtext"], 0.65),
            "term10": mix(b["subtext"], b["text"], 0.35),
            "term11": mix(b["subtext"], b["text"], 0.6),
            "term12": mix(b["subtext"], b["text"], 0.45),
            "term13": mix(b["subtext"], b["text"], 0.7),
            "term14": mix(b["subtext"], b["text"], 0.8),
            "term15": b["text"],
            "rosewater": mix(b["subtext"], b["text"], 0.75),
            "flamingo": mix(b["subtext"], b["text"], 0.55),
            "pink": mix(b["subtext"], b["text"], 0.45),
            "mauve": mix(b["outline"], b["subtext"], 0.75),
            "red": error,
            "maroon": mix(b["outline"], b["subtext"], 0.5),
            "peach": tones["infection"],
            "yellow": tertiary,
            "green": tones["greenpath"],
            "teal": mix(b["subtext"], b["text"], 0.3),
            "sky": mix(b["subtext"], b["text"], 0.65),
            "sapphire": tones["lifeblood"],
            "blue": mix(b["outline"], b["subtext"], 0.6),
            "lavender": mix(b["subtext"], b["text"], 0.5),
        }
    else:
        # Terminal: style greys, infection reds/oranges, greenpath, lifeblood, dream nail pinks
        hues = {
            "term0": highest,
            "term1": "ff6a4d",
            "term2": tones["greenpath"],
            "term3": "ffb054",
            "term4": "7aa7ff",
            "term5": "d77bd0",
            "term6": tones["lifeblood"],
            "term7": mix(b["text"], b["subtext"], 0.2),
            "term8": mix(b["outline"], b["void"], 0.3),
            "term9": "ff8c73",
            "term10": "9bdcab",
            "term11": "ffc77f",
            "term12": "9cc1ff",
            "term13": "e7a2e2",
            "term14": "9adcff",
            "term15": b["text"],
            "rosewater": "f2e6dc",
            "flamingo": "eacbc0",
            "pink": "e7a2e2",
            "mauve": "c79ae8",
            "red": "ff6a4d",
            "maroon": "e38a7d",
            "peach": tones["infection"],
            "yellow": "ffc77f",
            "green": tones["greenpath"],
            "teal": "6fd1c0",
            "sky": "8fd8ff",
            "sapphire": tones["lifeblood"],
            "blue": "7aa7ff",
            "lavender": "b3b8ff",
        }

    # Catppuccin-style surface names used by some templates
    hues |= {
        "text": b["text"],
        "subtext1": mix(b["text"], b["subtext"], 0.4),
        "subtext0": variant,
        "overlay2": mix(b["subtext"], b["outline"], 0.5),
        "overlay1": b["outline"],
        "overlay0": mix(b["outline"], b["faint"], 0.5),
        "surface2": mix(b["bright"], b["outline"], 0.2),
        "surface1": mix(highest, b["bright"], 0.5),
        "surface0": highest,
        "base": bg,
        "mantle": mix(b["void"], bg, 0.5),
        "crust": b["void"],
    }

    if light:
        greys = ("term0", "term7", "term8", "term15", "text", "subtext1", "subtext0", "overlay2", "overlay1", "overlay0",
                 "surface2", "surface1", "surface0", "base", "mantle", "crust",
                 # Flavour accents, already dark in a light style
                 "term2", "term6", "peach", "green", "sapphire")
        hues = {k: v if k in greys else mix(v, "000000", 0.4) for k, v in hues.items()}
        # Light terminals keep term0/8 dark and term7/15 light
        hues |= {"term0": mix(b["text"], b["subtext"], 0.4), "term8": b["subtext"], "term7": b["button"],
                 "term15": b["bright"]}
    s |= hues

    visited = mix(b["outline"], b["subtext"], 0.7) if mono else ("7d3570" if light else "c79ae8")
    neutral = tertiary if (mono or light) else "ffc77f"
    # KDE colours
    s |= {
        "klink": tertiary,
        "klinkSelection": tertiary,
        "kvisited": visited,
        "kvisitedSelection": visited,
        "knegative": error,
        "knegativeSelection": error,
        "kneutral": neutral,
        "kneutralSelection": neutral,
        "kpositive": success,
        "kpositiveSelection": success,
    }
    return s


def main():
    out = ASSETS / "schemes" / "hollowknight"
    styles = json.loads((ASSETS / "styles.json").read_text())
    for name, style in styles.items():
        terminal = style
        mode = "light" if style.get("light") else "dark"
        for flavour in style["flavours"]:
            folder = out / (flavour if name == "hallownest" else f"{name}-{flavour}")
            folder.mkdir(parents=True, exist_ok=True)
            for old in folder.glob("*.txt"):
                old.unlink()
            path = folder / f"{mode}.txt"
            path.write_text("".join(f"{k} {v}\n" for k, v in scheme(style, flavour, terminal).items()))
            print(path)


if __name__ == "__main__":
    main()
