#!/usr/bin/env python3
"""Self-test for agent-guard.py: python3 scripts/test-agent-guard.py"""

import json
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
GUARD = os.path.join(HERE, "agent-guard.py")
REPO = os.path.dirname(HERE)
HOME = os.path.expanduser("~")


def decision(tool, tool_input):
    out = subprocess.run(
        [sys.executable, GUARD],
        input=json.dumps({"tool_name": tool, "tool_input": tool_input, "cwd": REPO}),
        capture_output=True, text=True, env={"CLAUDE_PROJECT_DIR": REPO, "HOME": HOME},
    ).stdout
    return json.loads(out)["hookSpecificOutput"]["permissionDecision"] if out.strip() else "allow"


BASH = [
    ("git push origin x", "deny"), ("cd a && git push", "deny"),
    ("sudo pacman -Syu", "deny"), ("  sudo ls", "deny"), ("ls | xargs sudo rm", "deny"), ("echo 'use sudo'", "allow"),
    ("grim out.png", "deny"), ("grim -g '0,0 10x10' o.png", "allow"), ("paleshell season grimm", "allow"),
    ("cmake --install build", "deny"), ("cmake --build build", "allow"),
    ("git commit -m x", "ask"), ("git status", "allow"),
    ("rm -rf build", "ask"), ("rm file.txt", "allow"),
    ("paru -S foo", "ask"), ("pacman -Q", "allow"),
    ("sed -i s/a/b/ ~/.config/hypr/x.lua", "ask"), ("cat ~/.config/hypr/x.lua", "allow"),
    ("echo hi > $HOME/.config/paleshell/shell.json", "ask"), ("qs log -c paleshell | grep ERROR", "allow"),
    ("cat > notes.md <<'EOF'\nnever git push or sudo here\nEOF\nls", "allow"),
    ("cat > notes.md <<'EOF'\ntext\nEOF\ngit push", "deny"),
]
EDITS = [
    (os.path.join(REPO, "a.qml"), "allow"), (f"{HOME}/.config/hypr/x.lua", "ask"),
    ("/tmp/claude-1000/x", "allow"), (f"{HOME}/.claude/projects/m/MEMORY.md", "allow"),
]

bad = [(c, want, got) for c, want in BASH if (got := decision("Bash", {"command": c})) != want]
bad += [(p, want, got) for p, want in EDITS if (got := decision("Edit", {"file_path": p})) != want]
assert not bad, bad
print(f"guard ok ({len(BASH) + len(EDITS)} cases)")
