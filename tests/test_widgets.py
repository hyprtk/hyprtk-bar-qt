"""Unit tests for the desktop-widget backends (weather, sysinfo). No network."""

from __future__ import annotations

import json
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

    def test_measured_heights_avoid_overlap(self) -> None:
        # Auto-height widgets (config height 0) must not stack on top of each
        # other: the measured heights supply the cell height.
        cfg = {
            "a": {"snap_group": "g", "snap_axis": "vertical", "snap_order": 1,
                   "width": 200, "height": 0, "margin_x": 10, "margin_y": 10, "position": "free"},
            "b": {"snap_group": "g", "snap_axis": "vertical", "snap_order": 2,
                   "width": 200, "height": 0, "position": "free"},
        }
        out = widgets_layout.layout(cfg, heights={"a": {"w": 200, "h": 150}, "b": {"w": 200, "h": 90}})
        self.assertEqual(out["a"]["h"], 150)
        self.assertEqual(out["b"]["y"], 10 + 150 + widgets_layout.SNAP_GAP)

    def test_per_member_scale_fills_cell(self) -> None:
        # The cell is the largest natural member; smaller members scale up
        # (clamped to SNAP_SCALE_MAX), larger members scale down — as GTK.
        cfg = {
            "small": {"snap_group": "g", "snap_axis": "horizontal", "snap_order": 1,
                       "width": 100, "height": 100, "margin_x": 0, "margin_y": 0, "position": "free"},
            "big": {"snap_group": "g", "snap_axis": "horizontal", "snap_order": 2,
                     "width": 300, "height": 200, "position": "free"},
        }
        out = widgets_layout.layout(cfg)
        self.assertEqual(out["small"]["w"], 300)
        self.assertEqual(out["small"]["h"], 200)
        # small: min(300/100, 200/100)=2.0 -> clamped 2.0 * 0.97
        self.assertAlmostEqual(out["small"]["scale"], 2.0 * widgets_layout.SNAP_FIT_MARGIN, places=3)
        # big: min(300/300, 200/200)=1.0 * 0.97
        self.assertAlmostEqual(out["big"]["scale"], 1.0 * widgets_layout.SNAP_FIT_MARGIN, places=3)

    def test_anchor_keeps_dropped_widget_in_place(self) -> None:
        # A widget joining an existing group to the right stays where dropped;
        # the earlier member reflows to its left.
        cfg = {
            "clock": {"snap_group": "g1", "snap_axis": "horizontal", "snap_order": 0,
                       "width": 100, "height": 100, "margin_x": 0, "margin_y": 0, "position": "free"},
            "disk": {"position": "free", "margin_x": 320, "margin_y": 4, "snap_anchor": True,
                      "snap_group": "g1", "snap_axis": "horizontal", "snap_order": 1,
                      "width": 100, "height": 100},
        }
        out = widgets_layout.layout(cfg)
        # disk (anchor, index 1) stays at 320; clock moves one cell left of it.
        self.assertEqual(out["disk"]["x"], 320)
        self.assertEqual(out["clock"]["x"], 320 - (100 + widgets_layout.SNAP_GAP))



class SnapDrop(unittest.TestCase):
    def test_snap_axis(self) -> None:
        a = {"x": 0, "y": 0, "w": 100, "h": 100}
        right = {"x": 108, "y": 5, "w": 100, "h": 100}   # 8px gap, vertical overlap
        far = {"x": 400, "y": 400, "w": 100, "h": 100}
        below = {"x": 5, "y": 108, "w": 100, "h": 100}
        self.assertEqual(widgets_layout.snap_axis(a, right)[1], "horizontal")
        self.assertEqual(widgets_layout.snap_axis(a, below)[1], "vertical")
        self.assertIsNone(widgets_layout.snap_axis(a, far)[1])

    def test_snap_joins_nearest_and_orders(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "config.json"
            path.write_text(json.dumps({"widgets": {
                "clock": {"position": "free", "margin_x": 0, "margin_y": 0},
                "disk": {"position": "free", "margin_x": 500, "margin_y": 500},
            }}))
            rects = {
                "clock": {"x": 0, "y": 0, "w": 100, "h": 100},
                "disk": {"x": 500, "y": 500, "w": 100, "h": 100},
            }
            # Drop disk just to the right of clock.
            res = widgets_layout.snap("disk", 110, 4, rects, path)
            self.assertTrue(res["snapped"])
            self.assertEqual(res["axis"], "horizontal")
            data = json.loads(path.read_text())["widgets"]
            self.assertEqual(data["clock"]["snap_group"], data["disk"]["snap_group"])
            self.assertNotEqual(data["clock"]["snap_group"], "")
            self.assertEqual(data["clock"]["snap_order"], 0)  # left-most anchors
            self.assertEqual(data["disk"]["snap_order"], 1)

    def test_snap_none_detaches(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "config.json"
            path.write_text(json.dumps({"widgets": {
                "clock": {"position": "free", "margin_x": 0, "margin_y": 0, "snap_group": "g1"},
            }}))
            rects = {"clock": {"x": 1000, "y": 700, "w": 100, "h": 100}}
            res = widgets_layout.snap("clock", 1000, 700, rects, path)
            self.assertFalse(res["snapped"])
            self.assertEqual(json.loads(path.read_text())["widgets"]["clock"]["snap_group"], "")


class SetPosition(unittest.TestCase):
    def test_writes_free_position_and_detaches(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "config.json"
            path.write_text('{"widgets": {"clock": {"position": "top-right", "snap_group": "g3"}}}')
            self.assertTrue(widgets_layout.set_position("clock", 500, 300, path))
            import json
            data = json.loads(path.read_text())
            self.assertEqual(data["widgets"]["clock"]["position"], "free")
            self.assertEqual(data["widgets"]["clock"]["margin_x"], 500)
            self.assertEqual(data["widgets"]["clock"]["margin_y"], 300)
            self.assertEqual(data["widgets"]["clock"]["snap_group"], "")  # detached

    def test_missing_config_fails(self) -> None:
        self.assertFalse(widgets_layout.set_position("clock", 1, 2, Path("/no/such/config.json")))


class SysInfo(unittest.TestCase):
    def test_gather_shape(self) -> None:
        with mock.patch.object(sysinfo.monitor_data, "gpu_static", return_value=None):
            info = sysinfo.gather()
        for key in ("host", "os", "kernel", "uptime", "cpu", "mem_total", "disk_count", "disk_total"):
            self.assertIn(key, info)


if __name__ == "__main__":
    unittest.main()
