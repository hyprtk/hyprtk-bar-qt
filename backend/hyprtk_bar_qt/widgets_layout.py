"""Snap-group layout for the desktop widgets.

Widgets that share a non-empty ``snap_group`` are laid out together along
``snap_axis`` (horizontal / vertical), ordered by ``snap_order``, using one
uniform cell (the widest member). Toolkit-free and testable.

Usage::

    python3 widgets_layout.py layout --json '<widgets config block>'
"""

from __future__ import annotations

import argparse
import json

SPACING = 8


def layout(widgets: dict) -> dict:
    """``{id: {x, y, w, h}}`` for every widget that is in a snap group."""
    groups: dict[str, list] = {}
    for wid, block in (widgets or {}).items():
        if not isinstance(block, dict):
            continue
        group = str(block.get("snap_group") or "").strip()
        if not group:
            continue
        groups.setdefault(group, []).append((block.get("snap_order", 0), wid, block))

    out: dict = {}
    for members in groups.values():
        members.sort(key=lambda m: (m[0], m[1]))
        axis = str(members[0][2].get("snap_axis") or "horizontal")
        cell_w = max(int(m[2].get("width") or 280) for m in members)
        heights = [int(m[2].get("height") or 0) for m in members]
        cell_h = max(heights) if heights and all(h > 0 for h in heights) else 0

        first = members[0][2]
        x0 = int(first.get("margin_x") or 40)
        y0 = int(first.get("margin_y") or 40)
        if str(first.get("position") or "free") != "free":
            x0, y0 = 40, 40

        for i, (_order, wid, _block) in enumerate(members):
            if axis == "vertical":
                x, y = x0, y0 + i * ((cell_h or 0) + SPACING)
            else:
                x, y = x0 + i * (cell_w + SPACING), y0
            out[wid] = {"x": x, "y": y, "w": cell_w, "h": cell_h}
    return out


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="desktop-widget snap-group layout")
    sub = ap.add_subparsers(dest="action", required=True)
    lp = sub.add_parser("layout")
    lp.add_argument("--json", required=True)
    args = ap.parse_args(argv)

    try:
        widgets = json.loads(args.json)
    except ValueError:
        print(json.dumps({"layout": {}}))
        return 1
    print(json.dumps({"layout": layout(widgets)}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
