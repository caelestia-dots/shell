#!/usr/bin/env python3
"""Prepare a source tree for AOT QML compilation.

Copies the shell QML into the build directory, rewrites `qs.*` and relative
imports to the generated `Caelestia.Qml.*` modules, and emits the CMake module
definitions used by aot/CMakeLists.txt.
"""

import re
import shutil
import sys
from pathlib import Path

ROOT_DIRS = ("components", "modules", "services", "utils")
SOURCE_SUFFIXES = (".qml", ".js")
PLUGIN_TARGETS = (
    "caelestia-config",
    "caelestia-services",
    "caelestia-blobs",
    "caelestia-models",
    "caelestia-images",
    "caelestia-core",
    "caelestia-settings",
)
QT_DEPENDENCIES = (
    "QtQuick",
    "QtQuick.Controls",
    "QtQuick.Effects",
    "QtQuick.Layouts",
    "QtQuick.Shapes",
    "Quickshell",
    "Quickshell.Hyprland",
    "Quickshell.Io",
    "Quickshell.Services.Mpris",
    "Quickshell.Services.Notifications",
    "Quickshell.Services.Pam",
    "Quickshell.Services.Pipewire",
    "Quickshell.Services.UPower",
    "Quickshell.Wayland",
    "Quickshell.Widgets",
)


def capitalize(part: str) -> str:
    return part[:1].upper() + part[1:]


def module_uri(rel_dir: Path) -> str:
    if str(rel_dir) == ".":
        return "Caelestia.Qml"
    return "Caelestia.Qml." + ".".join(capitalize(part) for part in rel_dir.parts)


def rewrite_imports(text: str, rel_file: Path, source_root: Path) -> str:
    lines = []
    for line in text.splitlines(keepends=True):
        stripped = line.rstrip("\n")

        match = re.match(r"^(\s*)import\s+(qs(?:\.[A-Za-z0-9_]+)+)(\s+as\s+\w+)?\s*(//.*)?$", stripped)
        if match:
            path = match.group(2)[3:].replace(".", "/")
            uri = module_uri(Path(path) if path else Path("."))
            lines.append(f"{match.group(1)}import {uri}{match.group(3) or ''}{(' ' + match.group(4)) if match.group(4) else ''}\n")
            continue

        match = re.match(r'^(\s*)import\s+"([^"]+)"(\s+as\s+\w+)?\s*(//.*)?$', stripped)
        if match and not match.group(2).endswith(".js"):
            target = (rel_file.parent / match.group(2)).resolve()
            try:
                rel_target = target.relative_to(source_root)
            except ValueError:
                rel_target = None
            if rel_target is not None:
                uri = module_uri(rel_target)
                lines.append(f"{match.group(1)}import {uri}{match.group(3) or ''}{(' ' + match.group(4)) if match.group(4) else ''}\n")
                continue

        lines.append(line)

    return "".join(lines)


def copy_tree(source_root: Path, out_root: Path) -> None:
    source = out_root / "src"
    if source.exists():
        shutil.rmtree(source)
    source.mkdir(parents=True)

    for root_dir in ROOT_DIRS:
        for path in (source_root / root_dir).rglob("*"):
            if not path.is_file() or path.suffix not in SOURCE_SUFFIXES:
                continue

            rel = path.relative_to(source_root)
            dst = source / rel
            dst.parent.mkdir(parents=True, exist_ok=True)

            text = path.read_text()
            if path.suffix == ".qml":
                text = rewrite_imports(text, rel, source_root)
            dst.write_text(text)

    shell = source_root / "shell.qml"
    (source / "Shell.qml").write_text(rewrite_imports(shell.read_text(), Path("shell.qml"), source_root))


def cmake_quote(value: str) -> str:
    return f'"{value}"'


def generate_cmake(source_root: Path, out_root: Path) -> str:
    source = out_root / "src"
    qml_dirs = sorted({path.parent for path in source.rglob("*.qml")})
    js_files = sorted(source.rglob("*.js"))
    chunks = []

    for directory in qml_dirs:
        rel_dir = directory.relative_to(source)
        direct = sorted(path for path in directory.iterdir() if path.is_file() and path.suffix == ".qml")
        assigned_js = []
        for js in js_files:
            ancestor = js.parent
            while ancestor != source and ancestor not in qml_dirs:
                ancestor = ancestor.parent
            if ancestor == directory:
                assigned_js.append(js)

        files = sorted(direct + assigned_js)
        singletons = []
        qml_files = []
        for path in files:
            if path.suffix == ".qml" and "pragma Singleton" in path.read_text():
                singletons.append(path)
            else:
                qml_files.append(path)

        target = "caelestia-aot-" + ("root" if str(rel_dir) == "." else "-".join(rel_dir.parts))
        chunks.append("")

        for path in files:
            alias = path.relative_to(directory).as_posix()
            chunks.append(
                f"set_source_files_properties({cmake_quote(str(path))} PROPERTIES QT_RESOURCE_ALIAS {cmake_quote(alias)})"
            )

        chunks.append(f"qml_module({target}")
        chunks.append(f"    URI {module_uri(rel_dir)}")
        if qml_files:
            chunks.append("    QML_FILES")
            chunks.extend(f"        {cmake_quote(str(path))}" for path in qml_files)
        if singletons:
            chunks.append("    QML_SINGLETONS")
            chunks.extend(f"        {cmake_quote(str(path))}" for path in singletons)
        chunks.append("    DEPENDENCIES")
        chunks.extend(f"        {dependency}" for dependency in QT_DEPENDENCIES)
        chunks.append(")")
        chunks.append(
            f"target_compile_options({target} PRIVATE -Wno-float-equal -Wno-shorten-64-to-32 "
            "-Wno-implicit-int-float-conversion -Wno-float-conversion)"
        )

        for dependency in PLUGIN_TARGETS:
            chunks.append(f"if(TARGET {dependency})")
            chunks.append(f"    add_dependencies({target} {dependency})")
            chunks.append("endif()")

    return "\n".join(chunks) + "\n"


def write_launcher(source_root: Path, out_root: Path) -> None:
    shell = source_root / "shell.qml"
    pragmas = []
    for line in shell.read_text().splitlines():
        if not line.startswith("//@"):
            break
        pragmas.append(line)

    out_root.joinpath("shell.qml").write_text(
        "\n".join(pragmas) + "\n\nimport Caelestia.Qml\n\nShell {\n    settings.watchFiles: false\n}\n"
    )


def write_lock_launcher(source_root: Path, out_root: Path) -> None:
    text = (source_root / "lock-shell.qml").read_text()
    out_root.joinpath("lock-shell.qml").write_text(rewrite_imports(text, Path("lock-shell.qml"), source_root))


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: prepare.py <source-root> <output-root>", file=sys.stderr)
        return 2

    source_root = Path(sys.argv[1]).resolve()
    out_root = Path(sys.argv[2]).resolve()
    out_root.mkdir(parents=True, exist_ok=True)

    copy_tree(source_root, out_root)
    (out_root / "modules.cmake").write_text(generate_cmake(source_root, out_root))
    write_launcher(source_root, out_root)
    write_lock_launcher(source_root, out_root)

    for name in ("assets",):
        link = out_root / name
        if link.is_symlink() or link.is_file():
            link.unlink()
        elif link.is_dir():
            shutil.rmtree(link)
        link.symlink_to(source_root / name, target_is_directory=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
