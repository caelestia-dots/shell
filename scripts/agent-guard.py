#!/usr/bin/env python3
"""Claude Code PreToolUse hook: enforces the CLAUDE.md rules that a prompt alone can't guarantee.

deny -> the action is blocked and the reason goes back to the agent.
ask  -> Iago confirms it (terminal or the notch's approval card), even in bypass mode.

Rules (keep in sync with CLAUDE.md "Usuario y reglas"):
  deny  git push, sudo/doas/pkexec, `cmake --install`, grim without a region (-g)
  ask   git commit/reset --hard/clean, rm -r, pacman/paru that change packages,
        writes outside the repo and the scratchpad (Edit/Write, or Bash writing into ~/.config etc.)
"""

import json
import os
import re
import sys

DENY = [
    (r"\bgit\s+push\b", "No push: Iago lo hace él (CLAUDE.md)."),
    (r"(^\s*|[;&|(]\s*|\bxargs\s+)(sudo|doas|pkexec|run0)\b", "Los comandos con sudo los ejecuta Iago: dáselos en un bloque bash."),
    (r"\bcmake\s+--install\b", "Los módulos Caelestia.* no se instalan; se usan desde build/qml."),
    (r"\bgrim\b(?![^;&|]*\s-g\b)", "Nunca grim de la pantalla completa: usa -g con la geometría de la ventana de prueba."),
]
ASK = [
    (r"\bgit\s+(commit|reset\s+--hard|clean\s+-\w*f|checkout\s+--\s|restore\b|stash\s+(drop|clear))", "Acción de git que crea historia o descarta cambios."),
    (r"\brm\s+(-\w*[rR]|--recursive)", "Borrado recursivo."),
    (r"\b(pacman|paru|yay)\s+-(S|R|U)", "Cambia paquetes del sistema."),
]
# Bash writes into these trees need confirmation (CLAUDE.md: ask before touching things outside the repo).
GUARDED_DIRS = r"(~|\$HOME|/home/[^/\s]+)/\.(config|local)/(?!share/paleshell/assistant)"
WRITE_OPS = r"(\bsed\s+-i|\btee\b|>\s*[^&\s]|\bmv\b|\bcp\b|\bln\b|\brm\b|\btruncate\b|\binstall\b)"


def decide(kind, reason):
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": kind,
        "permissionDecisionReason": f"[agent-guard] {reason}",
    }}))
    sys.exit(0)


def inside(path, roots):
    path = os.path.realpath(os.path.expanduser(path))
    return any(path == r or path.startswith(r + os.sep) for r in roots)


def main():
    try:
        event = json.load(sys.stdin)
    except ValueError:
        return
    tool = event.get("tool_name", "")
    args = event.get("tool_input") or {}
    project = os.path.realpath(os.environ.get("CLAUDE_PROJECT_DIR") or event.get("cwd") or ".")
    claude_dir = os.path.realpath(os.path.expanduser("~/.claude/projects"))  # agent memory
    safe_roots = [project, os.path.realpath(os.environ.get("TMPDIR", "/tmp")), "/tmp", claude_dir]

    if tool == "Bash":
        # Heredoc bodies are data (file contents, commit messages), not commands.
        cmd = re.sub(r"<<-?\s*(['\"]?)(\w+)\1[^\n]*\n.*?^\s*\2\s*$", "", args.get("command", ""), flags=re.S | re.M)
        for pattern, reason in DENY:
            if re.search(pattern, cmd, re.M):
                decide("deny", reason)
        for pattern, reason in ASK:
            if re.search(pattern, cmd):
                decide("ask", reason)
        for segment in re.split(r"&&|\|\||;|\n", cmd):
            if re.search(GUARDED_DIRS, segment) and re.search(WRITE_OPS, segment):
                decide("ask", "Escribe fuera del repo (~/.config o ~/.local): Iago lo confirma.")
    elif tool in ("Edit", "Write", "NotebookEdit", "MultiEdit"):
        path = args.get("file_path") or args.get("notebook_path") or ""
        if path and not inside(path, safe_roots):
            decide("ask", f"Edita fuera del repo: {path}")


if __name__ == "__main__":
    main()
