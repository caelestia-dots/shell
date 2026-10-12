#!/usr/bin/env python3
"""Checks the Nexus pages against what the settings search needs from them.

The search index is built at runtime by utils/scripts/settings-indexer.js,
which reads the page sources line by line. A row it can't read is simply left
out of search, with nothing to tell anyone. This catches that before merge.

Errors:
  - a settings row with neither a settingAnchor nor `searchable: false`
  - a settingAnchor or label further into its row than the indexer reads
  - a settingAnchor used twice, or not in kebab-case
  - a setting without an icon in the indexer's SETTING_ICONS, or an icon left
    behind for an anchor that no longer exists
  - a TRANSLATORS comment pushed away from its call by settingAnchor or
    searchable, which makes xgettext drop it
Warnings:
  - a row on a page with `searchable: false` that still has a settingAnchor

Rows are opted out with `searchable: false`, whole pages (ones showing a
selected device or app, for example) with `searchable: false` on the page.

The report goes to stderr. Colour is dropped when stderr is not a terminal.
The exit code is 1 when there is an error, or with --strict when there is
anything at all.
"""

import argparse
import json
import re
import sys
from pathlib import Path

RED = "\033[0;31m"
YELLOW = "\033[0;33m"
BOLD = "\033[1m"
RESET = "\033[0m"

REPO_ROOT = Path(__file__).resolve().parent.parent
PAGES_DIR = REPO_ROOT / "modules" / "nexus" / "pages"
INDEXER = REPO_ROOT / "utils" / "scripts" / "settings-indexer.js"

ERROR = "error"
WARNING = "warning"
LEVEL_COLOURS = {ERROR: RED, WARNING: YELLOW}

# Kept in step with the indexer: the row types it reads, and how many lines
# after a row's opening line it looks at for the anchor and label.
ROW_TYPES = r"ToggleRow|SliderRow|SelectRow|StepperRow|NavRow|RowButton|InfoRow|PopupRow|DefaultRow|TextFieldRow"
ROW_RE = re.compile(rf"^\s*({ROW_TYPES})\s*\{{")
ROW_WINDOW = 11

ANCHOR_RE = re.compile(r'^\s*settingAnchor:\s*"([^"]*)"')
LABEL_RE = re.compile(r"^\s*(?:label|text):\s*Tr\.")
SEARCHABLE_RE = re.compile(r"^\s*searchable:\s*false\s*$")
SECTION_RE = re.compile(r"^\s*SectionHeader\s*\{")
TRANSLATORS_RE = re.compile(r"^\s*//\s*TRANSLATORS:")
SEARCH_PROP_RE = re.compile(r"^\s*(settingAnchor|searchable):")
KEBAB_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
ICON_KEY_RE = re.compile(r'^\s*"([^"]+)":\s*"[^"]*",?\s*$')


def disable_colour() -> None:
    """Blank every escape code so the report is plain text."""
    global RED, YELLOW, BOLD, RESET, LEVEL_COLOURS
    RED = YELLOW = BOLD = RESET = ""
    LEVEL_COLOURS = dict.fromkeys(LEVEL_COLOURS, "")


class Issue:
    """One reported issue, at a 1 based line/column."""

    def __init__(self, file: str, line: int, col: int, level: str, rule: str, msg: str):
        self.file = file
        self.line = line
        self.col = col
        self.level = level
        self.rule = rule
        self.msg = msg

    def __str__(self):
        c = LEVEL_COLOURS.get(self.level, "")
        return f"{c}[{self.rule}]{RESET} {self.file}:{self.line}:{self.col}: {self.msg}"

    def to_dict(self) -> dict[str, object]:
        return {
            "file": self.file,
            "line": self.line,
            "column": self.col,
            "level": self.level,
            "rule": self.rule,
            "message": self.msg,
        }


class Row:
    """A settings row as the indexer sees it: its own bindings, not its children's."""

    def __init__(self, kind: str, line: int, section: str):
        self.kind = kind
        self.line = line
        self.section = section
        self.anchor: str | None = None
        self.anchor_line = 0
        self.label_line = 0
        self.searchable = True


def column(text: str) -> int:
    return len(text) - len(text.lstrip()) + 1


def braces(text: str) -> int:
    """Net brace depth change of a line, ignoring strings and line comments."""
    text = re.sub(r'"(?:\\.|[^"\\])*"', '""', text)
    text = text.split("//", 1)[0]
    return text.count("{") - text.count("}")


def parse_rows(lines: list[str]) -> list[Row]:
    rows = []
    section = ""
    i = 0
    while i < len(lines):
        if SECTION_RE.match(lines[i]):
            section = str(i)
        m = ROW_RE.match(lines[i])
        if not m:
            i += 1
            continue

        row = Row(m.group(1), i + 1, section)
        depth = braces(lines[i])
        j = i + 1
        while j < len(lines) and depth > 0:
            text = lines[j]
            # Only the row's own bindings, one level in
            if depth == 1:
                a = ANCHOR_RE.match(text)
                if a and row.anchor is None:
                    row.anchor = a.group(1)
                    row.anchor_line = j + 1
                if LABEL_RE.match(text) and not row.label_line:
                    row.label_line = j + 1
                if SEARCHABLE_RE.match(text):
                    row.searchable = False
            depth += braces(text)
            j += 1
        rows.append(row)
        i += 1
    return rows


def page_searchable(lines: list[str]) -> bool:
    """False when the page's root object opts out with `searchable: false`."""
    depth = 0
    for text in lines:
        if depth == 1 and SEARCHABLE_RE.match(text):
            return False
        depth += braces(text)
    return True


