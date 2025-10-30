#!/usr/bin/env python3
"""Utility to capture Codex-assisted editing session details."""

from __future__ import annotations

import argparse
import datetime as dt
import re
import subprocess
import sys
from pathlib import Path
from typing import List, Sequence


REPO_ROOT = Path(__file__).resolve().parents[1]


def run_git(args: Sequence[str]) -> str:
    """Run a git command in the repository and return stdout."""
    result = subprocess.run(
        ["git", *args],
        cwd=REPO_ROOT,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        raise RuntimeError(
            f"git {' '.join(args)} failed with: {result.stderr.strip()}"
        )
    return result.stdout.strip()


def safe_git(args: Sequence[str]) -> str:
    try:
        return run_git(args)
    except RuntimeError:
        return "(unavailable)"


def slugify(value: str) -> str:
    slug = re.sub(r"[^a-zA-Z0-9]+", "-", value.lower()).strip("-")
    return slug[:50]


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Log a Codex session to codex_sessions/",
    )
    parser.add_argument(
        "title",
        help="Short human-readable title for the session entry.",
    )
    parser.add_argument(
        "-n",
        "--note",
        dest="notes",
        action="append",
        default=[],
        help="Add a note line (can be repeated).",
    )
    parser.add_argument(
        "--tags",
        nargs="+",
        default=[],
        help="Optional tags to help with filtering (space separated).",
    )
    parser.add_argument(
        "--skip-diff",
        action="store_true",
        help="Skip capturing git diff output.",
    )
    parser.add_argument(
        "--skip-status",
        action="store_true",
        help="Skip capturing git status output.",
    )
    parser.add_argument(
        "--output-dir",
        default="codex_sessions",
        help="Directory (relative to repo root) for saved sessions.",
    )
    parser.add_argument(
        "--commit",
        help="Capture diff from a specific commit (uses git show).",
    )
    return parser


def format_block(header: str, content: str, fence: str = "") -> List[str]:
    if not content:
        return []
    lines: List[str] = [f"## {header}"]
    if fence:
        lines.append(f"```{fence}")
        lines.append(content.rstrip())
        lines.append("```")
    else:
        lines.append(content.strip())
    lines.append("")
    return lines


def main(argv: Sequence[str]) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    output_dir = (REPO_ROOT / args.output_dir).resolve()
    output_dir.mkdir(parents=True, exist_ok=True)

    now = dt.datetime.now(dt.timezone.utc).astimezone()
    timestamp_display = now.strftime("%Y-%m-%d %H:%M:%S %Z")
    timestamp_slug = now.strftime("%Y%m%d-%H%M%S")
    slug = slugify(args.title)
    filename = f"{timestamp_slug}-{slug}.md" if slug else f"{timestamp_slug}.md"
    file_path = output_dir / filename

    branch = safe_git(["rev-parse", "--abbrev-ref", "HEAD"])
    commit = safe_git(["rev-parse", "--short", "HEAD"])
    status = ""
    if not args.skip_status and not args.commit:
        status = safe_git(["status", "--short"])

    diff = ""
    if not args.skip_diff:
        if args.commit:
            diff = safe_git(["show", args.commit])
        else:
            diff = safe_git(["diff"])

    header_lines = [
        f"# {args.title}",
        "",
        f"- Timestamp: {timestamp_display}",
        f"- Branch: {branch}",
        f"- Commit: {commit}",
    ]
    if args.tags:
        header_lines.append(f"- Tags: {', '.join(args.tags)}")
    header_lines.append("")

    body_lines: List[str] = []
    note_text = "\n".join(args.notes).strip()
    if note_text:
        body_lines.extend(format_block("Notes", note_text))
    body_lines.extend(format_block("Git Status", status, fence="text"))
    body_lines.extend(format_block("Git Diff", diff, fence="diff"))

    with file_path.open("w", encoding="utf-8") as handle:
        handle.write("\n".join(header_lines + body_lines).rstrip() + "\n")

    relative_path = file_path.relative_to(REPO_ROOT)
    print(f"Saved Codex session log to {relative_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
