#!/usr/bin/env python3
"""Goal check for agent sessions: is the working tree in a state worth handing back?

Checks only what changed against HEAD (plus untracked files):
  - QML conventions (scripts/qml-lint-conventions.py) on the whole tree
  - QML syntax with Qt 6 qmllint on changed .qml files
  - Python syntax on changed .py files
  - C++ plugin build when plugin/ changed and a build/ dir exists

Usage:
  scripts/agent-check.py           run the checks, exit 1 on failure
  scripts/agent-check.py --hook    Claude Code Stop hook: reads the event on stdin and exits 2
                                   with the failures on stderr so the agent fixes them first.
                                   Blocks at most once per stop (stop_hook_active) so it can't loop.
"""

import ast
import json
import os
import subprocess
import sys

QMLLINT = "/usr/lib/qt6/bin/qmllint"
ROOT = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True).stdout.strip()


def run(cmd, timeout=300):
    try:
        p = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True, timeout=timeout)
    except subprocess.TimeoutExpired:
        return 1, f"timed out after {timeout}s: {' '.join(cmd)}"
    return p.returncode, (p.stdout + p.stderr).strip()


def changed_files():
    _, diff = run(["git", "diff", "--name-only", "HEAD"])
    _, new = run(["git", "ls-files", "--others", "--exclude-standard"])
    return [f for f in set(diff.split() + new.split()) if os.path.isfile(os.path.join(ROOT, f))]


def check(files):
    failures = []
    qml = [f for f in files if f.endswith(".qml") and not f.startswith("zz_")]
    py = [f for f in files if f.endswith(".py")]

    if qml:
        rc, out = run([sys.executable, "scripts/qml-lint-conventions.py"])
        if rc != 0 or "No violations found" not in out:
            failures.append(f"qml-lint-conventions:\n{out[-3000:]}")
        if os.path.exists(QMLLINT):
            for f in qml:
                # Qt 6 qmllint exits 255 only on syntax errors; import warnings stay 0.
                rc, out = run([QMLLINT, f], timeout=60)
                if rc == 255:
                    failures.append(f"qmllint syntax error in {f}:\n{out[-1500:]}")
    for f in py:
        try:
            with open(os.path.join(ROOT, f), encoding="utf-8") as fh:
                ast.parse(fh.read(), f)
        except SyntaxError as e:
            failures.append(f"python syntax error in {f}:{e.lineno}: {e.msg}")
    if any(f.startswith("plugin/") for f in files) and os.path.isdir(os.path.join(ROOT, "build")):
        rc, out = run(["cmake", "--build", "build"], timeout=600)
        if rc != 0:
            failures.append(f"cmake --build build failed:\n{out[-3000:]}")
    return failures


def main():
    hook = "--hook" in sys.argv
    if hook:
        try:
            event = json.load(sys.stdin)
        except ValueError:
            event = {}
        if event.get("stop_hook_active"):
            return 0
    files = changed_files()
    if not files:
        return 0
    failures = check(files)
    if not failures:
        if not hook:
            print(f"OK: {len(files)} changed file(s) pass the checks.")
        return 0
    report = "Goal check failed (scripts/agent-check.py). Fix before finishing:\n\n" + "\n\n".join(failures)
    print(report, file=sys.stderr)
    return 2 if hook else 1


if __name__ == "__main__":
    sys.exit(main())
