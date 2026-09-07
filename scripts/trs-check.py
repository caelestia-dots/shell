#!/usr/bin/env python3
"""Checks the source for translation bugs xgettext cannot catch.

Errors, which break the string for translators:
  - the wrong arity for the helper, such as a context passed to tr()
  - source, plural or context args xgettext cannot extract, such as variables,
    concatenations and template substitutions
  - an empty source string, which is reserved for the catalog header
  - placeholders which do not start at %1 or skip a number
  - an .arg() given several args, of which only the first is substituted
  - mark() args passed as a string instead of a list
  - qsTr() and the other Qt helpers, which are not extracted
  - QML using Tr without importing Caelestia.I18n

Warnings, which are merely suspicious:
  - an empty context, which is the same as having none
  - a %n count in a helper with no plural forms
  - placeholders which do not match the chained .arg() calls, or a marked
    string with placeholders and no args
  - trMarked() on a literal, which never translates
  - TRANSLATORS comments xgettext will drop

By default every *.qml, *.cpp and *.hpp under the repo root is checked. Pass
--file to check a single file, --file - to check an unsaved buffer piped in on
stdin, and --json to get machine-readable output, whose ranges are meant for a
language server. The report always goes to
stderr, and colour is dropped when stderr is not a terminal. The exit code is 1
when there is an error, or with --strict when there is anything at all.
"""

import argparse
import json
import re
import sys
from bisect import bisect_right
from pathlib import Path

RED = "\033[0;31m"
YELLOW = "\033[0;33m"
BOLD = "\033[1m"
RESET = "\033[0m"

REPO_ROOT = Path(__file__).resolve().parent.parent

# The helpers implementing the marking themselves, whose own signatures look like calls
SKIPPED = ("plugin/src/Caelestia/I18n", "plugin/include/util/i18n.hpp")

ERROR = "error"
WARNING = "warning"

LEVEL_COLOURS = {ERROR: RED, WARNING: YELLOW}

# Min/max args accepted by each helper
ARITY = {
    "tr": (1, 1),
    "trCtx": (2, 2),
    "trN": (3, 3),
    "trCtxN": (4, 4),
    "trMarked": (1, 1),
    "mark": (1, 2),
    "markCtx": (2, 3),
    "markN": (3, 4),
    "markCtxN": (4, 5),
}

# Arg position of each role. A helper with a plural also takes a count
SPEC: dict[str, dict[str, int]] = {
    "tr": {"text": 0},
    "trCtx": {"text": 0, "ctx": 1},
    "trN": {"text": 0, "plural": 1},
    "trCtxN": {"text": 0, "plural": 1, "ctx": 3},
    "trMarked": {"text": 0},
    "mark": {"text": 0, "args": 1},
    "markCtx": {"text": 0, "ctx": 1, "args": 2},
    "markN": {"text": 0, "plural": 1, "args": 3},
    "markCtxN": {"text": 0, "plural": 1, "ctx": 3, "args": 4},
}

CALL_RE = re.compile(r"((?:\w+[.:]{1,2})*)(" + "|".join(ARITY) + r")\s*\(")
FOREIGN_RE = re.compile(r"(?<![\w.])(qsTr|qsTranslate|qsTrId|QT_TR_NOOP|QT_TRANSLATE_NOOP)\s*\(")
USES_TR_RE = re.compile(r"(?<![\w.])Tr\.\w")
IMPORT_RE = re.compile(r"^\s*import\s+Caelestia\.I18n\b", re.M)
TRANSLATORS_RE = re.compile(r"^([^\n]*?)(?://|/\*)\s*TRANSLATORS:[^\n]*\n(\s*\n)?", re.M)
ARG_CALL_RE = re.compile(r"\s*(\.arg\s*\()")
PLACEHOLDER_RE = re.compile(r"%L?(\d{1,2})")
ESCAPE_RE = re.compile(r"\\(.)")

