#!/usr/bin/env python3
"""Print an agent's plan limits as one JSON line: {"session": {...}, "week": {...}} or {"error": "..."}.

Usage: ai-usage.py <claude|agy>

Each window is {"percent": 0-100, "resetsAt": ISO date}. Tokens are only read from where each CLI
keeps them and never leave the Authorization header of the request to their own provider.
"""

import json
import os
import subprocess
import sys
import urllib.error
import urllib.request
from datetime import datetime, timezone

CLAUDE_ENDPOINT = "https://api.anthropic.com/api/oauth/usage"
AGY_ENDPOINT = "https://daily-cloudcode-pa.googleapis.com/v1internal:"


def fetch(req):
    """JSON body, or raises LookupError with the error code to report."""
    try:
        with urllib.request.urlopen(req, timeout=10) as res:
            return json.load(res)
    except urllib.error.HTTPError as e:
        raise LookupError("auth" if e.code in (401, 403) else "rate-limited" if e.code == 429 else f"http-{e.code}")
    except (OSError, ValueError):
        raise LookupError("offline")


def claude():
    claude_dir = os.environ.get("CLAUDE_CONFIG_DIR") or os.path.expanduser("~/.claude")
    try:
        with open(os.path.join(claude_dir, ".credentials.json")) as f:
            token = json.load(f)["claudeAiOauth"]["accessToken"]
    except (OSError, KeyError, ValueError, TypeError):
        raise LookupError("not-logged-in")

    data = fetch(urllib.request.Request(CLAUDE_ENDPOINT, headers={
        "Authorization": "Bearer " + token,
        "anthropic-beta": "oauth-2025-04-20",
        "Accept": "application/json",
    }))
    out = {}
    for key, name in (("five_hour", "session"), ("seven_day", "week")):
        bucket = data.get(key)
        if isinstance(bucket, dict) and bucket.get("utilization") is not None:
            out[name] = {"percent": float(bucket["utilization"]), "resetsAt": bucket.get("resets_at") or ""}
    return out


def agy_token():
    # agy keeps its Google sign-in in the Secret Service keyring, or in a file without one
    try:
        raw = subprocess.run(["secret-tool", "lookup", "service", "gemini", "username", "antigravity"],
                             capture_output=True, text=True, timeout=3).stdout
        data = json.loads(raw) if raw.strip() else None
    except (OSError, ValueError, subprocess.SubprocessError):
        data = None
    if not isinstance(data, dict):
        try:
            with open(os.path.expanduser("~/.gemini/antigravity-cli/antigravity-oauth-token")) as f:
                data = json.load(f)
        except (OSError, ValueError):
            raise LookupError("not-logged-in")
    token = data.get("token") if isinstance(data.get("token"), dict) else data
    access = token.get("access_token")
    if not access:
        raise LookupError("not-logged-in")
    expiry = token.get("expiry")
    if expiry:
        try:
            if datetime.fromisoformat(str(expiry).replace("Z", "+00:00")) <= datetime.now(timezone.utc):
                raise LookupError("expired")  # agy refreshes it the next time it runs
        except ValueError:
            pass
    return access


def agy():
    token = agy_token()

    def post(method, body):
        return fetch(urllib.request.Request(AGY_ENDPOINT + method, data=json.dumps(body).encode(), headers={
            "Authorization": "Bearer " + token,
            "Content-Type": "application/json",
            "User-Agent": "antigravity",
        }))

    project = post("loadCodeAssist", {}).get("cloudaicompanionProject")
    project = project.get("id") if isinstance(project, dict) else project
    data = post("retrieveUserQuotaSummary", {"project": project} if project else {})

    groups = [g for g in data.get("groups") or [] if isinstance(g, dict)]
    if not groups and data.get("buckets"):
        groups = [{"displayName": "Gemini", "buckets": data["buckets"]}]
    if not groups:
        return {}
    # The Gemini group holds the plan's own 5-hour and weekly limits
    gemini = next((g for g in groups if "gemini" in str(g.get("displayName", "")).lower()), groups[0])
    out = {}
    for b in gemini.get("buckets") or []:
        if not isinstance(b, dict) or b.get("disabled") is True:
            continue
        remaining = b.get("remainingFraction")
        if remaining is None or isinstance(remaining, bool):
            continue
        tag = " ".join(str(b.get(k, "")) for k in ("window", "bucketId", "displayName")).lower()
        name = "session" if "5h" in tag or "five" in tag else "week" if "week" in tag else None
        if name:
            out[name] = {"percent": round(max(0.0, min(1.0, 1 - float(remaining))) * 100, 1),
                         "resetsAt": b.get("resetTime") or ""}
    return out


def main(agent):
    try:
        out = {"claude": claude, "agy": agy}[agent]()
    except LookupError as e:
        return {"error": str(e)}
    return out or {"error": "no-limits"}


if __name__ == "__main__":
    if len(sys.argv) != 2 or sys.argv[1] not in ("claude", "agy"):
        sys.exit(__doc__)
    print(json.dumps(main(sys.argv[1])))
