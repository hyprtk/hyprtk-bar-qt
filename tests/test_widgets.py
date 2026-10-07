"""Unit tests for the desktop-widget backends (weather, sysinfo). No network."""

from __future__ import annotations

import os
import sys
import tempfile
import time
import unittest
from pathlib import Path
from unittest import mock

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "backend"))

from hyprtk_bar_qt import sysinfo, visualizer, weather, widgets_layout  # noqa: E402


class WeatherDescribe(unittest.TestCase):
    def test_known_code(self) -> None:
        label, day, night = weather.describe(0)
        self.assertEqual(label, "Clear")
        self.assertNotEqual(day, night)

    def test_unknown_code(self) -> None:
        self.assertEqual(weather.describe(12345)[0], "Unknown")

    def test_bad_code(self) -> None:
        self.assertEqual(weather.describe("nope")[0], "Unknown")


class WeatherCache(unittest.TestCase):
    def test_roundtrip(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "weather.json"
            with mock.patch.object(weather, "CACHE_PATH", path):
                self.assertIsNone(weather.load_cache())
                weather.save_cache({"city": "London", "fetched": 1.0})
                self.assertEqual(weather.load_cache()["city"], "London")

    def test_fresh_cache_skips_fetch(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "weather.json"
            with mock.patch.object(weather, "CACHE_PATH", path), \
                 mock.patch.object(weather, "fetch_weather") as fetch:
                weather.save_cache({"city": "London", "fetched": time.time()})
                result = weather.get_weather("London", max_age=900)
                fetch.assert_not_called()
                self.assertEqual(result["city"], "London")

    def test_stale_cache_fetches(self) -> None:
        fresh = {"city": "Paris", "fetched": time.time()}
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "weather.json"
            with mock.patch.object(weather, "CACHE_PATH", path), \
                 mock.patch.object(weather, "fetch_weather", return_value=fresh) as fetch:
                weather.save_cache({"city": "Paris", "fetched": time.time() - 9999})
                result = weather.get_weather("Paris", max_age=900)
                fetch.assert_called_once()
                self.assertEqual(result["city"], "Paris")


class Visualizer(unittest.TestCase):
    def test_parse_frame(self) -> None:
        self.assertEqual(visualizer.parse_frame("0;50;100"), [0.0, 0.5, 1.0])

    def test_parse_frame_clamps_and_rejects(self) -> None:
        self.assertEqual(visualizer.parse_frame("150;-10"), [1.0, 0.0])
        self.assertEqual(visualizer.parse_frame("oops;12"), [])

    def test_synthetic_frame_shape(self) -> None:
        frame = visualizer.synthetic_frame(1.0, 16)
        self.assertEqual(len(frame), 16)
        self.assertTrue(all(0.0 <= v <= 1.0 for v in frame))

    def test_resolve_binary_rejects_missing(self) -> None:
        self.assertIsNone(visualizer.resolve_binary("definitely-not-a-real-binary-xyz"))


class SnapLayout(unittest.TestCase):
    def test_no_groups_is_empty(self) -> None:
        self.assertEqual(widgets_layout.layout({"clock": {"width": 220}}), {})

    def test_horizontal_group(self) -> None:
        cfg = {
            "clock": {"snap_group": "g", "snap_axis": "horizontal", "snap_order": 1,
                       "width": 220, "margin_x": 100, "margin_y": 50, "position": "free"},
            "disk": {"snap_group": "g", "snap_axis": "horizontal", "snap_order": 2,
                      "width": 300, "margin_x": 0, "margin_y": 0, "position": "free"},
        }
        out = widgets_layout.layout(cfg)
        self.assertEqual(out["clock"]["x"], 100)
        self.assertEqual(out["clock"]["y"], 50)
        # uniform cell = widest (300); second sits one cell + spacing right
        self.assertEqual(out["disk"]["x"], 100 + 300 + widgets_layout.SPACING)
        self.assertEqual(out["disk"]["w"], 300)

    def test_vertical_group(self) -> None:
        cfg = {
            "a": {"snap_group": "g", "snap_axis": "vertical", "snap_order": 1,
                   "width": 200, "height": 100, "margin_x": 10, "margin_y": 10, "position": "free"},
            "b": {"snap_group": "g", "snap_axis": "vertical", "snap_order": 2,
                   "width": 200, "height": 120, "position": "free"},
        }
        out = widgets_layout.layout(cfg)
        self.assertEqual(out["a"]["y"], 10)
        self.assertEqual(out["b"]["y"], 10 + 120 + widgets_layout.SPACING)


class SysInfo(unittest.TestCase):
    def test_gather_shape(self) -> None:
        with mock.patch.object(sysinfo.monitor_data, "gpu_static", return_value=None):
            info = sysinfo.gather()
        for key in ("host", "os", "kernel", "uptime", "cpu", "mem_total", "disk_count", "disk_total"):
            self.assertIn(key, info)


if __name__ == "__main__":
    unittest.main()
