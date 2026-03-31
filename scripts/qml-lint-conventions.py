#!/usr/bin/env python3
"""Checks QML files for Qt coding convention violations.

https://doc.qt.io/qt-6/qml-codingconventions.html

Required ordering within each QML object (with blank line between sections):
  1. id
  2. property declarations
  3. signal declarations
  4. JavaScript functions
  5. object properties (bindings)
  6. child objects
  7. component definitions
"""

import re
import sys
from enum import IntEnum
from pathlib import Path

RED = "\033[0;31m"
YELLOW = "\033[0;33m"
CYAN = "\033[0;36m"
GREEN = "\033[0;32m"
MAGENTA = "\033[0;35m"
BOLD = "\033[1m"
RESET = "\033[0m"

REPO_ROOT = Path(__file__).resolve().parent.parent


class Section(IntEnum):
    ID = 0
    PROPERTY = 1
    SIGNAL = 2
    FUNCTION = 3
    BINDING = 4
    CHILD = 5
    COMPONENT_DEF = 6


SECTION_NAMES = {
    Section.ID: "id",
    Section.PROPERTY: "property declarations",
    Section.SIGNAL: "signal declarations",
    Section.FUNCTION: "functions",
    Section.BINDING: "bindings",
    Section.CHILD: "child objects",
    Section.COMPONENT_DEF: "component definitions",
}

RULE_COLOURS = {
    "file-structure": RED,
    "import-order": GREEN,
    "section-order": YELLOW,
    "missing-section-separator": CYAN,
    "blank-after-open-brace": MAGENTA,
    "blank-before-close-brace": MAGENTA,
}

IMPORT_RE = re.compile(r"^import\s+(\S+)")


def import_group(module: str) -> tuple[int, int] | None:
    """Return (group, depth) for a module import, or None to skip."""
    if module.startswith('"'):
        return None
    depth = module.count(".") + 1
    if module == "QtQuick" or module.startswith("QtQuick."):
        return (1, depth)
    if module.startswith("Qt"):
        return (2, depth)
    if module == "Quickshell" or module.startswith("Quickshell."):
        return (3, depth)
    if module == "M3Shapes":
        return (4, depth)
    if module == "Caelestia" or module.startswith("Caelestia."):
        return (5, depth)
    if module == "qs.components" or module.startswith("qs.components."):
        return (6, depth)
    if module == "qs.services":
        return (7, depth)
    if module == "qs.config":
        return (8, depth)
    if module == "qs.utils":
        return (9, depth)
    if module == "qs.modules" or module.startswith("qs.modules."):
        return (10, depth)
    return None


def parse_imports(lines: list[str]) -> tuple[int | None, int | None, list[str], list[tuple[str, int, int, str]]]:
    """Parse the import block, returning (first_idx, last_idx, relative_imports, module_imports).

    module_imports entries are (line_text, group, depth, module_name).
    """
    first_import = None
    last_import = None
    relative_imports: list[str] = []
    module_imports: list[tuple[str, int, int, str]] = []

    for i, line in enumerate(lines):
        stripped = line.strip()
        if not stripped or stripped.startswith("//") or stripped.startswith("pragma "):
            continue
        m = IMPORT_RE.match(stripped)
        if m:
            if first_import is None:
                first_import = i
            last_import = i
            module = m.group(1)
            result = import_group(module)
            if result is None:
                relative_imports.append(line)
            else:
                group, depth = result
                module_imports.append((line, group, depth, module))
            continue
        break

    return first_import, last_import, relative_imports, module_imports


