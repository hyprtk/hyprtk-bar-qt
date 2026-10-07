// Workspace pills from the Quickshell Hyprland service. Click to switch.
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "../../theme"

RowLayout {
    id: root
    spacing: 5

    Repeater {
        model: Hyprland.workspaces

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
                text: modelData.id
                color: pill.modelData.active ? "#000000" : Theme.foreground
                font.pixelSize: 11
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
