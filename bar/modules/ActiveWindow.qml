// Active-window module: the focused toplevel's title.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../../theme"

Text {
    id: root

    readonly property var toplevel: Hyprland.activeToplevel
    text: root.toplevel ? (root.toplevel.title || "") : ""
    visible: text.length > 0
    color: Theme.foreground
    font.pixelSize: 12
    elide: Text.ElideRight
    Layout.preferredWidth: Math.min(implicitWidth, 260)
}
