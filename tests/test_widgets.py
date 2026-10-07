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

from hyprtk_bar_qt import sysinfo, weather  # noqa: E402


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


class SysInfo(unittest.TestCase):
    def test_gather_shape(self) -> None:
        with mock.patch.object(sysinfo.monitor_data, "gpu_static", return_value=None):
            info = sysinfo.gather()
        for key in ("host", "os", "kernel", "uptime", "cpu", "mem_total", "disk_count", "disk_total"):
            self.assertIn(key, info)


if __name__ == "__main__":
    unittest.main()
