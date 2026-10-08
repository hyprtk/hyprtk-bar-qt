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

    // Instantiate the keybind signal bridge (menu/arc/clipboard toggles).
    readonly property var signalBridge: SignalBridge

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

    // Bar width / insets are shared with the popups (data/BarGeom.qml).
    function _width(screenW) {
        return BarGeom.width(screenW);
    }
    function _insets(screenW) {
        return BarGeom.insets(screenW);
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
    About {}
    DesktopWidgets {}

    Loader {
        active: Quickshell.env("HYPRTK_BAR_QT_NOTIFICATIONS") === "1"
        source: "surface/Notifications.qml"
    }
}
