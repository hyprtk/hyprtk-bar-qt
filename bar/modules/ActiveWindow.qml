// Active-window module: the focused toplevel's title (length-capped).
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../../theme"
import "../../data"

Text {
    id: root

    readonly property var toplevel: Hyprland.activeToplevel
    readonly property int maxLength: BarConfig.windowBlock.max_length || 40
    readonly property string full: root.toplevel ? (root.toplevel.title || "") : ""

    text: root.full.length > root.maxLength
        ? root.full.slice(0, root.maxLength - 1) + "\u2026"
        : root.full
    visible: text.length > 0
    color: Theme.foreground
    font.pixelSize: BarConfig.fontSize(Theme.fontSize)
    elide: Text.ElideRight
    Layout.preferredWidth: Math.min(implicitWidth, (BarConfig.windowBlock.width || 220))
}
