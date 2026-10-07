// Quick links: a configurable row of launcher glyphs.
// Left-click runs `command`; right/middle-click runs `alt` when set.
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../theme"
import "../../config"

RowLayout {
    id: root
    spacing: 4

    Repeater {
        model: Config.quicklinksLinks

        delegate: Rectangle {
            id: link
            required property var modelData

            implicitWidth: 22
            implicitHeight: 22
            radius: 6
            color: hover.hovered ? Theme.alpha(Theme.accent2, 0.22) : "transparent"

            Text {
                anchors.centerIn: parent
                text: link.modelData.glyph || "\u2022"
                color: Theme.accent
                font.pixelSize: 13
            }

            HoverHandler { id: hover }
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => {
                    const cmd = (mouse.button === Qt.LeftButton)
                        ? link.modelData.command
                        : (link.modelData.alt || link.modelData.command);
                    if (cmd)
                        Quickshell.execDetached(["sh", "-c", cmd]);
                }
            }
        }
    }
}
