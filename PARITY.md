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
| `notifications` | daemon + center (bell) | ✅ `NotificationsButton.qml` bell + unread badge, `surface/NotificationCenter.qml` history, opt-in toasts |
| `tray` | SNI tray + dbusmenu | ✅ `Tray.qml` (icons + activate + right-click DBusMenu via `QsMenuAnchor`) |
| `quicksettings` | Win11 flyout | ✅ `surface/QuickSettings.qml` |
| graphs | cpu/mem/net history | ✅ `components/Sparkline.qml`, `Net.qml` |

## Surfaces / popups / menus

| GTK | Qt status |
|---|---|
| Bar settings window (9 pages) | ◐ `surface/Settings.qml` (4 controls; needs pages) |
| System monitor dialog (CPU/Mem/Disks/Network/GPU/Apps, cairo graphs) | ✅ `surface/SysMonitor.qml` (six pages, QML graphs, DIMM slots) |
| Themer dialog (Wallpaper/Pywal/Rofi/Bar themes/Matuwall/Swaylock/Icons/SDDM+GRUB) | ✅ `surface/Themer.qml` (all nine pages, incl. the Matuwall TOML editor) |
| Clipboard history dialog | ✅ `surface/Clipboard.qml` (cliphist list/copy/delete/wipe, search) |
| Notification center | ✅ `surface/NotificationCenter.qml` (history, actions, clear all, unread badge) |
| Quick-settings flyout | ✅ |
| Arc menu (radial FAB) | ✅ `surface/ArcMenu.qml` (items from config; no per-layout themes) |
| Start menu (whisker / win7 / win11 / plasma layouts, search, favorites, recents, places, power) | ✅ `surface/StartMenu.qml` (4 layouts, search, favourites, recents, category sidebar, win7 places, power) |
| Bar right-click menu | ✅ `surface/BarMenu.qml` |
| Theme import dialog | ✅ Themer `Import` page (importable list, path, remove) |

## Settings pages (`bar_settings.py`)

Bar · Fonts · Themes · Animations · Arc Menu · Menu · Quicklinks · Modules · Widgets

✅ all nine pages in `surface/Settings.qml` (sidebar + StackLayout). Some controls
are partial: arc-item editing, live font application, and the Widgets page is a
stub.

## Config schema (`config.py`)

| Section | Qt status |
|---|---|
| `bar` (position/height/gaps/radius/opacity/width/align) | ✅ |
| `monitors` (primary / all / [connector]) | ✅ `shell.qml` screen filter |
| `theme` (source/theme_name/background/foreground/accent) | ✅ writer + `Theme` overrides |
| `animations`, `font` | ◐ animations stored; `font` family/size applied to modules |
| `layout` (left/center/right module lists) | ✅ data-driven (`DelegateChooser`) |
| `quicklinks` | ✅ |
| `menu` (layout + power) | ◐ (layout stored; v1 grid) |
| `sysmon` (interval/data_points/disk_path/network_iface/pages/monitor) | ✅ |
| `workspaces` (show_empty/max), `clock` (format), `updates` (interval/scripts), `window` (max_length/width), `tray` (icon_size) | ✅ |
| `quicksettings`, `notifications`, `arcmenu`, `widgets` | ◐ (partial) |
| — own qt config (`~/.config/hyprtk-bar-qt/config.json`) | ✅ `config/Config.qml` |

## Theming components

| GTK | Qt status |
|---|---|
| Live pywal palette | ✅ `theme/Theme.qml` |
| Bar `theme` block (manual/imported source) | ✅ Themer writes the override keys |
| 9 shipped themes (`themes/`) | ✅ Themer picker (`backend/.../themes.py` + `theme_import`) |
| `theme.py` / `menu/theme.py` / `desktop/theme.py` CSS builders | ☐ (QML uses colour tokens only) |
| `theme_import.py` (decode waybar CSS) | ✅ ported to `backend/.../theme_import.py` |
| gengtk/oomox, rofi variants, swaylock, SDDM/GRUB, icons | ☐ |

## Desktop widgets (`desktop/`)

`surface/DesktopWidgets.qml` + `surface/widgets/` — free-floating layer-shell
surfaces reading the shared hyprtk-bar `widgets` config.

| Widget | Qt status |
|---|---|
| `clock` | ✅ digital / text / dials (single analog dial) |
| `resources` | ✅ CPU graph + RAM/swap bars + temp/load |
| `disk` | ✅ per-drive bars + I/O rates |
| `network` | ✅ iface/IP/rates + download graph |
| `weather` | ✅ current + feels/humidity/wind + daily forecast (Open-Meteo, cached) |
| `visualizer` | ✅ cava levels; bars / wave / mirror / dots / glow |
| `sysinfo` | ✅ host/OS/kernel/uptime/CPU/GPU/memory/disks |
| placement: 9-way + `free` | ✅ (`WidgetFrame`) |
| placement: drag / snap / usable-area clamp | ☐ |

## Backend (Python, toolkit-free)

| Module | Qt status |
|---|---|
| `sysmon` (cpu/mem/net) | ✅ `backend/.../sysmon.py` |
| `monitor` (cpu cores/mem/disk/net/gpu, rich stream) | ✅ `backend/.../monitor.py` |
| `monitor_data` (dmidecode/lspci/lsblk) | ✅ `backend/.../monitor_data.py` |
| `clipboard` (cliphist list/copy/delete/wipe) | ✅ `backend/.../clipboard.py` |
| `proc_action` / `dimm` helpers | ✅ |
| palette / config readers | ✅ |
| `hypr_animations` | ☐ |
| `ipc` (hyprctl + socket2) | ◐ (Hyprland service + `IpcHandler` used instead) |

## Next passes

1. Desktop widgets: drag / snap / usable-area placement (all seven widgets done).
2. Start menu: KDE-Plasma in-menu file browser (the places sidebar + content);
   whisker categories and win7 places are done.
3. Remaining config: quicksettings/notifications/arcmenu options, live animation
   application, and full font application to every module.
4. Desktop-widget drag (Super+Shift move) — snap/usable-area still todo.
