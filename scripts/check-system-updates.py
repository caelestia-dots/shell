#!/usr/bin/env python3
"""Emit JSON lines for Arch / AUR / Flatpak updates."""
from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys


def run(cmd: list[str]) -> tuple[int, str, str]:
    try:
        env = {**dict(**__import__("os").environ), "LANG": "C", "LC_ALL": "C"}
        # Quickshell Process attaches an idle stdin pipe; tools like pacinfo
        # block forever waiting on it unless we detach.
        p = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            check=False,
            env=env,
            stdin=subprocess.DEVNULL,
        )
        return p.returncode, p.stdout or "", p.stderr or ""
    except FileNotFoundError:
        return 127, "", f"not found: {cmd[0]}"


def emit(obj: dict) -> None:
    print(json.dumps(obj, ensure_ascii=False), flush=True)


def size_to_mib(text: str) -> float:
    parts = (text or "").replace("\xa0", " ").replace("?", " ").split()
    if not parts:
        return 0.0
    try:
        n = float(parts[0].replace(",", ""))
    except ValueError:
        return 0.0
    unit = parts[1][0].upper() if len(parts) > 1 else "M"
    factor = {"B": 1 / 1048576, "K": 1 / 1024, "M": 1.0, "G": 1024.0, "T": 1048576.0}.get(unit, 1.0)
    return n * factor


def parse_pacinfo(blocks: str) -> dict[str, dict]:
    out: dict[str, dict] = {}
    for block in re.split(r"\n\s*\n", blocks.strip()):
        if not block.strip():
            continue
        meta = {
            "source": "",
            "group": "",
            "desc": "",
            "url": "",
            "size": 0.0,
        }
        name = ""
        licenses: list[str] = []
        requires: list[str] = []
        provides: list[str] = []
        optdeps: list[str] = []
        for line in block.splitlines():
            if ":" not in line:
                continue
            tag, value = line.split(":", 1)
            tag = tag.strip()
            value = value.strip()
            if tag == "Name":
                name = value
            elif tag == "Groups":
                meta["group"] = value
            elif tag == "Repository":
                meta["source"] = value.upper()
            elif tag == "URL":
                meta["url"] = value
            elif tag == "Download Size":
                meta["size"] = size_to_mib(value)
                meta["desc"] += f"Download Size:{value}\n"
            elif tag in ("Description", "Packager", "Installed Size", "Architecture"):
                meta["desc"] += f"{tag}:{value}\n"
            elif tag == "Licenses":
                licenses.append(value)
            elif tag == "Requires":
                requires.append(value)
            elif tag == "Optional Deps":
                optdeps.append(value)
            elif tag == "Provides":
                provides.append(value)
        if licenses:
            meta["desc"] += "Licenses:" + " ".join(licenses) + "\n"
        if requires:
            meta["desc"] += "Requires:" + " ".join(requires) + "\n"
        if provides:
            meta["desc"] += "Provide:" + " ".join(provides) + "\n"
        if optdeps:
            meta["desc"] += "Optional Deps:" + " ".join(optdeps) + "\n"
        if name:
            out[name] = meta
    return out


def pacinfo_for(names: list[str]) -> dict[str, dict]:
    if not names or not shutil.which("pacinfo"):
        return {}
    code, out, _ = run(["pacinfo", *names])
    if code != 0 and not out.strip():
        return {}
    return parse_pacinfo(out)


def check_arch() -> None:
    code, out, _ = run(["checkupdates", "--nocolor"])
    # checkupdates exits 2 when there are no updates
    lines = [ln for ln in out.splitlines() if ln.strip()]
    names = []
    rows = []
    for ln in lines:
        parts = ln.split()
        if len(parts) < 4:
            continue
        name, frm, _arrow, to = parts[0], parts[1], parts[2], parts[3]
        names.append(name)
        rows.append((name, frm, to))
    info = pacinfo_for(names)
    for name, frm, to in rows:
        meta = info.get(name, {})
        emit(
            {
                "name": name,
                "from": frm,
                "to": to,
                "source": meta.get("source") or "ARCH",
                "group": meta.get("group") or "",
                "desc": meta.get("desc") or "",
                "url": meta.get("url") or "",
                "size": float(meta.get("size") or 0),
            }
        )


def check_aur(wrapper: str) -> None:
    if not shutil.which(wrapper):
        return
    if wrapper in ("trizen", "pikaur"):
        cmd = [wrapper, "-Qua"]
    elif wrapper == "pacaur":
        cmd = ["pacaur", "-Qum", "--color", "never"]
    else:
        cmd = [wrapper, "-Qua", "--color", "never"]
    _, out, _ = run(cmd)
    lines = [ln for ln in out.splitlines() if ln.strip()]
    rows = []
    names = []
    for ln in lines:
        if wrapper == "pacaur" and ln.startswith("::"):
            continue
        parts = ln.split()
        # pacaur: "aur/pkg old -> new" style sometimes
        if wrapper == "pacaur" and "/" in parts[0]:
            parts[0] = parts[0].split("/", 1)[-1]
        if len(parts) < 2:
            continue
        name = parts[0]
        frm = parts[1] if len(parts) > 1 else ""
        to = parts[3] if len(parts) > 3 else "latest commit"
        names.append(name)
        rows.append((name, frm, to))
    info = pacinfo_for(names)
    for name, frm, to in rows:
        meta = info.get(name, {})
        emit(
            {
                "name": name,
                "from": frm,
                "to": to,
                "source": "AUR",
                "group": meta.get("group") or "",
                "desc": meta.get("desc") or "",
                "url": meta.get("url") or "",
                "size": float(meta.get("size") or 0),
            }
        )


def check_flatpak() -> None:
    if not shutil.which("flatpak"):
        return
    _, out, _ = run(["flatpak", "remote-ls", "--updates", "--columns=application,download-size"])
    for ln in out.splitlines():
        ln = ln.strip()
        if not ln:
            continue
        parts = ln.split()
        app_id = parts[0]
        size_raw = parts[1] if len(parts) > 1 else "0"
        _, info, _ = run(["flatpak", "info", app_id])
        version = ""
        ref = ""
        desc = ""
        for line in info.splitlines():
            if ": " not in line and ":" not in line:
                continue
            if ": " in line:
                tag, value = line.split(": ", 1)
            else:
                tag, value = line.split(":", 1)
                value = value.strip()
            tag = tag.strip()
            if tag == "Version":
                version = value
            elif tag == "Ref":
                ref = value
            elif tag not in ("ID",):
                desc += f"{tag}:{value}\n"
        ref_alt = ref.split("/")[0] if ref else "app"
        url = (
            f"https://flathub.org/apps/{app_id}"
            if ref_alt == "app"
            else "https://docs.flatpak.org/en/latest/available-runtimes.html"
        )
        emit(
            {
                "name": ref or app_id,
                "from": app_id,
                "to": version or "",
                "source": f"FLATPAK ({ref_alt})",
                "group": "",
                "desc": desc,
                "url": url,
                "size": size_to_mib(size_raw),
            }
        )


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--arch", action="store_true")
    ap.add_argument("--aur", metavar="WRAPPER", nargs="?", const="yay")
    ap.add_argument("--flatpak", action="store_true")
    args = ap.parse_args()
    if not (args.arch or args.aur or args.flatpak):
        args.arch = args.flatpak = True
        args.aur = "yay"
    if args.arch:
        check_arch()
    if args.aur:
        check_aur(args.aur)
    if args.flatpak:
        check_flatpak()
    return 0


if __name__ == "__main__":
    sys.exit(main())
