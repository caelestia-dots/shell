#!/usr/bin/env python3
"""Generate and reconcile dGPU wrapper desktop entries.

Reads a sidecar JSON registry that maps desktop entry ids to a GPU choice,
then creates or removes "App (dGPU)" wrapper entries in the user applications
directory so any launcher that reads that directory can launch the app on the
discrete GPU via a PRIME render offload env prefix.

The registry is a plain sidecar file at ~/.config/caelestia/dgpu.json,
deliberately NOT part of the C++ ConfigObject schema (the schema owns
shell.json only). Example::

    {
      "apps": {
        "com.visualstudio.code.desktop": "dGPU"
      }
    }

Desktop entry ids must include the .desktop extension. Wrapper entries carry
an X-Caelestia-DGPU-Source marker key inside the [Desktop Entry] group so
stale entries can be reconciled on every run; reruns are idempotent. Entries
whose source is assigned but no longer installed are pruned, since the
wrapper would be a dead launcher entry either way.
"""

import argparse
import json
import os
import re
import sys
from pathlib import Path

OFFLOAD_ENV = [
    "__NV_PRIME_RENDER_OFFLOAD=1",
    "__GLX_VENDOR_LIBRARY_NAME=nvidia",
    "__VK_LAYER_NV_optimus=NVIDIA_only",
]

MARKER_KEY = "X-Caelestia-DGPU-Source"
WRAPPER_SUFFIX = " (dGPU)"
DESKTOP_EXT = ".desktop"
MAIN_GROUP = "[Desktop Entry]"
DGPU = "dGPU"

KEY_VALUE = re.compile(r"^([A-Za-z0-9-]+)=(.*)$")


def home_dir() -> Path:
    return Path(os.environ.get("HOME") or Path.home())


def config_dir() -> Path:
    base = os.environ.get("XDG_CONFIG_HOME") or home_dir() / ".config"
    return Path(base) / "caelestia"


def data_home() -> Path:
    return Path(os.environ.get("XDG_DATA_HOME") or home_dir() / ".local/share")


def default_registry() -> Path:
    return config_dir() / "dgpu.json"


def default_applications_dir() -> Path:
    return data_home() / "applications"


def default_source_dirs() -> list[Path]:
    dirs = []
    for entry in os.environ.get("XDG_DATA_DIRS", "").split(":"):
        if entry and entry not in dirs:
            dirs.append(Path(entry))
    for entry in ("/usr/local/share", "/usr/share"):
        if entry not in dirs:
            dirs.append(Path(entry))
    return [d / "applications" for d in dirs]


def load_registry(path: Path) -> dict:
    if not path.exists():
        return {"apps": {}}
    try:
        with path.open() as f:
            return json.load(f)
    except (OSError, ValueError) as e:
        raise ValueError(f"cannot read registry {path}: {e}") from e


def assigned_dgpu_ids(registry: dict) -> set[str]:
    apps = registry.get("apps", {})
    if not isinstance(apps, dict):
        raise ValueError("registry key 'apps' must be an object")
    return {app_id for app_id, gpu in apps.items() if gpu == DGPU}


def find_source(
    entry_id: str, applications_dir: Path, source_dirs: list[Path]
) -> Path | None:
    for base in [applications_dir, *source_dirs]:
        candidate = base / entry_id
        if candidate.is_file():
            return candidate
    return None


def wrapper_filename(entry_id: str) -> str:
    stem = entry_id.removesuffix(DESKTOP_EXT)
    return f"{stem}{WRAPPER_SUFFIX}{DESKTOP_EXT}"


def desktop_groups(contents: str) -> list[tuple[str, str, str]]:
    """Parse a .desktop file into (group, key, value) tuples, in order."""
    group = None
    entries = []
    for line in contents.splitlines():
        if line.startswith("["):
            group = line
            continue
        m = KEY_VALUE.match(line)
        if m and group is not None:
            entries.append((group, m.group(1), m.group(2)))
    return entries


def build_wrapper(source: Path, entry_id: str) -> str:
    lines_out = []
    marker_written = False
    for line in source.read_text().splitlines():
        if line.startswith("["):
            group = line
            lines_out.append(line)
            if group == MAIN_GROUP and not marker_written:
                lines_out.append(f"{MARKER_KEY}={entry_id}")
                marker_written = True
            continue
        m = KEY_VALUE.match(line)
        if m is None or group != MAIN_GROUP:
            lines_out.append(line)
            continue
        key, value = m.group(1), m.group(2)
        if key == "Name":
            if not value.endswith(WRAPPER_SUFFIX):
                value = f"{value}{WRAPPER_SUFFIX}"
            lines_out.append(f"Name={value}")
        elif key == "Exec":
            if value.startswith("env "):
                value = "env " + " ".join(OFFLOAD_ENV) + " " + value[4:]
            else:
                value = "env " + " ".join(OFFLOAD_ENV) + " " + value
            lines_out.append(f"Exec={value}")
        elif key == MARKER_KEY:
            continue
        else:
            lines_out.append(line)
    if not marker_written:
        lines_out.append(f"{MARKER_KEY}={entry_id}")
    return "\n".join(lines_out) + "\n"


def wrapper_source_id(contents: str) -> str | None:
    for group, key, value in desktop_groups(contents):
        if group == MAIN_GROUP and key == MARKER_KEY:
            return value
    return None


def apply(registry: dict, applications_dir: Path, source_dirs: list[Path]) -> None:
    desired = assigned_dgpu_ids(registry)
    resolved = {
        entry_id: find_source(entry_id, applications_dir, source_dirs)
        for entry_id in desired
    }

    applications_dir.mkdir(parents=True, exist_ok=True)

    for entry_id, source in resolved.items():
        if source is None:
            continue
        target = applications_dir / wrapper_filename(entry_id)
        content = build_wrapper(source, entry_id)
        if target.exists() and target.read_text() == content:
            continue
        target.write_text(content)

    for entry in applications_dir.glob(f"*{WRAPPER_SUFFIX}{DESKTOP_EXT}"):
        source_id = wrapper_source_id(entry.read_text())
        if source_id is None:
            continue
        if source_id not in resolved or resolved[source_id] is None:
            entry.unlink(missing_ok=True)


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="caelestia-dgpu-generator",
        description="Create/remove 'App (dGPU)' wrapper desktop entries from a sidecar registry.",
    )
    parser.add_argument("--registry", type=Path, default=default_registry())
    parser.add_argument(
        "--applications-dir", type=Path, default=default_applications_dir()
    )
    parser.add_argument(
        "--source-dirs",
        type=str,
        default=":".join(str(p) for p in default_source_dirs()),
        help="Colon-separated dirs to resolve source desktop entries from (default: XDG_DATA_DIRS).",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    source_dirs = [Path(d) for d in args.source_dirs.split(":") if d]
    try:
        registry = load_registry(args.registry)
        apply(registry, args.applications_dir, source_dirs)
    except ValueError as e:
        print(f"error: {e}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