WRAPPER_RE = re.compile(
    r"^(?:QStringLiteral|QString::fromUtf8|QLatin1StringView|QLatin1String)\s*\(\s*(.*?)\s*\)$", re.S
)
CPP_PIECE_RE = re.compile(r'(?:u8?|U|L)?"((?:\\.|[^"\\])*)"(?:_s|_ba|_L1|_qs)?\s*')
JS_PIECES_RE = [
    re.compile(r'"((?:\\.|[^"\\])*)"\s*'),
    re.compile(r"'((?:\\.|[^'\\])*)'\s*"),
    re.compile(r"`((?:\\.|[^\\`])*)`\s*"),
]

QUOTES = "\"'`"


def disable_colour() -> None:
    """Blank every escape code so the report is plain text.

    Called when stderr isn't a terminal (a pipe or a redirect to a file) and
    for --json, whose consumers want the strings unadorned.
    """
    global RED, YELLOW, BOLD, RESET, LEVEL_COLOURS
    RED = YELLOW = BOLD = RESET = ""
    LEVEL_COLOURS = dict.fromkeys(LEVEL_COLOURS, "")


class Issue:
    """One reported issue, spanning the source from `start` to `end`.

    Both positions are 1 based line/column pairs. The end is exclusive, sitting
    just past the last character, which is what an LSP range wants.
    """

    def __init__(self, file: str, start: tuple[int, int], end: tuple[int, int], level: str, rule: str, msg: str):
        self.file = file
        self.line, self.col = start
        self.end_line, self.end_col = end
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
            "endLine": self.end_line,
            "endColumn": self.end_col,
            "level": self.level,
            "rule": self.rule,
            "message": self.msg,
        }


def mask(src: str) -> str:
    """Blank out comments, keeping strings and offsets intact."""
    out: list[str] = []
    i = 0
    n = len(src)

    while i < n:
        c = src[i]
        two = src[i : i + 2]

        if two == "//":
            while i < n and src[i] != "\n":
                out.append(" ")
                i += 1
            continue

        if two == "/*":
            out.append("  ")
            i += 2
            while i < n and src[i : i + 2] != "*/":
                out.append("\n" if src[i] == "\n" else " ")
                i += 1
            out.append("  ")
            i += 2
            continue

        if c in QUOTES:
            out.append(c)
            i += 1
            while i < n:
                ch = src[i]
                out.append(ch)
                i += 1
                if ch == c:
                    break
                if ch == "\\" and i < n:
                    out.append(src[i])
                    i += 1
            continue

        out.append(c)
        i += 1

    return "".join(out)


def skip_string(src: str, i: int) -> int:
    """Return the offset just past the string literal starting at `i`."""
    quote = src[i]
    n = len(src)
    i += 1

    while i < n:
        ch = src[i]
        i += 1
        if ch == quote:
            break
        if ch == "\\":
            i += 1

    return i


class Arg:
    """One argument of a call, with the span of its text in the source.

    The span excludes the whitespace around the argument, so it can be pointed
    at on its own.
    """

    def __init__(self, text: str, start: int, end: int):
        self.text = text
        self.start = start + len(text) - len(text.lstrip())
        self.end = end - (len(text) - len(text.rstrip()))

    @property
    def span(self) -> tuple[int, int]:
        return self.start, self.end


def split_args(src: str, i: int) -> tuple[list[Arg] | None, int]:
    """Split a call's arg list, starting just after the opening paren.

    Returns the args and the offset just past the closing paren, or None when
    the call is never closed.
    """
    args: list[Arg] = []
    start = i
    depth = 0
    n = len(src)

    while i < n:
        c = src[i]

        if c in QUOTES:
            i = skip_string(src, i)
            continue

        if c == ")" and depth == 0:
            text = src[start:i]
            if args or text.strip():
                args.append(Arg(text, start, i))
            return args, i + 1

        if c in "([{":
            depth += 1
        elif c in ")]}":
            depth -= 1
        elif c == "," and depth == 0:
            args.append(Arg(src[start:i], start, i))
            i += 1
            start = i
            continue

        i += 1

    return None, n


