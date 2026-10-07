"""Directory listing for the start menu's Plasma file browser.

Toolkit-free: returns a directory's entries (name, path, is_dir, size) with
directories first, hidden files skipped, sorted case-insensitively.

Usage::

    python3 files.py list <path>
"""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path


def list_dir(path: str) -> dict:
    """Entries of *path* (dirs first, hidden skipped), or an empty list."""
    base = Path(os.path.expanduser(path or "~"))
    entries = []
    try:
        for entry in base.iterdir():
            if entry.name.startswith("."):
                continue
            try:
                is_dir = entry.is_dir()
                size = 0 if is_dir else entry.stat().st_size
            except OSError:
                continue
            entries.append({
                "name": entry.name,
                "path": str(entry),
                "is_dir": is_dir,
                "size": size,
            })
    except OSError:
        pass
    entries.sort(key=lambda e: (not e["is_dir"], e["name"].lower()))
    try:
        parent = str(base.resolve().parent)
    except OSError:
        parent = str(base)
    return {"path": str(base), "parent": parent, "entries": entries}


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="directory listing for the menu browser")
    sub = ap.add_subparsers(dest="action", required=True)
    lst = sub.add_parser("list")
    lst.add_argument("path", nargs="?", default="~")
    args = ap.parse_args(argv)

    print(json.dumps(list_dir(args.path)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
