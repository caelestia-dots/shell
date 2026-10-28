#!/usr/bin/env python3
"""Local Steam library helpers for Caelestia.

Reads Non-Steam shortcuts (shortcuts.vdf), the hidden library collection
(user-collections.hidden), and optional Millennium Non-Steam Playtimes
(sessions.json) for hours played.

Usage:
  steam-nonsteam.py [--steamid STEAMID64]

Prints JSON: { "nonSteam": [...], "hiddenAppIds": ["..."] }
"""

from __future__ import annotations

import argparse
import json
import struct
import sys
import time
from pathlib import Path

STEAM64_BASE = 76561197960265728
TWO_WEEKS = 14 * 24 * 60 * 60
CACHE_DAYS = 400


def steam_roots() -> list[Path]:
    home = Path.home()
    roots = [
        home / ".local/share/Steam",
        home / ".steam/steam",
        home / ".steam/root",
        home / ".var/app/com.valvesoftware.Steam/data/Steam",
    ]
    seen: set[Path] = set()
    out: list[Path] = []
    for r in roots:
        try:
            r = r.resolve()
        except OSError:
            continue
        if r.is_dir() and r not in seen:
            seen.add(r)
            out.append(r)
    return out


def account_id(steamid64: str | None) -> str | None:
    if not steamid64 or not steamid64.isdigit():
        return None
    n = int(steamid64)
    if n < STEAM64_BASE:
        return None
    return str(n - STEAM64_BASE)


def parse_map(buf: bytes, i: int) -> tuple[dict, int]:
    out: dict = {}
    while i < len(buf):
        t = buf[i]
        i += 1
        if t == 8:
            return out, i
        z = buf.find(b"\x00", i)
        if z < 0:
            return out, len(buf)
        key = buf[i:z].decode("utf-8", "replace")
        i = z + 1
        if t == 0:
            val, i = parse_map(buf, i)
            out[key] = val
        elif t == 1:
            z = buf.find(b"\x00", i)
            out[key] = buf[i:z].decode("utf-8", "replace")
            i = z + 1
        elif t == 2:
            out[key] = struct.unpack_from("<i", buf, i)[0]
            i += 4
        elif t == 7:
            out[key] = struct.unpack_from("<Q", buf, i)[0]
            i += 8
        else:
            return out, i
    return out, i


def parse_shortcuts(path: Path) -> dict:
    data = path.read_bytes()
    if not data:
        return {}
    if data[0] != 0:
        return {}
    z = data.find(b"\x00", 1)
    if z < 0:
        return {}
    return parse_map(data, z + 1)[0]


def file_url(path: Path | None) -> str:
    if not path or not path.is_file():
        return ""
    return path.resolve().as_uri()


def pick_art(grid: Path, app_id: str, names: list[str]) -> str:
    for name in names:
        url = file_url(grid / name.format(id=app_id))
        if url:
            return url
    return ""


def millennium_sessions_paths() -> list[Path]:
    home = Path.home()
    return [
        home / ".local/share/millennium/plugins/non-steam-playtimes/sessions.json",
        home / ".local/share/Steam/plugins/non-steam-playtimes/sessions.json",
        home / ".steam/steam/plugins/non-steam-playtimes/sessions.json",
    ]


def session_cache_path() -> Path:
    import os

    base = os.environ.get("XDG_STATE_HOME") or str(Path.home() / ".local/state")
    return Path(base) / "caelestia" / "nonsteam-sessions.json"


def merge_session_cache(fresh: dict[str, list[dict[str, int]]]) -> dict[str, list[dict[str, int]]]:
    """Millennium collapses sessions older than two weeks, so keep our own history."""
    path = session_cache_path()
    try:
        cached = json.loads(path.read_text(encoding="utf-8"))
        if not isinstance(cached, dict):
            cached = {}
    except (OSError, json.JSONDecodeError):
        cached = {}

    horizon = int(time.time()) - CACHE_DAYS * 24 * 60 * 60
    merged: dict[str, list[dict[str, int]]] = {}
    for name in set(cached) | set(fresh):
        by_start: dict[int, dict[str, int]] = {}
        for s in (cached.get(name) or []) + (fresh.get(name) or []):
            try:
                start, end = int(s["start"]), int(s["end"])
            except (KeyError, TypeError, ValueError):
                continue
            if start >= horizon and end > start:
                by_start[start] = {"start": start, "end": max(end, by_start.get(start, {}).get("end", 0))}
        merged[name] = sorted(by_start.values(), key=lambda s: s["start"], reverse=True)

    if merged != cached:
        try:
            path.parent.mkdir(parents=True, exist_ok=True)
            tmp = path.with_suffix(".tmp")
            tmp.write_text(json.dumps(merged), encoding="utf-8")
            tmp.replace(path)
        except OSError:
            pass
    return merged