def check_imports(filepath: Path, lines: list[str], rel: str) -> list[Violation]:
    """Check that module imports are in the required order."""
    violations = []
    _, _, _, module_imports = parse_imports(lines)
    imports = [(i, *entry) for i, entry in enumerate(module_imports)]

    for j in range(1, len(imports)):
        _, prev_line, prev_group, prev_depth, prev_mod = imports[j - 1]
        _, curr_line, curr_group, curr_depth, curr_mod = imports[j]

        # Find actual line number for the current import
        lineno = 0
        count = 0
        for li, line in enumerate(lines):
            stripped = line.strip()
            m = IMPORT_RE.match(stripped)
            if m and import_group(m.group(1)) is not None:
                if count == j:
                    lineno = li + 1
                    break
                count += 1

        if curr_group < prev_group:
            violations.append(
                Violation(
                    rel,
                    lineno,
                    "import-order",
                    f"'{curr_mod}' should appear before '{prev_mod}'",
                )
            )
        elif curr_group == prev_group and curr_depth < prev_depth:
            violations.append(
                Violation(
                    rel,
                    lineno,
                    "import-order",
                    f"'{curr_mod}' should appear before '{prev_mod}' (less nested first)",
                )
            )

    return violations


def fix_imports(lines: list[str]) -> list[str]:
    """Sort imports and return the modified lines."""
    first, last, relative, module = parse_imports(lines)
    if first is None:
        return lines

    module.sort(key=lambda x: (x[1], x[2], x[3]))
    sorted_imports = relative + [entry[0] for entry in module]
    return lines[:first] + sorted_imports + lines[last + 1 :]


def check_file_structure(lines: list[str], rel: str) -> list[Violation]:
    """Check file-level structure: pragmas, then imports, then content."""
    violations = []
    pragma_indices: list[int] = []
    import_indices: list[int] = []
    content_start: int | None = None

    for i, line in enumerate(lines):
        stripped = line.strip()
        if not stripped:
            continue
        if stripped.startswith("pragma "):
            pragma_indices.append(i)
        elif IMPORT_RE.match(stripped):
            import_indices.append(i)
        else:
            content_start = i
            break

    # Pragmas must come before imports
    if pragma_indices and import_indices:
        if pragma_indices[-1] > import_indices[0]:
            violations.append(
                Violation(rel, pragma_indices[-1] + 1, "file-structure", "pragmas should appear before imports")
            )

    # Separator between pragmas and imports
    if pragma_indices and import_indices:
        gap = import_indices[0] - pragma_indices[-1] - 1
        if gap == 0:
            violations.append(
                Violation(
                    rel, import_indices[0] + 1, "file-structure", "blank line expected between pragmas and imports"
                )
            )
        elif gap > 1:
            violations.append(
                Violation(
                    rel,
                    pragma_indices[-1] + 3,
                    "file-structure",
                    "only one blank line expected between pragmas and imports",
                )
            )

    # No blank lines within imports
    for j in range(1, len(import_indices)):
        if import_indices[j] != import_indices[j - 1] + 1:
            for gap_line in range(import_indices[j - 1] + 1, import_indices[j]):
                if not lines[gap_line].strip():
                    violations.append(
                        Violation(rel, gap_line + 1, "file-structure", "no blank lines expected within imports")
                    )

    # Separator between imports/pragmas and content
    last_header = import_indices[-1] if import_indices else (pragma_indices[-1] if pragma_indices else None)
    if last_header is not None and content_start is not None:
        gap = content_start - last_header - 1
        label = "imports" if import_indices else "pragmas"
        if gap == 0:
            violations.append(
                Violation(
                    rel, content_start + 1, "file-structure", f"blank line expected between {label} and content"
                )
            )
        elif gap > 1:
            violations.append(
                Violation(
                    rel,
                    last_header + 3,
                    "file-structure",
                    f"only one blank line expected between {label} and content",
                )
            )

    return violations


def fix_file_structure(lines: list[str]) -> list[str]:
    """Ensure correct file structure: pragmas, blank, imports (no gaps), blank, content."""
    pragmas: list[str] = []
    imports: list[str] = []
    content_start: int | None = None

    for i, line in enumerate(lines):
        stripped = line.strip()
        if not stripped:
            continue
        if stripped.startswith("pragma "):
            pragmas.append(line)
        elif IMPORT_RE.match(stripped):
            imports.append(line)
        else:
            content_start = i
            break

    if content_start is None:
        content_start = len(lines)

    # Skip any blank lines at the start of content
    while content_start < len(lines) and not lines[content_start].strip():
        content_start += 1

    result: list[str] = []
    has_content = content_start < len(lines)
    if pragmas:
        result.extend(pragmas)
        if imports or has_content:
            result.append("")
    if imports:
        result.extend(imports)
        if has_content:
            result.append("")
    result.extend(lines[content_start:])
    return result


