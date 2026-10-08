"""Wallpaper folder scanning + apply for the Qt themer.

The Wallpaper page lists images from a directory (thumbnails in QML) and applies
one by running the hyprtk ``wallpaper-colors.sh`` script (which sets the
wallpaper and regenerates pywal). Toolkit-free and testable.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
from pathlib import Path

IMAGE_EXTS = {".png", ".jpg", ".jpeg", ".webp", ".gif", ".bmp", ".jxl", ".avif"}
CURRENT = Path.home() / ".cache" / "current-wallpaper.png"


def scan(directory: str) -> list[str]:
    """Absolute paths of image files directly in ``directory`` (sorted)."""
    try:
        entries = Path(directory).expanduser().iterdir()
    except OSError:
        return []
    return sorted(
        str(p.resolve())
        for p in entries
        if p.is_file() and p.suffix.lower() in IMAGE_EXTS
    )


def current() -> str | None:
    return str(CURRENT) if CURRENT.is_file() else None


def _wallpaper_script() -> Path | None:
    home = Path.home()
    for candidate in (
        home / ".local" / "share" / "hyprtk-bar" / "scripts" / "wallpaper-colors.sh",
        home / "hyprtk" / "configs" / "hypr" / "scripts" / "wallpaper-colors.sh",
    ):
        if candidate.is_file():
            return candidate
    return None


def apply(image: str) -> bool:
    """Set ``image`` as the wallpaper and regenerate pywal."""
    if not image or not os.path.isfile(image):
        return False
    script = _wallpaper_script()
    if script is None:
        return False
    try:
        subprocess.Popen(["bash", str(script), image], start_new_session=True)
        return True
    except (OSError, subprocess.SubprocessError):
        return False


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="wallpaper scanning + apply")
    sub = ap.add_subparsers(dest="action", required=True)
    scan_p = sub.add_parser("scan")
    scan_p.add_argument("directory", nargs="?", default=str(Path.home() / "Pictures" / "Wallpapers"))
    sub.add_parser("current")
    apply_p = sub.add_parser("apply")
    apply_p.add_argument("image")
    args = ap.parse_args(argv)

    if args.action == "scan":
        print(json.dumps({"images": scan(args.directory)}))
        return 0
    if args.action == "current":
        print(json.dumps({"current": current()}))
        return 0
    ok = apply(args.image)
    print(json.dumps({"ok": bool(ok)}))
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
