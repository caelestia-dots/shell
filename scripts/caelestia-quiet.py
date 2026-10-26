#!/usr/bin/env python3
"""Run caelestia CLI without broadcasting OSC colour sequences to every PTY.

apply_terms() writes ANSI OSC dumps to all /dev/pts devices. Some clients
(e.g. IDE embedded terminals) surface that as a system notification. We still
persist sequences.txt so new shells can pick up colours, but skip the broadcast.
"""

from __future__ import annotations

import runpy
import sys


def _patch_apply_terms() -> None:
    import caelestia.utils.theme as theme
    from caelestia.utils.paths import c_state_dir

    def apply_terms_quiet(sequences: str) -> None:
        state = c_state_dir / "sequences.txt"
        state.parent.mkdir(parents=True, exist_ok=True)
        state.write_text(sequences)

    theme.apply_terms = apply_terms_quiet


def main() -> None:
    _patch_apply_terms()
    # Replace argv so caelestia sees a normal CLI invocation
    sys.argv = ["caelestia", *sys.argv[1:]]
    runpy.run_module("caelestia", run_name="__main__")


if __name__ == "__main__":
    main()
