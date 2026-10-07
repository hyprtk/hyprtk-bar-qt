// Arc menu — a corner FAB whose items fan out along an arc (MaterialArcMenu
// concept, merged from the old hyprtk-arc-menu). Items/position come from
// Config; each item runs a command or opens a surface.
//
// Toggle from the bar button, the input action, or:
//   qs ipc call arcmenu toggle
import QtQuick
import Quickshell
import Quickshell.Io
import "../theme"
import "../config"
import "../state"

PanelWindow {
    id: arc

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    focusable: true
    visible: UiState.arcMenuOpen

    // Per-position fan (angles in degrees, screen y grows downward).
    readonly property var pos: ({
        "top-left":      { h: 0,   v: 0, start: 0,   end: 90  },
        "top-right":     { h: 1,   v: 0, start: 90,  end: 180 },
        "bottom-left":   { h: 0,   v: 1, start: 270, end: 360 },
        "bottom-right":  { h: 1,   v: 1, start: 180, end: 270 },
        "top-center":    { h: 0.5, v: 0, start: 0,   end: 180 },
        "bottom-center": { h: 0.5, v: 1, start: 180, end: 360 }
    }[Config.arcMenuPosition] || { h: 1, v: 0, start: 90, end: 180 })

    readonly property bool centered: pos.h === 0.5
    readonly property int size: 300
    readonly property int fabSize: 46
    readonly property int itemSize: 42
    readonly property int edge: 8
    readonly property int radius: 92

    anchors.top: pos.v === 0
    anchors.bottom: pos.v === 1
    anchors.left: pos.h === 0 || centered
    anchors.right: pos.h === 1 || centered
    implicitWidth: centered ? 640 : size
    implicitHeight: size

    function fabX() {
        if (pos.h === 0)
            return edge;
        if (pos.h === 1)
            return width - edge - fabSize;
        return (width - fabSize) / 2;
    }
    function fabY() {
        if (pos.v === 0)
            return edge;
        if (pos.v === 1)
            return height - edge - fabSize;
        return (height - fabSize) / 2;
    }

    function run(item) {
        UiState.arcMenuOpen = false;
        if (item.action === "settings") {
            UiState.settingsOpen = true;
            return;
        }
        if (item.command)
            Quickshell.execDetached(["sh", "-c", item.command]);
    }

    IpcHandler {
        target: "arcmenu"
        function toggle() { UiState.arcMenuOpen = !UiState.arcMenuOpen; }
        function open() { UiState.arcMenuOpen = true; }
        function close() { UiState.arcMenuOpen = false; }
    }

    // items, fanned
    Repeater {
        model: Config.arcMenuItems

        delegate: Rectangle {
            id: cell
            required property var modelData
            required property int index

            readonly property real n: Math.max(1, Config.arcMenuItems.length)
            readonly property real t: cell.n <= 1 ? 0.5 : cell.index / (cell.n - 1)
            readonly property real angDeg: arc.pos.start + (arc.pos.end - arc.pos.start) * cell.t
            readonly property real ang: cell.angDeg * Math.PI / 180

            width: arc.itemSize
            height: arc.itemSize
            radius: arc.itemSize / 2
            x: arc.fabX() + arc.fabSize / 2 + arc.radius * Math.cos(cell.ang) - width / 2
            y: arc.fabY() + arc.fabSize / 2 + arc.radius * Math.sin(cell.ang) - height / 2
            color: Theme.alpha(Theme.accent2, 0.9)
            border.color: Theme.alpha(Theme.accent, 0.9)
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: cell.modelData.glyph || "\u2022"
                color: "#000000"
                font.pixelSize: 16
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: arc.run(cell.modelData)
            }
        }
    }

    // the FAB
    Rectangle {
        id: fab
        x: arc.fabX()
        y: arc.fabY()
        width: arc.fabSize
        height: arc.fabSize
        radius: width / 2
        color: Theme.accent

        Text {
            anchors.centerIn: parent
            text: "\u2715"
            color: "#000000"
            font.pixelSize: 18
            font.bold: true
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: UiState.arcMenuOpen = false
        }
    }
}
