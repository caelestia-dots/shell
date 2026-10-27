#!/usr/bin/env python3
"""Apply activity wallpaper + colour scheme in one process.

Wallpaper CLI always regenerates colours; pairing it with `scheme set` meant
two full theme applies (~2× latency). Here we only update wallpaper files,
then regenerate and apply colours once.
"""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path


def _patch_theme_quiet() -> None:
    import caelestia.utils.theme as theme
    from caelestia.utils.paths import c_state_dir

    def apply_terms_quiet(sequences: str) -> None:
        state = c_state_dir / "sequences.txt"
        state.parent.mkdir(parents=True, exist_ok=True)
        state.write_text(sequences)

    orig_apply_colours = theme.apply_colours
    kitty = Path.home() / ".config/caelestia/scripts/kitty-reload-colours.sh"

    def apply_colours_quiet(colours: dict[str, str], mode: str) -> None:
        orig_apply_colours(colours, mode)
        if kitty.is_file():
            try:
                subprocess.run(
                    [str(kitty)],
                    check=False,
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                )
            except OSError:
                pass

    theme.apply_terms = apply_terms_quiet
    theme.apply_colours = apply_colours_quiet


def _set_wallpaper_files(wall: Path) -> None:
    from caelestia.utils.paths import (
        compute_hash,
        wallpaper_link_path,
        wallpaper_path_path,
        wallpaper_thumbnail_path,
        wallpapers_cache_dir,
    )
    from caelestia.utils.wallpaper import convert_gif, get_thumb, is_valid_image

    wall = wall.resolve()
    if not is_valid_image(wall):
        raise ValueError(f'"{wall}" is not a valid image')

    wall_cache = convert_gif(wall) if wall.suffix.lower() == ".gif" else wall

    wallpaper_path_path.parent.mkdir(parents=True, exist_ok=True)
    wallpaper_path_path.write_text(str(wall))
    wallpaper_link_path.parent.mkdir(parents=True, exist_ok=True)
    wallpaper_link_path.unlink(missing_ok=True)
    wallpaper_link_path.symlink_to(wall)

    cache = wallpapers_cache_dir / compute_hash(wall_cache)
    thumb = get_thumb(wall_cache, cache)
    wallpaper_thumbnail_path.parent.mkdir(parents=True, exist_ok=True)
    wallpaper_thumbnail_path.unlink(missing_ok=True)
    wallpaper_thumbnail_path.symlink_to(thumb)


def _apply_scheme(
    name: str | None,
    flavour: str | None,
    mode: str | None,
    variant: str | None,
    *,
    force: bool,
) -> None:
    from caelestia.utils.scheme import (
        get_scheme,
        get_scheme_flavours,
        get_scheme_modes,
        get_scheme_names,
        scheme_variants,
    )
    from caelestia.utils.theme import apply_colours

    scheme = get_scheme()
    dirty = force

    if name and name != scheme._name:
        if name not in get_scheme_names():
            raise ValueError(f"Invalid scheme name: {name}")
        scheme._name = name
        scheme._check_flavour()
        scheme._check_mode()
        dirty = True

    if flavour and flavour != scheme._flavour:
        if flavour not in get_scheme_flavours(scheme._name):
            raise ValueError(f'Invalid scheme flavour: "{flavour}"')
        scheme._flavour = flavour
        scheme._check_mode()
        dirty = True

    if mode and mode != scheme._mode:
        if mode not in get_scheme_modes(scheme._name, scheme._flavour):
            raise ValueError(f'Invalid scheme mode: "{mode}"')
        scheme._mode = mode
        dirty = True

    if variant and variant != scheme._variant:
        if variant not in scheme_variants:
            raise ValueError(f'Invalid scheme variant: "{variant}"')
        scheme._variant = variant
        dirty = True

    if not dirty:
        return

    # One colour regen + one theme apply (templates, hypr, kitty, …)
    scheme.update_colours()
    apply_colours(scheme.colours, scheme.mode)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--wallpaper", default="", help="wallpaper path (optional)")
    parser.add_argument("--name", default="", help="scheme name")
    parser.add_argument("--flavour", default="", help="scheme flavour")
    parser.add_argument("--mode", default="", choices=["", "dark", "light"])
    parser.add_argument("--variant", default="", help="scheme variant")
    args = parser.parse_args()

    if not args.wallpaper and not any((args.name, args.flavour, args.mode, args.variant)):
        print("nothing to apply", file=sys.stderr)
        return 1

    _patch_theme_quiet()

    wall_set = False
    if args.wallpaper:
        _set_wallpaper_files(Path(args.wallpaper))
        wall_set = True

    if wall_set or any((args.name, args.flavour, args.mode, args.variant)):
        _apply_scheme(
            args.name or None,
            args.flavour or None,
            args.mode or None,
            args.variant or None,
            force=wall_set,
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
