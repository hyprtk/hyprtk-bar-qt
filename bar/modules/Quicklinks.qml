// Quick links: a configurable row of launcher glyphs.
// Left-click runs `command`; right/middle-click runs `alt` when set.
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../theme"
import "../../config"
import "../../state"

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
                    const linkData = link.modelData;
                    // Built-in surface actions (no command).
                    if (mouse.button === Qt.LeftButton && linkData.action) {
                        if (linkData.action === "clipboard")
                            UiState.clipboardOpen = !UiState.clipboardOpen;
                        else if (linkData.action === "themer")
                            UiState.themerOpen = !UiState.themerOpen;
                        else if (linkData.action === "settings")
                            UiState.settingsOpen = true;
                        return;
                    }
                    const cmd = (mouse.button === Qt.LeftButton)
                        ? linkData.command
                        : (linkData.alt || linkData.command);
                    if (cmd)
                        Quickshell.execDetached(["sh", "-c", cmd]);
                }
            }
        }
    }
}
