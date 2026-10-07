# Changelog

## 0.9.0 — unreleased

Parity pass 6 (theming, part 1): shipped bar themes.

- `backend/hyprtk_bar_qt/theme_import.py`: ported the toolkit-free waybar-CSS
  decoder (resolve `@import`/`@define-color`, derive
  background/foreground/accent/etc.).
- `backend/hyprtk_bar_qt/themes.py`: CLI over `theme_import` — `list` returns
  the installed themes with hexified swatches, `palette <name>` one theme.
- `backend/hyprtk_bar_qt/config.py`: `PYWAL_PATH` + `load_pywal_colors`.
- `surface/Themer.qml`: a "Bar themes" picker (name + swatches) writes Theme
  overrides; "Follow hyprtk-bar / pywal" clears them.
- Tests: `tests/test_themes.py`.

## 0.8.0 — unreleased

Parity pass 5: clipboard history + tray context menu.

- `surface/Clipboard.qml`: in-bar clipboard history (cliphist) — search, click to
  copy (text/image), per-row delete, two-step "Clear all", Esc to close. Toggle
  from the clipboard quicklink or `qs ipc call clipboard toggle`
  (`bin/hyprtk-bar-qt-clipboard-toggle`).
- `backend/hyprtk_bar_qt/clipboard.py`: toolkit-free cliphist wrapper
  (list/copy/delete/wipe) with a testable `parse_list`.
- `bar/modules/Tray.qml`: right-click now opens the item's DBusMenu via
  `QsMenuAnchor` (items with `onlyMenu` open it on left-click too).
- `bar/modules/Quicklinks.qml`: quicklinks can carry a built-in `action`
  (`clipboard` / `themer` / `settings`) instead of a command; defaults now
  include Wallpaper and Clipboard.

## 0.7.0 — unreleased

Parity pass 4: notification center.

- `data/NotifyData.qml`: singleton owning the notification daemon (gated behind
  `HYPRTK_BAR_QT_NOTIFICATIONS=1`), the tracked history, arrival timestamps, the
  unread count and the transient toast queue.
- `surface/NotificationCenter.qml`: Win11-style history panel — newest first,
  per-row dismiss + actions, "Clear all", relative time, unread badge reset on
  open.
- `bar/modules/NotificationsButton.qml`: bell with a numbered unread badge;
  registered in the default right layout and the Settings module list.
- `surface/Notifications.qml`: reworked to render only the transient toasts from
  `NotifyData` (history outlives the toast).

## 0.6.0 — unreleased

Parity pass 3: Mission Center-style system monitor dialog.

- `surface/SysMonitor.qml`: layer-shell panel floated above the bar, opened by
  left-clicking the sysmon module. Sidebar (CPU / Memory / Disks / Network /
  GPU / Apps) + `StackLayout`, live QML graphs (`Sparkline`), stat readouts, a
  per-core bar grid, a clickable drive grid, a network-interface list and an
  Apps page (user/system apps + processes, Launch / Kill / Force kill with a
  confirm dialog). Page set follows `Config.sysmonPages`; graph colours follow
  the live pywal palette.
- `backend/hyprtk_bar_qt/monitor.py`: streams a full JSON sample per interval
  (selected pages only) — a `MonitorSampler` over the ported readers. The
  process walk is gated on `--active apps` so it only runs while the Apps page
  is on screen.
- `backend/hyprtk_bar_qt/proc_action.py`: one-shot `kill` / `launch` helper the
  Apps page buttons invoke (reuses `monitor_data.kill_process`/`launch_process`).
- Memory Slots section on the Memory page: DIMM cards (populated/size/locator)
  from SMBIOS, read from the cache on first open and refreshed on demand via
  `backend/hyprtk_bar_qt/dimm.py` (may prompt once through pkexec).
- `backend/hyprtk_bar_qt/monitor_data.py`: ported the GTK bar's toolkit-free
  readers (CPU cores/load/temps, memory, disk I/O, network interfaces, GPU across
  AMD/NVIDIA/Intel, drives via lsblk, processes, DIMMs). Shares the
  `~/.cache/hyprtk-bar` caches with the GTK bar.
- `data/MonitorData.qml`: singleton that runs the backend only while the dialog
  is open and exposes the latest sample + rolling histories.
- `Config`: `sysmonMonitor`, `sysmonInterval`, `sysmonDataPoints`,
  `sysmonDiskPath`, `sysmonNetworkIface`, `sysmonPages`.
- `Theme.walColor(n, fallback)` helper for arbitrary pywal palette indices.
- Tests: `tests/test_monitor.py`.

## 0.5.0 — unreleased

Parity pass 2: data-driven layout, full settings window, config writer.

