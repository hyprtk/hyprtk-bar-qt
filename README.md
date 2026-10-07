# hyprtk-bar-qt

The hyprtk taskbar, rewritten on Qt. **QML presentation + Python/IPC logic**,
built on [Quickshell](https://quickshell.org/) (a QtQuick toolkit that provides
Wayland layer-shell surfaces, Hyprland IPC, SNI tray, MPRIS, PipeWire and more).

This is the Qt counterpart to the GTK4 `hyprtk-bar`. It exists because
PySide6/QtWidgets has **no supported layer-shell binding for Python** — the
supported route for a Wayland bar is QML — so the shell is QML and any logic
that is awkward in QML lives in a toolkit-free Python backend.

See `../hyprtk-bar/QT-MIGRATION.md` for the full assessment and rationale.

## Architecture

```
shell.qml                     Quickshell entry — bar per screen + surfaces
bar/
  Bar.qml                     the frosted panel + module row
  modules/
    Workspaces.qml            Hyprland workspaces (Quickshell.Hyprland), click to switch
    Tasklist.qml              open windows (Toplevel): activate / middle-click close
    Tray.qml                  system tray (SystemTray / SNI)
    Clock.qml                 Quickshell SystemClock (format from Config)
    SysMonitor.qml            CPU/mem % + rolling sparklines (shared SysData)
    Net.qml                   rx/tx rates + rolling sparklines
surface/
  QuickSettings.qml           volume/brightness/Wi-Fi/Bluetooth flyout (wpctl, brightnessctl, nmcli, bluetoothctl)
  Settings.qml                settings window (writes config/Config.qml)
  ArcMenu.qml                 corner FAB with an item arc; IPC-toggleable
  SysMonitor.qml              Mission Center-style system monitor dialog (CPU/Mem/Disks/Network/GPU/Apps)
  Notifications.qml           notification daemon + toasts (opt-in, see below)
theme/
  Theme.qml                   singleton: live pywal + hyprtk-bar config colours
  qmldir
config/
  Config.qml                  singleton: own settings (~/.config/hyprtk-bar-qt/config.json)
state/
  UiState.qml                 singleton: which surface is open
data/
  SysData.qml                 singleton: runs the backend once, exposes cpu/mem/net + histories
  MonitorData.qml             singleton: runs the rich monitor backend while the dialog is open
components/
  Toggle.qml                  pill toggle
  Sparkline.qml               Canvas line + gradient-area graph
backend/
  hyprtk_bar_qt/
    palette.py                palette resolver (mirrors Theme.qml)
    config.py                 hyprtk-bar config reader
    sysmon.py                 /proc sampler (cpu/mem/net), streams JSON lines on stdout
    monitor.py                rich system-monitor sampler (cpu/mem/disk/net/gpu/apps), streams JSON lines
    monitor_data.py           toolkit-free readers (cpu cores/temps, mem, disk, net, gpu, drives, dimms, procs)
    proc_action.py            one-shot kill/launch helper for the Apps page
tests/
  test_sysmon.py              backend unit tests
  test_monitor.py             monitor backend unit tests
bin/hyprtk-bar-qt             launcher wrapper (qs -p <root>)
bin/hyprtk-bar-qt-arc-toggle  hotkey helper (qs ipc call arcmenu toggle)
Makefile                      make test / run / install
install.sh                    copy into the Quickshell config dir
```

Singletons avoid QtQuick name clashes: the theme is `Theme` (not `Palette`) and
UI state is `UiState` (not `State`).

**The split:** QML renders; Python computes. Backend modules never import
Qt/PySide, so they are unit-testable headlessly. QML drives them with
Quickshell `Process` (JSON lines on stdout) and Quickshell `IpcHandler` for
the reverse direction.

## Requirements

- Quickshell (`quickshell` / `qs`) — Arch `extra`, Debian, NixOS
- Qt 6 (QtQuick, QtQuick.Layouts) — pulled in by Quickshell
- Python 3.10+ (backend only; no third-party deps)

No PySide6 required: the shell runs inside Quickshell's own Qt.

## Run

```sh
./bin/hyprtk-bar-qt          # from the repo
qs -p /path/to/hyprtk-bar-qt # explicitly
```

Install into the Quickshell config dir:

```sh
./install.sh                 # -> ~/.config/quickshell/hyprtk-bar-qt
hyprtk-bar-qt                # launcher on ~/.local/bin
# or: qs -c hyprtk-bar-qt
```

## Status

Working bar: workspaces, tasklist, tray, clock, CPU/memory sparklines and a
network-rate graph (all fed by the Python backend), plus a quick-settings
flyout, a settings window, a corner arc menu and a Mission Center-style system
monitor dialog (CPU / Memory / Disks / Network / GPU, opened from the sysmon
module). Theming reads the live pywal
palette and the existing hyprtk-bar config, so it matches the desktop while the
GTK bar still runs alongside it.

`make test` runs the toolkit-free backend unit tests. The arc menu can be bound
to a hotkey with `hyprtk-bar-qt-arc-toggle` (it calls `qs ipc call arcmenu
toggle`).

Notifications (the `org.freedesktop.Notifications` daemon + toasts) are
implemented but **opt-in**, because only one process can own that bus name:

```sh
HYPRTK_BAR_QT_NOTIFICATIONS=1 hyprtk-bar-qt
```

Enable it only once the GTK bar's daemon is retired; otherwise it just warns and
waits to take over.

Roadmap (see `CHANGELOG.md`): arc menu, graph widgets, per-display desktop
widgets, MPRIS media control, and theming to full visual parity.
