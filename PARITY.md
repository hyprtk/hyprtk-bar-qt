# hyprtk-bar ↔ hyprtk-bar-qt parity matrix

Goal: **like-for-like** with the GTK4 `hyprtk-bar` — all modules, settings,
popups, menus, config and theming components.

Legend: ✅ done · ◐ partial · ☐ todo

## Bar modules (`bar/modules/`)

| GTK module | Purpose | Qt status |
|---|---|---|
| `start_button` | start-menu button | ✅ button + `surface/StartMenu.qml` v1 |
| `quicklinks` | configurable launcher glyph row (L/R/M click) | ✅ `Quicklinks.qml` |
| `workspaces` | Hyprland workspaces | ✅ `Workspaces.qml` |
| `tasklist` | open windows | ✅ `Tasklist.qml` |
| `window` | active window title | ✅ `ActiveWindow.qml` |
| `updates` | package-update count | ✅ `Updates.qml` |
| `sysmon` | CPU/RAM/disk + click → monitor | ✅ `SysMonitor.qml` + `surface/SysMonitor.qml` dialog |
| `kbstate` | Caps/Num lock LEDs | ✅ `KbState.qml` |
| `clock` | time/date (styles, dials, seconds) | ◐ `Clock.qml` (digital simple; no styles/dials) |
| `notifications` | daemon + center (bell) | ◐ `Notifications.qml` (toasts opt-in; no center) |
| `tray` | SNI tray + dbusmenu | ◐ `Tray.qml` (icons + activate; no context menu) |
| `quicksettings` | Win11 flyout | ✅ `surface/QuickSettings.qml` |
| graphs | cpu/mem/net history | ✅ `components/Sparkline.qml`, `Net.qml` |

## Surfaces / popups / menus

| GTK | Qt status |
|---|---|
| Bar settings window (9 pages) | ◐ `surface/Settings.qml` (4 controls; needs pages) |
| System monitor dialog (CPU/Mem/Disks/Network/GPU/Apps, cairo graphs) | ◐ `surface/SysMonitor.qml` (all six pages live, QML graphs; DIMM-slot graphic todo) |
| Themer dialog (Wallpaper/Pywal/Rofi/Bar themes/Matuwall/Swaylock/Icons/SDDM+GRUB) | ◐ `surface/Themer.qml` v1 (palette/opacity/actions; pages todo) |
| Clipboard history dialog | ☐ |
| Notification center | ☐ |
| Quick-settings flyout | ✅ |
| Arc menu (radial FAB) | ✅ `surface/ArcMenu.qml` (items from config; no per-layout themes) |
| Start menu (whisker / win7 / win11 / plasma layouts, search, favorites, recents, places, power) | ◐ `surface/StartMenu.qml` v1 (search + app grid + power; layouts/favorites/recents todo) |
| Bar right-click menu | ✅ `surface/BarMenu.qml` |
| Theme import dialog | ☐ |

## Settings pages (`bar_settings.py`)

Bar · Fonts · Themes · Animations · Arc Menu · Menu · Quicklinks · Modules · Widgets

✅ all nine pages in `surface/Settings.qml` (sidebar + StackLayout). Some controls
are partial: arc-item editing, live font application, and the Widgets page is a
stub.

## Config schema (`config.py`)

| Section | Qt status |
|---|---|
| `bar` (position/height/gaps/radius/opacity/width/align) | ✅ (multi-monitor `monitors` todo) |
| `theme` (source/theme_name/background/foreground/accent) | ✅ writer + `Theme` overrides |
| `animations`, `font` | ◐ (stored; font application partial) |
| `layout` (left/center/right module lists) | ✅ data-driven (`DelegateChooser`) |
| `quicklinks` | ✅ |
| `menu` (layout + power) | ◐ (layout stored; v1 grid) |
| `sysmon` (interval/data_points/disk_path/network_iface/pages/monitor) | ✅ |
| `workspaces`, `clock`, `updates`, `window`, `tray`, `quicksettings`, `notifications`, `arcmenu`, `widgets` | ◐ (partial) |
| — own qt config (`~/.config/hyprtk-bar-qt/config.json`) | ✅ `config/Config.qml` |

## Theming components

| GTK | Qt status |
|---|---|
| Live pywal palette | ✅ `theme/Theme.qml` |
| Bar `theme` block (manual/imported source) | ◐ (palette reads it; no writer) |
| 9 shipped themes (`themes/`) | ☐ |
| `theme.py` / `menu/theme.py` / `desktop/theme.py` CSS builders | ☐ (QML uses colour tokens only) |
| `theme_import.py` (decode waybar CSS) | ☐ |
| gengtk/oomox, rofi variants, swaylock, SDDM/GRUB, icons | ☐ |

## Desktop widgets (`desktop/`)

`clock` · `weather` · `visualizer` · `disk` · `network` · `resources` · `sysinfo`
+ `manager` (placement) — all ☐.

## Backend (Python, toolkit-free)

| Module | Qt status |
|---|---|
| `sysmon` (cpu/mem/net) | ✅ `backend/.../sysmon.py` |
| `monitor` (cpu cores/mem/disk/net/gpu, rich stream) | ✅ `backend/.../monitor.py` |
| `monitor_data` (dmidecode/lspci/lsblk) | ✅ `backend/.../monitor_data.py` |
| palette / config readers | ✅ |
| `hypr_animations` | ☐ |
| `ipc` (hyprctl + socket2) | ◐ (Hyprland service used instead) |

## Next passes

1. System-monitor dialog: DIMM-slot graphic (dmidecode via pkexec) — all six
   pages (CPU/Mem/Disks/Network/GPU/Apps) are otherwise live.
2. Clipboard history, notification center, tray context menu (dbusmenu).
3. Themer: 9 themes, theme_import, wallpaper/pywal/rofi/swaylock/icons/SDDM.
4. Desktop widgets (clock/weather/visualizer/disk/network/resources/sysinfo) + placement.
5. Start-menu layout variants (whisker/win7/win11/plasma), favorites/recents/places.
6. Remaining module config (workspaces/clock/sysmon/tray/quicksettings options),
   multi-monitor `monitors`, animation/font live application.