def unescape(text: str) -> str:
    return ESCAPE_RE.sub(lambda m: {"n": "\n", "t": "\t"}.get(m.group(1), m.group(1)), text)


def literal(arg: str, cpp: bool) -> str | None:
    """Return the content of a literal arg, or None when it isn't one.

    Adjacent and `+` concatenated literals count, since xgettext folds them.
    A template literal with a substitution does not, since its value is only
    known at runtime.
    """
    src = arg.strip()
    if not src:
        return None

    wrapper = WRAPPER_RE.match(src)
    if wrapper:
        src = wrapper.group(1)

    out = []
    while src:
        if out:
            src = src.removeprefix("+").lstrip()

        if cpp:
            m = CPP_PIECE_RE.match(src)
            if not m:
                return None
            out.append(unescape(m.group(1)))
            src = src[m.end() :]
            continue

        for piece in JS_PIECES_RE:
            m = piece.match(src)
            if m:
                break
        else:
            return None

        if src[0] == "`" and "${" in m.group(1):
            return None

        out.append(unescape(m.group(1)))
        src = src[m.end() :]

    return "".join(out)


def placeholders(text: str) -> list[int]:
    """Return the sorted distinct `%1` style placeholders of a string."""
    return sorted({int(n) for n in PLACEHOLDER_RE.findall(text.replace("%%", ""))})


def arg_chain(src: str, i: int) -> tuple[int, tuple[int, int] | None, int]:
    """Count the `.arg()` calls chained onto a call ending at `i`.

    Also returns the span of the first one passing several args, which only
    ever substitutes the first, and the offset the chain ends at.
    """
    count = 0
    multi = None

    while True:
        m = ARG_CALL_RE.match(src, i)
        if not m:
            return count, multi, i

        args, end = split_args(src, m.end())
        if args is None:
            return count, multi, i

        count += 1
        if multi is None and len(args) > 1:
            multi = (m.start(1), end)
        i = end


