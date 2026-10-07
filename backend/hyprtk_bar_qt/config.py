"""Reading the hyprtk-bar JSON config (toolkit-free)."""

from __future__ import annotations

import json
import os


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
