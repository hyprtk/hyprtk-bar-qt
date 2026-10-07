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

ShellRoot {
    id: shell

    // Parsed bar width in px for a given screen width.
    function _width(screenW) {
        const w = Config.barWidth;
        if (typeof w === "string" && w.endsWith("%")) {
            const pct = parseFloat(w);
            return Math.round(screenW * Math.max(0, Math.min(pct, 100)) / 100);
        }
        const px = parseInt(w);
        return isNaN(px) ? screenW : px;
    }
    // Left/right margins for the bar pill on a screen of the given width.
    function _insets(screenW) {
        const avail = screenW - Config.gapOut * 2;
        const w = Math.max(120, Math.min(shell._width(screenW), avail));
        const leftover = avail - w;
        if (Config.barAlign === "left")
            return { left: Config.gapOut, right: Config.gapOut + leftover };
        if (Config.barAlign === "right")
            return { left: Config.gapOut + leftover, right: Config.gapOut };
        const half = Math.round(leftover / 2);
        return { left: Config.gapOut + half, right: Config.gapOut + (leftover - half) };
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panel
            required property var modelData
            screen: modelData

            readonly property var insets: shell._insets(modelData.width)

            anchors.top: Config.barPosition === "top"
            anchors.bottom: Config.barPosition === "bottom"
            anchors.left: true
            anchors.right: true
            margins.top: Config.barPosition === "top" ? Config.gapOut : 0
            margins.bottom: Config.barPosition === "bottom" ? Config.gapOut : 0
            margins.left: panel.insets.left
            margins.right: panel.insets.right
            implicitHeight: Config.barHeight
            exclusiveZone: Config.barHeight + Config.gapOut
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

    Loader {
        active: Quickshell.env("HYPRTK_BAR_QT_NOTIFICATIONS") === "1"
        source: "surface/Notifications.qml"
    }
}