class FileChecker:
    """Checks the translation helper calls of a single file."""

    def __init__(self, rel: str, src: str):
        self.rel = rel
        self.src = src
        self.cpp = rel.endswith((".cpp", ".hpp"))
        self.masked = mask(src)
        self.starts = [0] + [i + 1 for i, c in enumerate(src) if c == "\n"]
        self.issues: list[Issue] = []

    def pos_at(self, offset: int) -> tuple[int, int]:
        """Return the 1 based line and column of an offset."""
        line = bisect_right(self.starts, offset)
        return line, offset - self.starts[line - 1] + 1

    def report(self, span: tuple[int, int], level: str, rule: str, msg: str) -> None:
        start, end = span
        self.issues.append(Issue(self.rel, self.pos_at(start), self.pos_at(max(end, start)), level, rule, msg))

    def check(self) -> list[Issue]:
        if not self.cpp:
            self.check_qml_imports()

        for m in CALL_RE.finditer(self.masked):
            self.check_call(m)

        self.check_translator_comments()

        self.issues.sort(key=lambda i: (i.line, i.col))
        return self.issues

    def check_qml_imports(self) -> None:
        # Anchored to the first use, since that is what the missing import breaks
        use = USES_TR_RE.search(self.masked)
        if use and not IMPORT_RE.search(self.src):
            self.report(
                (use.start(), use.end()), ERROR, "missing-import", "uses Tr but is missing `import Caelestia.I18n`"
            )

        for m in FOREIGN_RE.finditer(self.masked):
            self.report(
                (m.start(1), m.end(1)),
                ERROR,
                "foreign-helper",
                f"`{m.group(1)}()` is not extracted, use the Tr helpers instead",
            )

    def check_call(self, m: re.Match[str]) -> None:
        prefix, name = m.group(1), m.group(2)
        start = m.start()

        prev = self.masked[start - 1] if start else ""
        if prev and (prev.isalnum() or prev in "._:"):
            return

        if self.cpp:
            # Only the mark helpers exist in C++, a plain tr() is QObject::tr
            if name.startswith("tr") or not (prefix == "" or prefix.endswith("i18n::")):
                return
        elif prefix != "Tr.":
            return

        args, end = split_args(self.masked, m.end())
        if args is None:
            self.report((start, m.end()), ERROR, "unterminated", f"unterminated argument list for `{name}()`")
            return

        span = (start, end)
        if not self.check_arity(span, name, args):
            return

        spec = SPEC[name]
        text_arg = args[spec["text"]]
        text = literal(text_arg.text, self.cpp)

        if name == "trMarked":
            if text is not None:
                self.report(
                    span, WARNING, "redundant-marked", "`trMarked()` on a literal never translates, use `tr()`"
                )
            return

        plural_arg = args[spec["plural"]] if "plural" in spec else None
        plural = literal(plural_arg.text, self.cpp) if plural_arg else None

        self.check_sources(name, text_arg, text, plural_arg, plural)
        self.check_context(name, args, spec)

        for what, arg, value in (("source string", text_arg, text), ("plural string", plural_arg, plural)):
            if value is not None:
                self.check_forms(arg.span, name, what, value, "plural" in spec)

        self.check_args(span, name, args, spec, text)

    def check_arity(self, span: tuple[int, int], name: str, args: list[Arg]) -> bool:
        low, high = ARITY[name]
        count = len(args)
        if low <= count <= high:
            return True

        want = f"{low} arg" + ("" if low == 1 else "s") if low == high else f"{low}-{high} args"
        hint = ""
        if name == "tr" and count == 2:
            hint = " (use `trCtx()` to add context)"
        elif name == "trN" and count == 4:
            hint = " (use `trCtxN()` to add context)"

        self.report(span, ERROR, "arity", f"`{name}()` takes {want}, got {count}{hint}")
        return False

    def check_sources(
        self, name: str, text_arg: Arg, text: str | None, plural_arg: Arg | None, plural: str | None
    ) -> None:
        if text is None:
            hint = "" if self.cpp else " (mark the string at its source instead)"
            self.report(
                text_arg.span, ERROR, "non-literal", f"`{name}()` needs a literal source string to be extractable{hint}"
            )
        elif text == "":
            self.report(text_arg.span, ERROR, "empty-source", f"`{name}()` has an empty source string")

        if plural_arg is not None and plural is None:
            self.report(
                plural_arg.span, ERROR, "non-literal", f"`{name}()` needs a literal plural string to be extractable"
            )

    def check_context(self, name: str, args: list[Arg], spec: dict[str, int]) -> None:
        if "ctx" not in spec:
            return

        arg = args[spec["ctx"]]
        ctx = literal(arg.text, self.cpp)
        if ctx is None:
            self.report(arg.span, ERROR, "non-literal", f"`{name}()` needs a literal context to be extractable")
        elif ctx == "":
            plain = name.replace("Ctx", "")
            self.report(arg.span, WARNING, "empty-context", f"`{name}()` has an empty context, use `{plain}()`")

    def check_forms(self, span: tuple[int, int], name: str, what: str, value: str, has_plural: bool) -> None:
        if not has_plural and re.search(r"%L?n", value):
            self.report(span, WARNING, "plural-count", f"{what} of `{name}()` has a `%n` count but no plural forms")

        found = placeholders(value)
        if found and found != list(range(1, len(found) + 1)):
            listed = ", ".join(f"%{n}" for n in found)
            self.report(
                span,
                ERROR,
                "placeholders",
                f"{what} of `{name}()` has non-contiguous placeholders ({listed}), number them from %1",
            )

    def check_args(
        self, span: tuple[int, int], name: str, args: list[Arg], spec: dict[str, int], text: str | None
    ) -> None:
        found = placeholders(text) if text else []
        expected = found[-1] if found else 0

        if name.startswith("mark"):
            index = spec.get("args")
            arg = args[index] if index is not None and index < len(args) else None
            given = arg is not None and arg.text.strip()
            if given and literal(arg.text, self.cpp) is not None:
                self.report(arg.span, ERROR, "mark-args", f"the args of `{name}()` must be a list of strings")
            elif expected and not given:
                self.report(
                    span, WARNING, "arg-count", f"`{name}()` has placeholders but no args, they will not be filled in"
                )
            return

        count, multi, chain_end = arg_chain(self.masked, span[1])
        if count != expected and (count > 0 or expected == 0):
            self.report(
                (span[0], chain_end),
                WARNING,
                "arg-count",
                f"`{name}()` has {expected} placeholder(s) but {count} `.arg()` call(s)",
            )
        if multi:
            self.report(
                multi,
                ERROR,
                "arg-multi",
                "only the first argument of `.arg()` is substituted, chain a call per placeholder",
            )

    def check_translator_comments(self) -> None:
        """xgettext only picks up comments sitting on their own directly above the call."""
        for m in TRANSLATORS_RE.finditer(self.src):
            start = m.start() + len(m.group(1))
            eol = self.src.find("\n", start)
            span = (start, eol if eol != -1 else len(self.src))

            if m.group(1).strip():
                self.report(
                    span,
                    WARNING,
                    "translators-comment",
                    "trailing TRANSLATORS comment, xgettext only reads comments on their own line above the call",
                )
            elif m.group(2) is not None:
                self.report(
                    span,
                    WARNING,
                    "translators-comment",
                    "TRANSLATORS comment is not directly above a call, xgettext will drop it",
                )


