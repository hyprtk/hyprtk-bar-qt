"""Lock-screen settings reader/writer for the Qt themer.

Supports both the live swaylock config (``~/.config/swaylock/config``) and the
migrated hyprlock colours (``~/.cache/wal/hyprlock-colors.conf``): lists the
config's ``key=value`` settings (marking colour-looking values) and writes an
edited value back to the same file.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from pathlib import Path

HOME = Path.home()
SWAYLOCK = HOME / ".config" / "swaylock" / "config"
HYPRLOCK_CONF = HOME / ".config" / "hypr" / "hyprlock.conf"
HYPRLOCK_COLORS = HOME / ".cache" / "wal" / "hyprlock-colors.conf"

_HEX8 = re.compile(r"^#?[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$")


def detect() -> tuple[str, Path | None]:
    if HYPRLOCK_CONF.is_file():
        return "hyprlock", HYPRLOCK_COLORS if HYPRLOCK_COLORS.is_file() else None
    if SWAYLOCK.is_file():
        return "swaylock", SWAYLOCK
    return "", None


def _looks_color(value: str) -> bool:
    return bool(_HEX8.match(value.strip()))


def read() -> dict:
    kind, path = detect()
    items: list[dict] = []
    if path is not None:
        try:
            for line in path.read_text().splitlines():
                s = line.strip()
                if not s or s.startswith("#") or "=" not in s:
                    continue
                key, _, val = s.partition("=")
                key = key.strip()
                val = val.strip()
                # hyprlock colour vars are prefixed $lock_.
                label = key.replace("$lock_", "") if key.startswith("$lock_") else key
                items.append({"key": key, "label": label, "value": val, "color": _looks_color(val)})
        except OSError:
            pass
    return {"kind": kind, "path": str(path) if path else "", "items": items}


def set_value(key: str, value: str) -> bool:
    kind, path = detect()
    if path is None or not path.is_file():
        return False
    try:
        lines = path.read_text().splitlines()
    except OSError:
        return False
    out = []
    found = False
    for line in lines:
        stripped = line.strip()
        if "=" in stripped and not stripped.startswith("#"):
            k = stripped.partition("=")[0].strip()
            if k == key:
                out.append(f"{key}={value}")
                found = True
                continue
        out.append(line)
    if not found:
        out.append(f"{key}={value}")
    try:
        tmp = path.with_suffix(path.suffix + ".tmp")
        tmp.write_text("\n".join(out) + "\n")
        os.replace(tmp, path)
        return True
    except OSError:
        return False


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="lock-screen settings")
    sub = ap.add_subparsers(dest="action", required=True)
    sub.add_parser("read")
    p_set = sub.add_parser("set")
    p_set.add_argument("--key", required=True)
    p_set.add_argument("--value", required=True)
    args = ap.parse_args(argv)

    if args.action == "read":
        print(json.dumps(read()))
        return 0
    ok = set_value(args.key, args.value)
    print(json.dumps({"ok": ok}))
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
