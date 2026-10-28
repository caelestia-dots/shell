#!/usr/bin/env python3
"""Steam play activity history for Caelestia.

The Steam Web API only exposes lifetime and two-week totals, so this keeps two
sources of per-day activity:

  poll      Detect running Steam games (Steam's `reaper AppId=<id>` launcher
            process) and record real sessions while the shell is running.
  snapshot  Compare playtime_forever against the previous snapshot and
            attribute whatever the tracked sessions do not explain to the day
            of rtime_last_played (covers play while the shell was off).

Usage:
  steam-activity.py poll
  steam-activity.py snapshot '<json [[appId, playtimeForever, lastPlayed], ...]>'

Prints JSON: { "days": { appId: { "YYYY-MM-DD": minutes } },
               "sessions": { appId: [ { start, end } ] },
               "active": { appId: start } }
"""

from __future__ import annotations

import fcntl
import json
import os
import sys
import time
from datetime import date, datetime
from pathlib import Path

KEEP_DAYS = 400
POLL_GAP = 180  # seconds without seeing a game before its session is closed
MIN_SESSION = 60
SHORTCUT_BIT = 0x80000000  # non-Steam shortcuts, tracked by Millennium instead


def state_dir() -> Path:
    base = os.environ.get("XDG_STATE_HOME") or str(Path.home() / ".local/state")
    return Path(base) / "caelestia"


def running_app_ids() -> set[str]:
    ids: set[str] = set()
    for proc in Path("/proc").iterdir():
        if not proc.name.isdigit():
            continue
        try:
            args = (proc / "cmdline").read_bytes().split(b"\x00")
        except OSError:
            continue
        if not args or not args[0].endswith(b"reaper"):
            continue
        for arg in args[1:]:
            if arg.startswith(b"AppId="):
                value = arg[6:].decode(errors="ignore")
                if value.isdigit() and 0 < int(value) < SHORTCUT_BIT:
                    ids.add(value)
                break
    return ids


def close_session(state: dict, app_id: str, start: int, end: int) -> None:
    if end - start >= MIN_SESSION:
        state["sessions"].setdefault(app_id, []).append({"start": start, "end": end})


def poll(state: dict, now: int) -> None:
    active: dict[str, dict[str, int]] = state["active"]
    running = running_app_ids()
    for app_id in list(active):
        entry = active[app_id]
        stale = now - entry["seen"] > POLL_GAP
        if app_id not in running or stale:
            close_session(state, app_id, entry["start"], entry["seen"])
            del active[app_id]
    for app_id in running:
        if app_id in active:
            active[app_id]["seen"] = now
        else:
            active[app_id] = {"start": now, "seen": now}


def tracked_seconds(state: dict, app_id: str, since: int, until: int) -> int:
    total = 0
    spans = list(state["sessions"].get(app_id, []))
    if app_id in state["active"]:
        a = state["active"][app_id]
        spans.append({"start": a["start"], "end": a["seen"]})
    for s in spans:
        total += max(0, min(s["end"], until) - max(s["start"], since))
    return total


def snapshot(state: dict, now: int, games: list) -> None:
    snap: dict[str, list[int]] = state["snapshot"]
    days: dict[str, dict[str, int]] = state["days"]
    for entry in games:
        try:
            app_id, minutes, last = str(entry[0]), int(entry[1]), int(entry[2] or 0)
        except (IndexError, TypeError, ValueError):
            continue
        prev = snap.get(app_id)
        if isinstance(prev, int):
            prev = [prev, 0]
        if prev is not None and minutes > prev[0]:
            residual = minutes - prev[0] - tracked_seconds(state, app_id, prev[1], now) // 60
            if residual > 1:
                day = datetime.fromtimestamp(last or now).date().isoformat()
                bucket = days.setdefault(app_id, {})
                bucket[day] = bucket.get(day, 0) + residual
        if prev is None or prev[0] != minutes:
            snap[app_id] = [minutes, now]


def prune(state: dict, now: int) -> None:
    horizon = now - KEEP_DAYS * 86400
    cutoff = date.fromtimestamp(horizon).isoformat()
    for app_id in list(state["days"]):
        kept = {d: m for d, m in state["days"][app_id].items() if d >= cutoff}
        if kept:
            state["days"][app_id] = kept
        else:
            del state["days"][app_id]
    for app_id in list(state["sessions"]):
        kept = [s for s in state["sessions"][app_id] if s["end"] >= horizon]
        if kept:
            state["sessions"][app_id] = kept
        else:
            del state["sessions"][app_id]


def main() -> int:
    cmd = sys.argv[1] if len(sys.argv) > 1 else "poll"
    path = state_dir() / "steam-activity.json"
    path.parent.mkdir(parents=True, exist_ok=True)

    with open(path.with_suffix(".lock"), "w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        try:
            state = json.loads(path.read_text(encoding="utf-8"))
            if not isinstance(state, dict):
                state = {}
        except (OSError, json.JSONDecodeError):
            state = {}
        for key in ("snapshot", "days", "sessions", "active"):
            if not isinstance(state.get(key), dict):
                state[key] = {}

        now = int(time.time())
        if cmd == "snapshot":
            try:
                games = json.loads(sys.argv[2]) if len(sys.argv) > 2 else []
            except json.JSONDecodeError:
                games = []
            poll(state, now)
            snapshot(state, now, games)
        else:
            poll(state, now)
        prune(state, now)

        tmp = path.with_suffix(".tmp")
        tmp.write_text(json.dumps(state), encoding="utf-8")
        tmp.replace(path)

    out_sessions = {k: sorted(v, key=lambda s: s["start"], reverse=True) for k, v in state["sessions"].items()}
    out_active = {k: v["start"] for k, v in state["active"].items()}
    json.dump({"days": state["days"], "sessions": out_sessions, "active": out_active}, sys.stdout)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
