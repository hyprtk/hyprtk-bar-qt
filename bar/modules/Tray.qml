// System tray (SNI host), via Quickshell's StatusNotifier service.
//
// Left-click activates, middle-click secondary-activates. Context menus come
// from Quickshell.DBusMenu in a follow-up; icons use the item's icon string
// (usually an absolute path).
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import "../../theme"

RowLayout {
    id: root
    spacing: 6

    Repeater {
        model: SystemTray.items

        delegate: Item {
            id: item
            required property var modelData

            implicitWidth: 18
            implicitHeight: 18

            Image {
                anchors.fill: parent
                source: item.modelData.icon
                sourceSize.width: 18
                sourceSize.height: 18
                smooth: true
                fillMode: Image.PreserveAspectFit
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => {
                    if (mouse.button === Qt.MiddleButton)
                        item.modelData.secondaryActivate();
                    else
                        item.modelData.activate();
                }
            }
        }
    }
}
