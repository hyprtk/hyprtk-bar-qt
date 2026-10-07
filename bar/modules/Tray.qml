// System tray (SNI host), via Quickshell's StatusNotifier + DBusMenu services.
//
// Left-click activates, middle-click secondary-activates, right-click opens the
// item's DBusMenu context menu through QsMenuAnchor (items with onlyMenu open
// the menu on left-click too).
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import "../../theme"
import "../../data"

RowLayout {
    id: root
    spacing: 6

    readonly property int iconSize: BarConfig.tray.icon_size || 18

    Repeater {
        model: SystemTray.items

        delegate: Item {
            id: item
            required property var modelData

            implicitWidth: root.iconSize
            implicitHeight: root.iconSize

            // Window attached property is only valid on Item-derived types, so
            // resolve it here and hand it to the (QtObject) menu anchor.
            readonly property var barWindow: QsWindow.window

            Image {
                anchors.fill: parent
                source: item.modelData.icon
                sourceSize.width: root.iconSize
                sourceSize.height: root.iconSize
                smooth: true
                fillMode: Image.PreserveAspectFit
            }

            QsMenuAnchor {
                id: menuAnchor
                menu: item.modelData.menu
                anchor.window: item.barWindow
                anchor.item: item
                anchor.rect: Qt.rect(0, item.height, item.width, 1)
                anchor.edges: Edges.Bottom
                anchor.gravity: Edges.Bottom
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => {
                    if (mouse.button === Qt.MiddleButton) {
                        item.modelData.secondaryActivate();
                    } else if (mouse.button === Qt.RightButton) {
                        if (item.modelData.hasMenu)
                            menuAnchor.open();
                    } else if (item.modelData.onlyMenu) {
                        if (item.modelData.hasMenu)
                            menuAnchor.open();
                        else
                            item.modelData.activate();
                    } else {
                        item.modelData.activate();
                    }
                }
            }
        }
    }
}