- **Data-driven bar layout**: `Config.layoutLeft/Center/Right` hold module names;
  `Bar.qml` renders them via a `DelegateChooser` registry. `shell.qml` honours
  `barPosition`, `barHeight`, `gapOut`, `radius`, `barWidth` (px or %) and
  `barAlign`, computing layer-shell margins per screen.
- **Settings window**: nine pages (Bar / Themes / Fonts / Animations / Arc Menu /
  Menu / Quicklinks / Modules / Widgets) with a sidebar + StackLayout.
- **Config writer**: `Config` now persists ~30 keys generically (`_keys`
  load/save); geometry, layout, theme overrides, fonts, animations, quicklinks,
  menu, arc menu, power.
- **Theme overrides**: `Config.themeBackground/Foreground/Accent/themeName/source`
  take precedence over the hyprtk-bar config, then pywal.
- New `Quicklinks` module + `BarIconButton` component; button modules
  (`StartButton`/`ThemerButton`/`SettingsButton`/`ArcButton`/`QuickSettingsButton`)
  registered in the layout.

## 0.4.0 — unreleased

Parity pass 1: bar menu, start menu, themer, more modules.

- `surface/BarMenu.qml`: right-click the bar → Start Menu / Settings / Themer /
  Quick Settings / Arc Menu / Reload / Lock.
- `surface/StartMenu.qml`: searchable app grid (`DesktopEntries` + icon lookup),
  Settings/Themer shortcuts, power footer (lock/suspend/logout/reboot/shutdown).
- `surface/Themer.qml` v1: live palette swatches, bar-opacity override,
  regenerate-palette / save / close.
- Modules: `ActiveWindow.qml` (focused title), `KbState.qml` (Caps/Num LEDs via
  new `backend/.../kbleds.py`), `Updates.qml` (pending-update count).
- `Config`: opacity override, `showWindow`/`showUpdates`/`showKbState`,
  `menuPower`. `UiState`: `startMenuOpen`/`themerOpen`/`barMenuOpen`/`barMenuX`.
- Bar: start button (left) + Themer/Settings/Arc/Quick-Settings buttons (right).
- `PARITY.md`: full like-for-like matrix vs `hyprtk-bar`.

## 0.3.0 — unreleased

Graph widgets + arc menu.

- `components/Sparkline.qml`: Canvas line + gradient-area graph.
- `data/SysData.qml`: shared singleton running the backend once, exposing
  cpu/mem/net + rolling histories.
- `Net` module (rx/tx rates + sparklines) and `SysMonitor` now shows CPU/mem
  sparklines; backend `sysmon.py` extended with network byte rates.
- `surface/ArcMenu.qml`: corner FAB with items fanned along an arc
  (position/items from `Config`), toggleable via `qs ipc call arcmenu toggle`
  (`bin/hyprtk-bar-qt-arc-toggle`).
- `Config` gained `arcMenuPosition` / `arcMenuItems`; `UiState` gained
  `arcMenuOpen`.
- Added `tests/test_sysmon.py` + `Makefile` (`make test`).

## 0.2.0 — unreleased

Modules and surfaces.

- Modules: `Tasklist` (open windows — activate / middle-click close), `Tray`
  (SNI system tray), plus the existing `Workspaces`, `Clock`, `SysMonitor`.
- `surface/QuickSettings.qml`: volume (wpctl), brightness (brightnessctl),
  Wi-Fi (nmcli), Bluetooth (bluetoothctl) + Settings/Lock shortcuts.
- `surface/Settings.qml`: edits `config/Config.qml` (bar height, clock format,
  module visibility) and writes `~/.config/hyprtk-bar-qt/config.json`.
- `surface/Notifications.qml`: notification daemon + toast stack, opt-in behind
  `HYPRTK_BAR_QT_NOTIFICATIONS=1` (one owner of the notifications bus name).
- New singletons `Config` and `UiState` (named to avoid QtQuick `Palette`/`State`
  clashes) and a `Toggle` component.

## 0.1.0 — unreleased

Initial Qt/QML rewrite scaffold (Quickshell + Python backend).

- `shell.qml`: layer-shell `PanelWindow` per screen via Quickshell.
- `bar/`: frosted panel with `Workspaces` (Hyprland), `Clock` (SystemClock) and
  `SysMonitor` modules.
- `theme/Palette.qml`: singleton resolving live pywal colours + the existing
  `hyprtk-bar` config (source, theme block, opacity).
- `backend/hyprtk_bar_qt/`: toolkit-free Python logic — `palette.py`,
  `config.py`, and `sysmon.py` (streams CPU/memory as JSON lines over stdout).
- `bin/hyprtk-bar-qt`, `install.sh`, packaging metadata.

Chosen architecture: QML presentation + Python/IPC logic, because PySide6/
QtWidgets has no supported Wayland layer-shell binding.
