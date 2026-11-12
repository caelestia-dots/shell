#!/bin/sh
# Drop-down desktop assistant: runs an agent CLI (claude, agy…) from a fixed workdir whose
# CLAUDE.md/AGENTS.md point it at the paleshell skill. Outside the repo so the repo's own
# CLAUDE.md isn't loaded.
src=$(dirname "$(realpath "$0")")/assistant
dir=${XDG_DATA_HOME:-$HOME/.local/share}/paleshell/assistant
mkdir -p "$dir"
for f in CLAUDE.md AGENTS.md GEMINI.md; do
    ln -sfn "$src/CLAUDE.md" "$dir/$f"
done
cd "$dir" || exit 1
exec "$@"