def fix_section_separators(lines: list[str]) -> list[str]:
    """Insert blank lines between different sections and return modified lines."""
    insertions: list[int] = []
    scopes: dict[str, ScopeTracker] = {}
    in_block_comment = False
    func_skip_depth = 0
    prev_blank: dict[str, bool] = {}

    for i, line in enumerate(lines):
        stripped = line.strip()
        indent = get_indent(line)

        if in_block_comment:
            if BLOCK_COMMENT_END.search(stripped):
                in_block_comment = False
            continue
        if BLOCK_COMMENT_START.search(stripped) and not BLOCK_COMMENT_END.search(stripped):
            in_block_comment = True
            continue

        if not stripped:
            for key in prev_blank:
                prev_blank[key] = True
            continue

        if COMMENT_LINE_RE.match(stripped):
            continue

        if func_skip_depth > 0:
            func_skip_depth += stripped.count("{") - stripped.count("}")
            if func_skip_depth <= 0:
                func_skip_depth = 0
            continue

        if stripped == "}":
            to_remove = [k for k in scopes if len(k) > len(indent)]
            for k in to_remove:
                del scopes[k]
                prev_blank.pop(k, None)
            continue

        section = classify_line(stripped)
        if section is None:
            continue

        if indent not in scopes:
            scopes[indent] = ScopeTracker()
            prev_blank[indent] = True

        tracker = scopes[indent]
        had_blank = prev_blank.get(indent, True)

        if tracker.last_section is not None and section != tracker.last_section and not had_blank:
            insertions.append(i)

        if tracker.last_section is None or section >= tracker.last_section:
            tracker.last_section = section
            tracker.last_section_line = i + 1

        prev_blank[indent] = False

        brace_count = stripped.count("{") - stripped.count("}")
        if brace_count > 0 and section == Section.FUNCTION:
            func_skip_depth = brace_count
        if brace_count > 0 and section == Section.BINDING:
            colon_idx = stripped.index(":")
            after_colon = stripped[colon_idx + 1 :].strip()
            if not re.match(r"^[A-Z]", after_colon):
                func_skip_depth = brace_count
        if brace_count > 0 and section in (Section.CHILD, Section.COMPONENT_DEF):
            to_remove = [k for k in scopes if len(k) > len(indent)]
            for k in to_remove:
                del scopes[k]
                prev_blank.pop(k, None)

    result = list(lines)
    for idx in reversed(insertions):
        result.insert(idx, "")
    return result


def fix_file(filepath: Path) -> bool:
    """Fix auto-fixable violations. Returns True if file was modified."""
    try:
        text = filepath.read_text()
    except (OSError, UnicodeDecodeError):
        return False

    lines = text.splitlines()
    lines = fix_imports(lines)
    lines = fix_file_structure(lines)
    lines = fix_section_separators(lines)
    new_text = "\n".join(lines)
    if text.endswith("\n"):
        new_text += "\n"
    if new_text != text:
        filepath.write_text(new_text)
        return True
    return False


# Regexes
PROPERTY_DECL_RE = re.compile(r"^(?:required\s+|readonly\s+|default\s+)*property\s")
SIGNAL_RE = re.compile(r"^signal\s")
FUNCTION_RE = re.compile(r"^function\s")
ID_RE = re.compile(r"^id\s*:\s*[a-zA-Z_]\w*\s*$")
ENUM_RE = re.compile(r"^enum\s")
COMPONENT_DEF_RE = re.compile(r"^component\s+\w+\s*:")
COMMENT_LINE_RE = re.compile(r"^//")
BLOCK_COMMENT_START = re.compile(r"/\*")
BLOCK_COMMENT_END = re.compile(r"\*/")
BINDING_RE = re.compile(r"^[a-z][a-zA-Z0-9_.]*\s*:")
SIGNAL_HANDLER_RE = re.compile(r"^on[A-Z][a-zA-Z]*\s*:")
# Child object: starts with uppercase or is a known child-like pattern
CHILD_OBJECT_RE = re.compile(r"^[A-Z][a-zA-Z0-9_.]*\s*\{")
# Inline component: Component { ... }
INLINE_COMPONENT_RE = re.compile(r"^Component\s*\{")
# Behavior on <property> {, NumberAnimation on <property> {, etc.
BEHAVIOR_ON_RE = re.compile(r"^[A-Z]\w+\s+on\s+\w[\w.]*\s*\{")
# Attached signal handler: Component.onCompleted:, Drag.onDragStarted:, etc.
ATTACHED_HANDLER_RE = re.compile(r"^[A-Z]\w+\.on[A-Z]\w*\s*:")


