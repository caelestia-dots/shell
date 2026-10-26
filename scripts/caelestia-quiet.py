#!/usr/bin/env python3
"""Run caelestia CLI without broadcasting OSC colour sequences to every PTY.

apply_terms() writes ANSI OSC dumps to all /dev/pts devices. Some clients
(e.g. IDE embedded terminals) surface that as a system notification. We still
persist sequences.txt so new shells can pick up colours, but skip the broadcast.

After colours are applied (including user templates like kitty.conf), push the
palette into open Kitty windows via remote control.
"""

from __future__ import annotations

import runpy
import subprocess
import sys
from pathlib import Path


def _reload_kitty() -> None:
    script = Path.home() / ".config/caelestia/scripts/kitty-reload-colours.sh"
    if not script.is_file():
        return
    try:
        subprocess.run([str(script)], check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except OSError:
        pass


def _patch_theme() -> None:
    import caelestia.utils.theme as theme
    from caelestia.utils.paths import c_state_dir

    def apply_terms_quiet(sequences: str) -> None:
        state = c_state_dir / "sequences.txt"
        state.parent.mkdir(parents=True, exist_ok=True)
        state.write_text(sequences)

    orig_apply_colours = theme.apply_colours

    def apply_colours_quiet(colours: dict[str, str], mode: str) -> None:
        orig_apply_colours(colours, mode)
        # Templates land inside apply_colours; refresh Kitty after that.
        _reload_kitty()

    theme.apply_terms = apply_terms_quiet
    theme.apply_colours = apply_colours_quiet


def main() -> None:
    _patch_theme()
    # Replace argv so caelestia sees a normal CLI invocation
    sys.argv = ["caelestia", *sys.argv[1:]]
    runpy.run_module("caelestia", run_name="__main__")


if __name__ == "__main__":
    main()
