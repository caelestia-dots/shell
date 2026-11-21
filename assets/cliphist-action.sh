#!/bin/sh
# Helper for the launcher clipboard history, wrapping cliphist.
#
# Usage: cliphist-action.sh <command> <db> [args...]
#
# <db> is the path of a cliphist database, or "-" for the default one.
# Flags must come before cliphist's own subcommand, hence the ch() helper.

set -eu

cmd=${1:?missing command}
db=${2:?missing database}
shift 2

# Non-default databases may live in a directory that doesn't exist yet
if [ "$db" != "-" ]; then
    mkdir -p "$(dirname "$db")"
fi

ch() {
    if [ "$db" = "-" ]; then
        cliphist "$@"
    else
        cliphist -db-path "$db" "$@"
    fi
}

case "$cmd" in
list)
    # Older cliphist versions don't have -preview-width
    ch -preview-width 300 list 2>/dev/null || ch list
    ;;
text)
    # text <db> <id> <max-bytes>
    ch decode "$1" | head -c "$2"
    ;;
image)
    # image <db> <id> <out-file>: decode to a file once, reuse afterwards
    out=$2
    if [ ! -s "$out" ]; then
        mkdir -p "$(dirname "$out")"
        tmp="$out.$$"
        if ch decode "$1" >"$tmp"; then
            mv -f "$tmp" "$out"
        else
            rm -f "$tmp"
            exit 1
        fi
    fi
    ;;
copy)
    # copy <db> <id>
    ch decode "$1" | wl-copy
    ;;
delete)
    # delete <db> <id>
    printf '%s\t\n' "$1" | ch delete
    ;;
prune)
    # prune <db> <cache-dir>: drop decoded images older than a day
    find "$1" -type f -mmin +1440 -delete 2>/dev/null || true
    ;;
wipe)
    # wipe <db>: clear the whole history of a database
    ch wipe
    ;;
current)
    # current <db> <max-bytes>: what the clipboard holds right now, as a line with the
    # kind (image or text) followed by the text, if any
    types=$(timeout 1 wl-paste --list-types 2>/dev/null) || exit 0
    if printf '%s\n' "$types" | grep -q '^image/'; then
        echo image
    elif printf '%s\n' "$types" | grep -qiE '^(text/|utf8_string$|string$|text$)'; then
        echo text
        timeout 1 wl-paste --no-newline --type text 2>/dev/null | head -c "$1"
    fi
    ;;
active)
    # active <db> <id>...: print the ids whose content is exactly what the clipboard holds
    tmp=$(mktemp)
    trap 'rm -f "$tmp"' EXIT
    timeout 1 wl-paste --no-newline --type text >"$tmp" 2>/dev/null || exit 0
    for id in "$@"; do
        if ch decode "$id" 2>/dev/null | cmp -s - "$tmp"; then
            echo "$id"
        fi
    done
    ;;
pin)
    # pin <source-db> <id> <pins-db>: copy an entry into the pins database
    mkdir -p "$(dirname "$2")"
    ch decode "$1" | cliphist -db-path "$2" store
    ;;
*)
    echo "cliphist-action: unknown command '$cmd'" >&2
    exit 2
    ;;
esac
