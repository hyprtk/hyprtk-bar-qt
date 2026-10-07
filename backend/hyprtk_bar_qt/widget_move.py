"""Desktop-widget move control channel (a FIFO).

Hyprland binds ``Super + Shift + left mouse`` (press -> ``start``, release ->
``stop``) to ``hyprtk-bar-qt-widget-move``, which writes to this FIFO. The Qt bar
watches it (via this streamer) and drives the cursor-polling move itself — the
same model as the GTK bar, on its own FIFO so the two never clash.

Streams one JSON line per command: ``{"cmd": "start"|"stop"}``.
"""

from __future__ import annotations

import json
import os
import select
import stat
import sys
import time
from pathlib import Path

FIFO_NAME = "hyprtk-bar-qt-widget-move.fifo"


def fifo_path() -> Path:
    runtime = os.environ.get("XDG_RUNTIME_DIR") or f"/run/user/{os.getuid()}"
    return Path(runtime) / FIFO_NAME


def ensure_fifo(path: Path) -> bool:
    try:
        os.mkfifo(path, 0o600)
        return True
    except FileExistsError:
        pass
    except OSError:
        return False
    try:
        info = os.lstat(path)
    except OSError:
        return False
    if not stat.S_ISFIFO(info.st_mode) or info.st_uid != os.getuid() or info.st_mode & 0o077:
        try:
            os.unlink(path)
            os.mkfifo(path, 0o600)
        except OSError:
            return False
    return True


def main(argv: list[str] | None = None) -> int:
    path = fifo_path()
    if not ensure_fifo(path):
        return 1
    try:
        fd = os.open(path, os.O_RDONLY | os.O_NONBLOCK | os.O_NOFOLLOW)
    except OSError:
        return 1
    try:
        while True:
            try:
                ready, _, _ = select.select([fd], [], [], 1.0)
            except InterruptedError:
                continue
            if not ready:
                continue
            data = os.read(fd, 256)
            if not data:
                # All writers closed; reopen the read end without a busy loop.
                os.close(fd)
                time.sleep(0.05)
                try:
                    fd = os.open(path, os.O_RDONLY | os.O_NONBLOCK | os.O_NOFOLLOW)
                except OSError:
                    return 1
                continue
            for line in data.decode("utf-8", "replace").splitlines():
                cmd = line.strip()
                if cmd in ("start", "stop", "toggle"):
                    print(json.dumps({"cmd": cmd}), flush=True)
    except KeyboardInterrupt:
        return 0
    finally:
        try:
            os.close(fd)
        except OSError:
            pass
        try:
            os.unlink(path)
        except OSError:
            pass
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
