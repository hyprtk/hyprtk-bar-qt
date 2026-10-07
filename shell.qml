// hyprtk-bar-qt — Quickshell entry point.
//
// QML presentation layer of the Qt rewrite. One layer-shell PanelWindow per
// screen, each rendering Bar.qml, plus the surfaces (quick settings, settings,
// arc menu, bar menu, start menu, themer). Heavy logic lives in the Python
// backend (backend/hyprtk_bar_qt) and is streamed in over Quickshell Process.
import Quickshell
import QtQuick
import "bar"
import "surface"
import "config"
import "state"
import "data"

ShellRoot {
    id: shell

    // Screens that should show the bar, per the shared hyprtk-bar `monitors`
    // selector ("primary" | "all" | ["CONNECTOR", ...]).
    function _screens() {
        const screens = Quickshell.screens;
        const m = BarConfig.monitors;
        if (Array.isArray(m))
            return screens.filter(s => m.indexOf(s.name) >= 0);
        if (m === "all")
            return screens;
        return screens.length ? [screens[0]] : [];
    }

    // Parsed bar width in px for a given screen width.
    function _width(screenW) {
        const w = BarConfig.barWidth;
        if (typeof w === "string" && w.endsWith("%")) {
            const pct = parseFloat(w);
            return Math.round(screenW * Math.max(0, Math.min(pct, 100)) / 100);
        }
        const px = parseInt(w);
        return isNaN(px) ? screenW : px;
    }
    // Left/right margins for the bar pill on a screen of the given width.
    function _insets(screenW) {
        const avail = screenW - BarConfig.gapOut * 2;
        const w = Math.max(120, Math.min(shell._width(screenW), avail));
        const leftover = avail - w;
        if (BarConfig.barAlign === "left")
            return { left: BarConfig.gapOut, right: BarConfig.gapOut + leftover };
        if (BarConfig.barAlign === "right")
            return { left: BarConfig.gapOut + leftover, right: BarConfig.gapOut };
        const half = Math.round(leftover / 2);
        return { left: BarConfig.gapOut + half, right: BarConfig.gapOut + (leftover - half) };
    }

    Variants {
        model: shell._screens()

        PanelWindow {
            id: panel
            required property var modelData
            screen: modelData

            readonly property var insets: shell._insets(modelData.width)

            anchors.top: BarConfig.barPosition === "top"
            anchors.bottom: BarConfig.barPosition === "bottom"
            anchors.left: true
            anchors.right: true
            margins.top: BarConfig.barPosition === "top" ? BarConfig.gapOut : 0
            margins.bottom: BarConfig.barPosition === "bottom" ? BarConfig.gapOut : 0
            margins.left: panel.insets.left
            margins.right: panel.insets.right
            implicitHeight: BarConfig.barHeight
            exclusiveZone: BarConfig.barHeight + BarConfig.gapOut
            color: "transparent"

            Bar {
                anchors.fill: parent
            }
        }
    }

    QuickSettings {}
    Settings {}
    ArcMenu {}
    BarMenu {}
    StartMenu {}
    Themer {}
    SysMonitor {}
    NotificationCenter {}
    Clipboard {}
    DesktopWidgets {}

    Loader {
        active: Quickshell.env("HYPRTK_BAR_QT_NOTIFICATIONS") === "1"
        source: "surface/Notifications.qml"
    }
}