def load_millennium_playtimes() -> dict[str, dict]:
    """Match Millennium Non-Steam Playtimes plugin (keyed by AppName).

    Returns { name: { playtimeForever, playtime2Weeks, lastPlayed, sessions } }
    in minutes/unix. The rolled-up session uses started_at=0 and
    ended_at=accumulated seconds, so it is excluded from `sessions`.
    """
    path = next((p for p in millennium_sessions_paths() if p.is_file()), None)
    if not path:
        return {}
    try:
        sessions = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {}
    if not isinstance(sessions, dict):
        return {}

    now = int(time.time())
    cutoff = now - TWO_WEEKS
    out: dict[str, dict] = {}
    for name, entries in sessions.items():
        if not isinstance(entries, list):
            continue
        forever_sec = 0
        recent_sec = 0
        last_played = 0
        real_sessions: list[dict[str, int]] = []
        for s in entries:
            if not isinstance(s, dict):
                continue
            try:
                started = int(s.get("started_at") or 0)
                ended = int(s.get("ended_at") or 0)
            except (TypeError, ValueError):
                continue
            if ended < started:
                continue
            dur = ended - started
            forever_sec += dur
            # Mirror plugin: count toward 2 weeks if session started after cutoff
            if started > cutoff:
                recent_sec += dur
            if started != 0 and ended > last_played:
                last_played = ended
            if started != 0 and dur >= 60:
                real_sessions.append({"start": started, "end": ended})
        out[str(name)] = {
            "playtimeForever": max(0, forever_sec // 60),
            "playtime2Weeks": max(0, recent_sec // 60),
            "lastPlayed": last_played,
            "sessions": real_sessions,
        }

    history = merge_session_cache({name: v["sessions"] for name, v in out.items()})
    for name, v in out.items():
        v["sessions"] = history.get(name) or []
    return out


def load_hidden_ids(cfg: Path) -> list[str]:
    cloud = cfg / "cloudstorage"
    if not cloud.is_dir():
        return []
    ids: set[str] = set()
    for path in sorted(cloud.glob("cloud-storage-namespace-*.json")):
        if path.name.endswith(".modified.json"):
            continue
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            continue
        entries = data if isinstance(data, list) else []
        for item in entries:
            if not (isinstance(item, list) and len(item) >= 2):
                continue
            if item[0] != "user-collections.hidden":
                continue
            meta = item[1] if isinstance(item[1], dict) else {}
            raw = meta.get("value") or ""
            try:
                coll = json.loads(raw) if isinstance(raw, str) else raw
            except json.JSONDecodeError:
                continue
            for app in coll.get("added") or []:
                ids.add(str(app))
    return sorted(ids)


def load_for_account(root: Path, acct: str, playtimes: dict[str, dict]) -> tuple[list[dict], list[str]]:
    cfg = root / "userdata" / acct / "config"
    hidden = load_hidden_ids(cfg)
    vdf = cfg / "shortcuts.vdf"
    if not vdf.is_file():
        return [], hidden
    grid = cfg / "grid"
    shortcuts = parse_shortcuts(vdf)
    games: list[dict] = []
    for entry in shortcuts.values():
        if not isinstance(entry, dict):
            continue
        name = (entry.get("AppName") or "").strip()
        if not name:
            continue
        if entry.get("IsHidden") == 1:
            continue
        raw_id = entry.get("appid", 0)
        try:
            app_id = str(int(raw_id) & 0xFFFFFFFF)
        except (TypeError, ValueError):
            continue
        icon = entry.get("icon") or ""
        icon_url = file_url(Path(icon)) if icon else ""
        header = pick_art(
            grid,
            app_id,
            ["{id}_hero.jpg", "{id}_hero.png", "{id}.png", "{id}.jpg"],
        )
        capsule = pick_art(
            grid,
            app_id,
            ["{id}p.jpg", "{id}p.png", "{id}.png", "{id}.jpg", "{id}_logo.png"],
        )
        if not capsule:
            capsule = icon_url
        if not header:
            header = capsule or icon_url
        last = entry.get("LastPlayTime") or 0
        try:
            last = int(last)
        except (TypeError, ValueError):
            last = 0
        pt = playtimes.get(name) or {}
        if pt.get("lastPlayed"):
            last = max(last, int(pt["lastPlayed"]))
        games.append(
            {
                "appId": app_id,
                "name": name,
                "exe": (entry.get("Exe") or "").strip('"'),
                "icon": icon_url,
                "capsuleUrl": capsule,
                "headerUrl": header,
                "lastPlayed": last,
                "playtimeForever": int(pt.get("playtimeForever") or 0),
                "playtime2Weeks": int(pt.get("playtime2Weeks") or 0),
                "sessions": pt.get("sessions") or [],
                "tracked": bool(pt),
                "nonSteam": True,
            }
        )
    games.sort(key=lambda g: g["lastPlayed"], reverse=True)
    return games, hidden


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--steamid", default="")
    args = ap.parse_args()
    acct = account_id(args.steamid.strip() or None)
    playtimes = load_millennium_playtimes()
    games: list[dict] = []
    hidden: list[str] = []
    for root in steam_roots():
        if acct:
            games, hidden = load_for_account(root, acct, playtimes)
            if games or hidden:
                break
        else:
            userdata = root / "userdata"
            if not userdata.is_dir():
                continue
            for child in sorted(userdata.iterdir()):
                if child.is_dir() and child.name.isdigit():
                    games, hidden = load_for_account(root, child.name, playtimes)
                    if games or hidden:
                        break
            if games or hidden:
                break
    json.dump({"nonSteam": games, "hiddenAppIds": hidden}, sys.stdout, ensure_ascii=False)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
