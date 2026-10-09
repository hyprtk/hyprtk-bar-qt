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
import os
import tempfile
from pathlib import Path

try:
    from .paths import QT_CONFIG
except ImportError:  # run as a script (python3 widgets_layout.py)
    from paths import QT_CONFIG

# Gap between members of a snap group (matches the GTK bar's SNAP_GAP).
SNAP_GAP = 10
# A dropped widget joins a neighbour when their edges are within this many px.
SNAP_DIST = 28
# Each member's content is scaled to fill the uniform cell; clamp the factor and
# leave a small margin (matches the GTK bar's SNAP_SCALE_*/SNAP_FIT_MARGIN).
SNAP_SCALE_MIN = 0.4
SNAP_SCALE_MAX = 2.0
SNAP_FIT_MARGIN = 0.97

# Backwards-compatible alias (older tests referenced SPACING).
SPACING = SNAP_GAP

BAR_CONFIG = QT_CONFIG


def layout(widgets: dict, heights: dict | None = None, bounds: dict | None = None) -> dict:
    """``{id: {x, y, w, h}}`` for every widget that is in a snap group.

    *heights* maps ``id -> {w, h}`` measured sizes (needed because auto-height
    widgets store ``height: 0`` in the config); *bounds* is the usable area
    ``{w, h}`` the group must fit inside (the cell shrinks to fit, then the
    group is clamped on-screen).
    """
    heights = heights or {}
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
        nat = []
        for _order, wid, block in members:
            measured = heights.get(wid) or {}
            cw = max(int(block.get("width") or 0), int(measured.get("w") or 0)) or 200
            ch = max(int(block.get("height") or 0), int(measured.get("h") or 0)) or 120
            nat.append((cw, ch))
        cell_w = max(n[0] for n in nat)
        cell_h = max(n[1] for n in nat)
        count = len(members)

        if bounds and bounds.get("w") and bounds.get("h"):
            bw, bh = int(bounds["w"]), int(bounds["h"])
            total_w = count * cell_w + (count - 1) * SNAP_GAP
            total_h = count * cell_h + (count - 1) * SNAP_GAP
            fit = min(1.0, bw / total_w if total_w else 1.0, bh / total_h if total_h else 1.0)
            cell_w = max(40, int(cell_w * fit))
            cell_h = max(30, int(cell_h * fit))

        # Anchor the group on the widget that was just dropped (its persisted
        # margin is where the user put it) so it stays put; otherwise the first
        # member. This mirrors the GTK manager's ``_snap_anchor``.
        anchor_index = next(
            (i for i, (_o, _w, b) in enumerate(members) if b.get("snap_anchor")), 0
        )
        anchor_block = members[anchor_index][2]
        ref_x = int(anchor_block.get("margin_x") or 40)
        ref_y = int(anchor_block.get("margin_y") or 40)
        if str(anchor_block.get("position") or "free") != "free":
            ref_x, ref_y = 40, 40

        if axis == "vertical":
            base_x = ref_x
            base_y = ref_y - anchor_index * (cell_h + SNAP_GAP)
        else:
            base_x = ref_x - anchor_index * (cell_w + SNAP_GAP)
            base_y = ref_y

        # Keep the whole group inside the usable area.
        if bounds and bounds.get("w") and bounds.get("h"):
            bw, bh = int(bounds["w"]), int(bounds["h"])
            span_x = cell_w if axis == "vertical" else count * cell_w + (count - 1) * SNAP_GAP
            span_y = cell_h if axis == "horizontal" else count * cell_h + (count - 1) * SNAP_GAP
            base_x = max(0, min(base_x, bw - span_x)) if bw >= span_x else max(0, (bw - span_x) // 2)
            base_y = max(0, min(base_y, bh - span_y)) if bh >= span_y else max(0, (bh - span_y) // 2)

        for i, (_order, wid, _block) in enumerate(members):
            scale = min(cell_w / max(nat[i][0], 1), cell_h / max(nat[i][1], 1))
            scale = max(SNAP_SCALE_MIN, min(SNAP_SCALE_MAX, scale)) * SNAP_FIT_MARGIN
            if axis == "vertical":
                x, y = base_x, base_y + i * (cell_h + SNAP_GAP)
            else:
                x, y = base_x + i * (cell_w + SNAP_GAP), base_y
            out[wid] = {"x": x, "y": y, "w": cell_w, "h": cell_h, "scale": round(scale, 4)}
    return out


def set_position(widget_id: str, x: int, y: int, config_path: Path = BAR_CONFIG) -> bool:
    """Persist a dragged widget's free position into the widgets block.

    A dragged widget is detached from its snap group (its ``snap_group`` is
    cleared) so the group layout does not immediately snap it back, matching
    the GTK bar.
    """
    try:
        data = json.loads(config_path.read_text())
    except (OSError, ValueError):
        return False
    widgets = data.setdefault("widgets", {})
    block = widgets.setdefault(widget_id, {})
    block["position"] = "free"
    block["margin_x"] = int(x)
    block["margin_y"] = int(y)
    block["snap_group"] = ""
    block.pop("snap_anchor", None)
    try:
        config_path.parent.mkdir(parents=True, exist_ok=True)
        fd, tmp = tempfile.mkstemp(dir=str(config_path.parent), prefix=".config.", suffix=".tmp")
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
            f.flush()
            os.fsync(f.fileno())
        os.replace(tmp, config_path)
        return True
    except OSError:
        return False


def _write(data: dict, config_path: Path) -> bool:
    try:
        config_path.parent.mkdir(parents=True, exist_ok=True)
        fd, tmp = tempfile.mkstemp(dir=str(config_path.parent), prefix=".config.", suffix=".tmp")
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
            f.flush()
            os.fsync(f.fileno())
        os.replace(tmp, config_path)
        return True
    except OSError:
        return False


def _rect(r: dict) -> tuple[int, int, int, int]:
    return int(r.get("x") or 0), int(r.get("y") or 0), int(r.get("w") or 0), int(r.get("h") or 0)


def snap_axis(a: dict, b: dict) -> tuple[int | None, str | None]:
    """Return ``(gap, axis)`` when *a* and *b* are adjacent, else ``(None, None)``."""
    ax, ay, aw, ah = _rect(a)
    bx, by, bw, bh = _rect(b)
    hgap = max(ax, bx) - min(ax + aw, bx + bw)
    vgap = max(ay, by) - min(ay + ah, by + bh)
    v_overlap = min(ay + ah, by + bh) - max(ay, by)
    h_overlap = min(ax + aw, bx + bw) - max(ax, bx)
    h_ok = hgap <= SNAP_DIST and v_overlap > min(ah, bh) * 0.4
    v_ok = vgap <= SNAP_DIST and h_overlap > min(aw, bw) * 0.4
    if h_ok and (not v_ok or hgap <= vgap):
        return hgap, "horizontal"
    if v_ok:
        return vgap, "vertical"
    return None, None


def _new_group_id(widgets: dict) -> str:
    existing = {
        str(b.get("snap_group") or "").strip()
        for b in widgets.values() if isinstance(b, dict)
    }
    index = 1
    while f"g{index}" in existing:
        index += 1
    return f"g{index}"


def snap(widget_id: str, x: int, y: int, rects: dict, config_path: Path = BAR_CONFIG) -> dict:
    """Persist a dropped position and join the nearest adjacent widget's group.

    *rects* maps ``id -> {x, y, w, h}`` (on-screen) for every widget; the moved
    widget's entry is overridden with the dropped ``x``/``y``. Returns
    ``{"ok", "snapped", ...}``.
    """
    rects = {k: dict(v) for k, v in (rects or {}).items()}
    if widget_id in rects:
        rects[widget_id]["x"] = int(x)
        rects[widget_id]["y"] = int(y)
    try:
        data = json.loads(config_path.read_text())
    except (OSError, ValueError):
        return {"ok": False, "snapped": False}
    widgets = data.setdefault("widgets", {})
    block = widgets.setdefault(widget_id, {})
    block["position"] = "free"
    block["margin_x"] = int(x)
    block["margin_y"] = int(y)

    moved = rects.get(widget_id)
    best = None
    if moved:
        for oid, r in rects.items():
            if oid == widget_id:
                continue
            gap, axis = snap_axis(moved, r)
            if gap is None:
                continue
            if best is None or gap < best[0]:
                best = (gap, axis, oid)

    if best is None:
        block["snap_group"] = ""
        block.pop("snap_anchor", None)
        ok = _write(data, config_path)
        return {"ok": ok, "snapped": False}

    _gap, axis, other_id = best
    other = widgets.setdefault(other_id, {})
    had_group = bool(str(other.get("snap_group") or "").strip())
    group = str(other.get("snap_group") or "").strip() or _new_group_id(widgets)
    if not had_group:
        # New group: the target becomes its first member.
        other["snap_group"] = group
        other["snap_axis"] = axis
        other.setdefault("snap_order", 0)
    group_axis = str(other.get("snap_axis") or axis)
    members = [
        wid for wid, b in widgets.items()
        if isinstance(b, dict) and str(b.get("snap_group") or "").strip() == group
    ]
    if widget_id not in members:
        members.append(widget_id)
    # The joining widget is appended after the existing members (drop order,
    # matching GTK) and becomes the group's anchor so it stays where dropped.
    max_order = max(
        (int(widgets[wid].get("snap_order", 0) or 0) for wid in members if wid != widget_id),
        default=-1,
    )
    for wid in members:
        widgets[wid]["snap_group"] = group
        widgets[wid]["snap_axis"] = group_axis
        widgets[wid].pop("snap_anchor", None)
    widgets[widget_id]["snap_order"] = max_order + 1
    widgets[widget_id]["snap_anchor"] = True
    ok = _write(data, config_path)
    return {"ok": ok, "snapped": True, "group": group, "axis": group_axis}


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="desktop-widget snap-group layout")
    sub = ap.add_subparsers(dest="action", required=True)
    lp = sub.add_parser("layout")
    lp.add_argument("--json", required=True)
    lp.add_argument("--heights")
    lp.add_argument("--bounds")
    sp = sub.add_parser("set")
    sp.add_argument("--id", required=True)
    sp.add_argument("--x", type=int, required=True)
    sp.add_argument("--y", type=int, required=True)
    np_ = sub.add_parser("snap")
    np_.add_argument("--id", required=True)
    np_.add_argument("--x", type=int, required=True)
    np_.add_argument("--y", type=int, required=True)
    np_.add_argument("--rects", required=True)
    args = ap.parse_args(argv)

    if args.action == "set":
        ok = set_position(args.id, args.x, args.y)
        print(json.dumps({"ok": ok}))
        return 0 if ok else 1

    if args.action == "snap":
        try:
            rects = json.loads(args.rects)
        except ValueError:
            rects = {}
        print(json.dumps(snap(args.id, args.x, args.y, rects)))
        return 0

    try:
        widgets = json.loads(args.json)
        heights = json.loads(args.heights) if args.heights else None
        bounds = json.loads(args.bounds) if args.bounds else None
    except ValueError:
        print(json.dumps({"layout": {}}))
        return 1
    print(json.dumps({"layout": layout(widgets, heights, bounds)}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
