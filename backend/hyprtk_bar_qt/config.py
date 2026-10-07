"""Reading the hyprtk-bar JSON config + pywal palette (toolkit-free)."""

from __future__ import annotations

import json
import os
from pathlib import Path

PYWAL_PATH = Path.home() / ".cache" / "wal" / "colors.json"


def config_path() -> str:
    return os.path.join(os.path.expanduser("~"), ".config", "hyprtk-bar", "config.json")


def load_config() -> dict:
    """Return the bar config, or an empty dict if it is absent/invalid."""
    try:
        with open(config_path()) as f:
            data = json.load(f)
        return data if isinstance(data, dict) else {}
    except (OSError, ValueError):
        return {}


def get(key: str, default=None):
    return load_config().get(key, default)


def load_pywal_colors() -> dict | None:
    """Read ~/.cache/wal/colors.json; returns color map or None if unavailable."""
    try:
        data = json.loads(PYWAL_PATH.read_text())
    except (OSError, json.JSONDecodeError):
        return None
    out = dict(data.get("colors") or {})
    special = data.get("special") or {}
    out["background"] = special.get("background")
    out["foreground"] = special.get("foreground")
    return out or None
