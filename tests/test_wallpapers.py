"""Unit tests for the toolkit-free wallpaper scanner (no Qt, no wallpapers)."""

from __future__ import annotations

import os
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "backend"))

from hyprtk_bar_qt import wallpapers  # noqa: E402


class Scan(unittest.TestCase):
    def test_filters_images_and_sorts(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            for name in ("b.png", "a.jpg", "notes.txt", "c.webp"):
                (base / name).write_bytes(b"x")
            (base / "sub").mkdir()
            (base / "sub" / "nested.png").write_bytes(b"x")
            result = wallpapers.scan(tmp)
            names = [Path(p).name for p in result]
            self.assertEqual(names, ["a.jpg", "b.png", "c.webp"])

    def test_missing_dir_is_empty(self) -> None:
        self.assertEqual(wallpapers.scan("/no/such/dir/here"), [])

    def test_apply_missing_file_fails(self) -> None:
        self.assertFalse(wallpapers.apply("/no/such/image.png"))


if __name__ == "__main__":
    unittest.main()