def icon_keys() -> dict[str, int]:
    """The anchors listed in the indexer's SETTING_ICONS, with their lines."""
    keys = {}
    inside = False
    for n, text in enumerate(INDEXER.read_text(encoding="utf-8").splitlines(), 1):
        if text.startswith("const SETTING_ICONS"):
            inside = True
            continue
        if inside:
            if text.startswith("}"):
                break
            m = ICON_KEY_RE.match(text)
            if m:
                keys[m.group(1)] = n
    return keys


def rel_path(path: Path) -> str:
    return str(path.relative_to(REPO_ROOT))


def check() -> tuple[list[Issue], int]:
    issues: list[Issue] = []
    anchors: dict[str, tuple[str, int]] = {}
    # Anchors that need an icon. An info section's rows merge into one result,
    # named after the section and jumping to its first row, so only that row
    # needs one.
    needs_icon: dict[str, tuple[str, int]] = {}
    files = sorted(PAGES_DIR.rglob("*.qml"))

    for path in files:
        rel = rel_path(path)
        lines = path.read_text(encoding="utf-8").splitlines()
        searchable_page = page_searchable(lines)
        info_sections: set[str] = set()

        for n, text in enumerate(lines):
            if TRANSLATORS_RE.match(text) and n + 1 < len(lines):
                nxt = SEARCH_PROP_RE.match(lines[n + 1])
                if nxt:
                    issues.append(
                        Issue(
                            rel,
                            n + 2,
                            column(lines[n + 1]),
                            ERROR,
                            "translators-comment",
                            f"`{nxt.group(1)}` separates a TRANSLATORS comment from its call, "
                            "xgettext will drop the comment; move it above the comment",
                        )
                    )

        for row in parse_rows(lines):
            if row.anchor is None:
                if searchable_page and row.searchable:
                    issues.append(
                        Issue(
                            rel,
                            row.line,
                            column(lines[row.line - 1]),
                            ERROR,
                            "missing-anchor",
                            f"{row.kind} has no settingAnchor, so search can't find it; "
                            "add one, or `searchable: false` if it shouldn't be found",
                        )
                    )
                continue

            col = column(lines[row.anchor_line - 1])
            if not searchable_page:
                issues.append(
                    Issue(
                        rel,
                        row.anchor_line,
                        col,
                        WARNING,
                        "unsearchable-page",
                        "settingAnchor on a page with `searchable: false` is never indexed",
                    )
                )
                continue

            if not KEBAB_RE.match(row.anchor):
                issues.append(
                    Issue(rel, row.anchor_line, col, ERROR, "anchor-format", f'"{row.anchor}" is not kebab-case')
                )
            if row.anchor in anchors:
                other, other_line = anchors[row.anchor]
                issues.append(
                    Issue(
                        rel,
                        row.anchor_line,
                        col,
                        ERROR,
                        "duplicate-anchor",
                        f'"{row.anchor}" is already used at {other}:{other_line}',
                    )
                )
            else:
                anchors[row.anchor] = (rel, row.anchor_line)

            for what, line in (("settingAnchor", row.anchor_line), ("label", row.label_line)):
                if line - row.line > ROW_WINDOW:
                    issues.append(
                        Issue(
                            rel,
                            line,
                            column(lines[line - 1]),
                            ERROR,
                            "outside-window",
                            f"the indexer only reads {ROW_WINDOW} lines past a row's opening line, "
                            f"move the {what} closer to the top",
                        )
                    )

            if row.kind == "InfoRow" and row.section:
                if row.section in info_sections:
                    continue
                info_sections.add(row.section)
            needs_icon[row.anchor] = (rel, row.anchor_line)

    icons = icon_keys()
    indexer = rel_path(INDEXER)
    for anchor, (rel, line) in needs_icon.items():
        if anchor not in icons:
            issues.append(
                Issue(rel, line, 1, ERROR, "missing-icon", f'"{anchor}" has no icon in SETTING_ICONS ({indexer})')
            )
    for anchor, line in icons.items():
        if anchor not in needs_icon:
            issues.append(Issue(indexer, line, 1, ERROR, "orphaned-icon", f'no setting uses the anchor "{anchor}"'))

    return issues, len(files)


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--json", action="store_true", help="report as JSON on stderr")
    parser.add_argument("--strict", action="store_true", help="exit non-zero for warnings as well as errors")
    return parser.parse_args(argv)


def report(issues: list[Issue], args: argparse.Namespace, checked: int) -> int:
    """Write the issues to stderr in the requested format, returning the exit code."""
    err = sys.stderr
    errors = sum(1 for i in issues if i.level == ERROR)
    warnings = len(issues) - errors
    failed = 1 if errors or (args.strict and warnings) else 0

    if args.json:
        print(json.dumps({"issues": [i.to_dict() for i in issues]}), file=err)
        return failed

    print(f"{BOLD}Checking {checked} Nexus page(s) for settings search issues...{RESET}\n", file=err)

    for issue in issues:
        print(issue, file=err)

    print(file=err)
    if not issues:
        print(f"{BOLD}No issues found.{RESET}", file=err)
        return failed

    by_rule: dict[str, int] = {}
    for issue in issues:
        by_rule[issue.rule] = by_rule.get(issue.rule, 0) + 1
    for rule, count in sorted(by_rule.items()):
        print(f"  {rule}: {count}", file=err)

    print(f"\n{BOLD}Found {errors} error(s) and {warnings} warning(s).{RESET}", file=err)
    return failed


def main() -> int:
    args = parse_args()

    if args.json or not sys.stderr.isatty():
        disable_colour()

    issues, checked = check()
    return report(issues, args, checked)


if __name__ == "__main__":
    sys.exit(main())
