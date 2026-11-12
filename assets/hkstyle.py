"""Active Hallownest palette for the theme scripts, read from styles.json.

Scripts are called as `<script> <style> <flavour>`; unknown names fall back to hallownest/vessel.
"""
import json
import sys
from pathlib import Path

STYLES = json.loads((Path(__file__).parent / "styles.json").read_text())


def palette(argv=sys.argv):
    """Flat dict: base colours, charms, the flavour's accent/steel/tertiary/error/success, `key` and `light`."""
    style = argv[1] if len(argv) > 1 and argv[1] in STYLES else "hallownest"
    flavours = STYLES[style]["flavours"]
    flavour = argv[2] if len(argv) > 2 and argv[2] in flavours else "vessel"
    return {**STYLES[style]["base"], **STYLES[style]["charms"], **flavours[flavour], "key": f"{style}-{flavour}",
            "light": STYLES[style].get("light", False)}
