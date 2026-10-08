// Small rounded icon button used by the bar's action modules.
import QtQuick
import "../theme"
import "../data"

Rectangle {
    id: btn

    property string glyph: ""
    property bool active: false
    signal activated()

    implicitWidth: 22
    implicitHeight: 22
    radius: 6
    color: btn.active ? Theme.accent : Theme.alpha(Theme.accent2, 0.12)

    Text {
        anchors.centerIn: parent
        text: btn.glyph
        color: btn.active ? "#000000" : Theme.foreground
        font.family: BarConfig.glyphFont
        font.pixelSize: 13
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.activated()
    }
}
