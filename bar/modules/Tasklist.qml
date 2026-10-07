// Window list (tasklist). Left-click activates a window, middle-click closes it.
//
// Backed by the Quickshell Hyprland service (Quickshell.Wayland Toplevel):
// title / activated / appId, with activate() and close().
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../../theme"

RowLayout {
    id: root
    spacing: 4

    Repeater {
        model: Hyprland.toplevels

        delegate: Rectangle {
            id: win
            required property var modelData

            readonly property int maxWidth: 180
            readonly property int textWidth: Math.min(label.implicitWidth, win.maxWidth)

            implicitWidth: win.textWidth + 16
            implicitHeight: 22
            radius: 6
            color: win.modelData.activated
                ? Theme.alpha(Theme.accent, 0.85)
                : Theme.alpha(Theme.accent2, 0.12)

            Text {
                id: label
                anchors.centerIn: parent
                width: win.textWidth
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                text: win.modelData.title || win.modelData.appId || "?"
                color: win.modelData.activated ? "#000000" : Theme.foreground
                font.pixelSize: 11
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => {
                    if (mouse.button === Qt.MiddleButton)
                        win.modelData.close();
                    else
                        win.modelData.activate();
                }
            }
        }
    }
}