def rel_path(filepath: Path) -> str:
    """Reporting path: relative to the repo root when the file lives inside it."""
    try:
        return str(filepath.resolve().relative_to(REPO_ROOT))
    except ValueError:
        return str(filepath)


def check_file(filepath: Path) -> list[Issue]:
    """Check a file on disk. An unreadable file yields no issues."""
    try:
        src = filepath.read_text()
    except (OSError, UnicodeDecodeError):
        return []

    return FileChecker(rel_path(filepath), src).check()


def source_files() -> list[Path]:
    files = (p for ext in ("*.qml", "*.cpp", "*.hpp") for p in REPO_ROOT.rglob(ext))
    return sorted(p for p in files if "build" not in p.parts)


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument(
        "--file",
        metavar="PATH",
        help="check only this file instead of every *.qml, *.cpp and *.hpp under the repo root; "
        "pass - to read the source from stdin (for unsaved editor buffers)",
    )
    parser.add_argument(
        "--stdin-name",
        metavar="PATH",
        help="the path the source piped in on stdin belongs to, used to label the issues "
        "and to tell QML from C++; buffers without one are checked as QML",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="report as JSON on stderr: every issue carries a 1 based start and "
        "end position; the end is exclusive, as an LSP range is",
    )
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

    print(f"{BOLD}Checking {checked} source file(s) for translation issues...{RESET}\n", file=err)

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

    # Buffer mode: the source never touches disk, so it is named by --stdin-name
    if args.file == "-":
        name = rel_path(Path(args.stdin_name)) if args.stdin_name else "<stdin>"
        issues = [] if name.startswith(SKIPPED) else FileChecker(name, sys.stdin.read()).check()
        return report(issues, args, 1)

    if args.file:
        path = Path(args.file)
        if not path.is_file():
            print(f"{RED}no such file: {path}{RESET}", file=sys.stderr)
            return 2
        files = [path]
    else:
        files = source_files()

    files = [f for f in files if not rel_path(f).startswith(SKIPPED)]
    return report([i for f in files for i in check_file(f)], args, len(files))


if __name__ == "__main__":
    sys.exit(main())