class Violation:
    def __init__(self, file: str, line: int, rule: str, msg: str):
        self.file = file
        self.line = line
        self.rule = rule
        self.msg = msg

    def __str__(self):
        c = RULE_COLOURS.get(self.rule, "")
        return f"{c}[{self.rule}]{RESET} {self.file}:{self.line}: {self.msg}"


class ScopeTracker:
    """Tracks the current section and last-seen state for one indent level."""

    def __init__(self):
        self.last_section: Section | None = None
        self.last_section_line: int = 0
        self.had_blank_before_current: bool = True  # no separator needed at start


def get_indent(line: str) -> str:
    return line[: len(line) - len(line.lstrip())]


def classify_line(stripped: str) -> Section | None:
    """Classify a stripped QML line into a section category."""
    if ID_RE.match(stripped):
        return Section.ID
    if PROPERTY_DECL_RE.match(stripped):
        return Section.PROPERTY
    if SIGNAL_RE.match(stripped):
        return Section.SIGNAL
    if FUNCTION_RE.match(stripped):
        return Section.FUNCTION
    if ENUM_RE.match(stripped):
        return Section.PROPERTY  # enums go with declarations
    if COMPONENT_DEF_RE.match(stripped):
        return Section.COMPONENT_DEF
    if BEHAVIOR_ON_RE.match(stripped):
        return Section.CHILD
    if CHILD_OBJECT_RE.match(stripped):
        return Section.CHILD
    if INLINE_COMPONENT_RE.match(stripped):
        return Section.CHILD
    if BINDING_RE.match(stripped) or SIGNAL_HANDLER_RE.match(stripped):
        return Section.BINDING
    if ATTACHED_HANDLER_RE.match(stripped):
        return Section.BINDING
    return None


