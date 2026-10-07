// Workspace pills from the Quickshell Hyprland service. Click to switch.
// Honours the shared `workspaces` block (show_empty, max) and `font` size.
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "../../theme"
import "../../data"

RowLayout {
    id: root
    spacing: 5

    readonly property bool showEmpty: BarConfig.workspaces.show_empty !== false
    readonly property int maxWs: BarConfig.workspaces.max || 10

    function visibleWs() {
        let list = Hyprland.workspaces.values || [];
        if (!root.showEmpty)
            list = list.filter(w => w.active || (w.toplevels && w.toplevels.values.length > 0));
        return list.slice(0, root.maxWs);
    }

    Repeater {
        model: root.visibleWs()

        delegate: Rectangle {
            id: pill
            required property var modelData
            implicitWidth: 22
            implicitHeight: 22
            radius: 6
            color: modelData.active
                ? Theme.accent
                : Theme.alpha(Theme.accent2, 0.15)

            Text {
                anchors.centerIn: parent
                text: pill.modelData.id
                color: pill.modelData.active ? "#000000" : Theme.foreground
                font.pixelSize: Math.max(9, BarConfig.fontSize(Theme.fontSize) - 1)
                font.bold: true
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch("workspace " + pill.modelData.id)
            }
        }
    }
}
