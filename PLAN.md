# hyprtk-bar-qt — Parity Remediation Plan

Source: static audit of `hyprtk-bar-qt` vs the reference GTK4 bar
(`../hyprtk-bar/`). Created 2026-10-08. This is the record of what is
non-functional / missing and the order in which it is being fixed.

Method: read every QML surface/module/component, every backend module, `bin/`,
`install.sh`; map against the GTK bar's `bar.py`, `bar_settings.py`,
`themer.py`, `desktop/*`, `menu/*`, `notifications.py`, `tray.py`, `ipc.py`,
`hypr_animations.py`, and the `tools/e2e` coverage. Claims in `PARITY.md` /
`CHANGELOG.md` were treated as unverified until the code confirmed them.

Legend: `[ ]` todo · `[~]` in progress · `[x]` done

---

## Batch 1 — Install correctness & hygiene  ✅ done

- [x] `install.sh` no-rsync fallback now copies the full runtime tree
      (`surface/`, `components/`, `config/`, `data/`, `state/` were missing) and
      prunes `__pycache__`.
- [x] `install.sh` links every `bin/*` helper into `~/.local/bin`.
- [x] Version aligned: `__init__.py __version__` 0.27.0 → 0.30.0.
- [x] Dead code purged: `palette.py` (+ its 75 lines), `config.load_config()/get()`,
      unused `config`/`sys` imports in `wallpapers.py`, `UiState.closeAll()`,
      `Themer.col()/lockColors()/swatchNames`; CHANGELOG's phantom `arc_toggle.py`
      corrected to `signal_bridge.py`.
- [x] Stale comments updated (`data/Widgets.qml`, `surface/DesktopWidgets.qml`,
      `surface/Themer.qml`).
- [x] `Settings.qml onExited` now warns on non-zero write exit.
- [x] Nerd-Font glyphs pinned in `SysMonitor`, `QuickSettings`, `Themer`,
      `StartMenu`.

## Batch 2 — Dead settings wiring  ✅ done

- [x] A1 start-button Enabled now writes/reads `center.start_button` (new
      `Settings.moduleEnabledKey`), and `StartButton.qml` gates on it.
- [x] A2 `font.icon_size` honoured via new `BarConfig.iconSize()` (matches GTK
      `icon_size_for`); applied to `BarIconButton` + Net/KbState/SysMonitor glyphs.
- [x] A3 "UI animations" toggle now calls `Config.save()` — persists.
- [x] A4 dead Qt geometry keys removed from `config/Config.qml` + `_keys`
      (shared `BarConfig` is authoritative; only `opacity` override remains).
- [x] A5 `Config.menuLayout`, `Config.sysmonMonitor` removed.
- [x] A6 `use_pywal` honoured by `Theme.qml` (legacy seed of `theme.source`);
      redundant `BarConfig.usePywal` removed.
- [x] A9 Settings hint corrected (Low/High are presets; real Hyprland-follow in
      Batch 6).

## Batch 3 — Anchors & multi-monitor  ✅ done

- [x] A7 `BarMenu` + notification toasts now honour `barPosition` (anchor to the
      bar's edge, top or bottom) instead of hardcoding top.
- [x] A14 desktop widgets place on the focused monitor captured at startup
      (matches GTK `manager.py`, which uses the focused monitor; GTK itself does
      not do per-display widgets — that stays on GTK's roadmap).
- [x] A15 new `data/Screens.qml` (name→ShellScreen + focused monitor). Bar
      modules register their monitor (`BarAnchors`); popups set `screen:` to the
      clicked monitor (bell/QS/start/menu) or the focused monitor on open
      (SysMonitor/Clipboard/Settings/Themer/About/toasts).
- [x] A16 Tasklist restores a window from a negative-id (special/minimized)
      workspace before focusing it (GTK `tasklist.py:576`).

## Batch 4 — Settings parity UI

- [ ] Widgets page: layer, margin_x/y, width/height, radius, padding,
      snap_group/axis/order + per-widget specific options (GTK
      `bar_settings.py:1544-1670`).
- [ ] Menu page: `enabled`, `follow_bar`, `gap_in`, `gap_out`.
- [ ] Modules page: reorder (up/down) + section radios; fix append-only
      `setSection`.
- [ ] Fonts page: installed-font picker (GTK `Gtk.FontButton`).
- [ ] Themes page: `imported` source + imported-theme-name picker; resolve the
      conflict with `Config.themeSource` set by Themer (A13).
- [ ] Per-module option editors: `workspaces.show_empty/max`,
      `clock.format/date_format/calendar`, `updates.interval/scripts`,
      `window.max_length/width`, `tray.icon_size`,
      `notifications.max_stored/default_timeout`.
- [ ] Arc-item editor: add `action` field (settings/themer/clipboard).
- [ ] Wire `Settings.addFavorite()` (currently dead → can't add menu favourites).

## Batch 5 — Widget parity

- [ ] Clock widget: `theme` files, `show_seconds`, `dial_count`,
      `ring_thickness` (currently one dial).
- [ ] Visualizer widget: `source`, `sensitivity`, `smoothing`, `orientation`,
      `peak_dots`.
- [ ] Widget global border (`widgets.border`) — currently only driven by
      `transparent`.
- [ ] QuickSettings brightness gamma fallback via `hyprsunset` when no backlight.
- [ ] QuickSettings Lock honours config (`menu.power.lock`), not hardcoded.
- [ ] Quicklinks glyph-font fallback → `BarConfig.glyphFont`.

## Batch 6 — Missing features (new work)

- [ ] `hypr_animations` backend port (border mode/speed from Hyprland files) and
      wire the low/high modes to it.
- [ ] MPRIS media control module.
- [ ] Notification images / action icons in toasts + center.
- [ ] Themer changes persist without Save (A12).
- [ ] SDDM/GRUB updater path discovery (no hardcoded `~/hyprtk`) (A23).

## Batch 7 — Verification

- [ ] Update `PARITY.md` row-by-row from the audit result.
- [ ] Re-run `make test` + `qmllint`; add tests for the newly wired settings.
- [ ] Launch the bar and exercise each fixed surface (`grim` capture evidence).
- [ ] Re-audit: advertised status must match code (no "implemented ✅" unless
      verified).