def check_file(filepath: Path) -> list[Violation]:
    violations = []
    rel = str(filepath.relative_to(REPO_ROOT))

    try:
        lines = filepath.read_text().splitlines()
    except (OSError, UnicodeDecodeError):
        return violations

    violations.extend(check_file_structure(lines, rel))
    violations.extend(check_imports(filepath, lines, rel))

    scopes: dict[str, ScopeTracker] = {}  # indent -> tracker
    in_block_comment = False
    func_skip_depth = 0  # brace depth for skipping function bodies only
    prev_blank: dict[str, bool] = {}  # indent -> was previous relevant line a blank?

    for i, line in enumerate(lines):
        lineno = i + 1
        stripped = line.strip()
        indent = get_indent(line)

        # Handle block comments
        if in_block_comment:
            if BLOCK_COMMENT_END.search(stripped):
                in_block_comment = False
            continue
        if BLOCK_COMMENT_START.search(stripped) and not BLOCK_COMMENT_END.search(stripped):
            in_block_comment = True
            continue

        # Track blank lines per indent
        if not stripped:
            # Check: blank line right after opening brace of a QML object
            if i > 0 and func_skip_depth == 0 and not in_block_comment and lines[i - 1].strip().endswith("{"):
                violations.append(
                    Violation(
                        rel,
                        lineno,
                        "blank-after-open-brace",
                        "no blank line expected after opening brace",
                    )
                )
            for key in prev_blank:
                prev_blank[key] = True
            continue

        # Skip line comments
        if COMMENT_LINE_RE.match(stripped):
            continue

        # Skip inside function bodies (JS code, not QML structure)
        if func_skip_depth > 0:
            func_skip_depth += stripped.count("{") - stripped.count("}")
            if func_skip_depth <= 0:
                func_skip_depth = 0
            continue

        # Closing brace: pop all scopes deeper than this indent
        # (the scope at this indent belongs to the parent object and must persist)
        if stripped == "}":
            # Check: blank line right before closing brace
            if i > 0 and not lines[i - 1].strip():
                violations.append(
                    Violation(
                        rel,
                        lineno,
                        "blank-before-close-brace",
                        "no blank line expected before closing brace",
                    )
                )
            to_remove = [k for k in scopes if len(k) > len(indent)]
            for k in to_remove:
                del scopes[k]
                prev_blank.pop(k, None)
            continue

        section = classify_line(stripped)
        if section is None:
            continue

        # Get or create scope tracker for this indent
        if indent not in scopes:
            scopes[indent] = ScopeTracker()
            prev_blank[indent] = True  # treat start of object as having separator

        tracker = scopes[indent]
        had_blank = prev_blank.get(indent, True)

        # --- Check 1: Section ordering ---
        if tracker.last_section is not None and section < tracker.last_section:
            violations.append(
                Violation(
                    rel,
                    lineno,
                    "section-order",
                    f"{SECTION_NAMES[section]} should appear before "
                    f"{SECTION_NAMES[tracker.last_section]} "
                    f"(seen at line {tracker.last_section_line})",
                )
            )

        # --- Check 2: Missing blank line between different sections ---
        if tracker.last_section is not None and section != tracker.last_section and not had_blank:
            violations.append(
                Violation(
                    rel,
                    lineno,
                    "missing-section-separator",
                    f"blank line expected between {SECTION_NAMES[tracker.last_section]} and {SECTION_NAMES[section]}",
                )
            )

        # Update tracker
        if tracker.last_section is None or section >= tracker.last_section:
            tracker.last_section = section
            tracker.last_section_line = lineno

        prev_blank[indent] = False

        # Skip function bodies (they contain JS, not QML structure)
        brace_count = stripped.count("{") - stripped.count("}")
        if brace_count > 0 and section == Section.FUNCTION:
            func_skip_depth = brace_count

        # Skip JS blocks in bindings (signal handlers, attached handlers,
        # and expression blocks like `color: { ... }`)
        if brace_count > 0 and section == Section.BINDING:
            colon_idx = stripped.index(":")
            after_colon = stripped[colon_idx + 1 :].strip()
            # If content after : doesn't start with an uppercase type name,
            # it's a JS block (not an inline QML object like `contentItem: Rect {`)
            if not re.match(r"^[A-Z]", after_colon):
                func_skip_depth = brace_count

        # Child object/component opening resets deeper scopes
        if brace_count > 0 and section in (Section.CHILD, Section.COMPONENT_DEF):
            to_remove = [k for k in scopes if len(k) > len(indent)]
            for k in to_remove:
                del scopes[k]
                prev_blank.pop(k, None)

    return violations


def main():
    fix_mode = "--fix" in sys.argv
    qml_files = sorted(p for p in REPO_ROOT.rglob("*.qml") if "build" not in p.parts)

    if fix_mode:
        fixed = sum(1 for f in qml_files if fix_file(f))
        print(f"{BOLD}Fixed {fixed} file(s).{RESET}\n")

    print(f"{BOLD}Checking {len(qml_files)} QML files for convention violations...{RESET}\n")

    all_violations: list[Violation] = []
    for f in qml_files:
        all_violations.extend(check_file(f))

    for v in all_violations:
        print(v)

    print()
    if all_violations:
        by_rule: dict[str, int] = {}
        for v in all_violations:
            by_rule[v.rule] = by_rule.get(v.rule, 0) + 1
        for rule, count in sorted(by_rule.items()):
            print(f"  {RULE_COLOURS.get(rule, '')}{rule}{RESET}: {count}")
        print(f"\n{BOLD}Found {len(all_violations)} violation(s).{RESET}")
        return 1
    else:
        print(f"{BOLD}No violations found.{RESET}")
        return 0


if __name__ == "__main__":
    sys.exit(main())
