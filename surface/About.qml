// About box (bar right-click menu → About).
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../theme"
import "../state"

FloatingWindow {
    id: about

    title: "About hyprtk-bar-qt"
    visible: UiState.aboutOpen
    implicitWidth: 440
    implicitHeight: 320
    color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, Math.max(0.96, Theme.opacity))

    property real reveal: 0
    Behavior on reveal { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
    onVisibleChanged: reveal = visible ? 1 : 0

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 8
        opacity: about.reveal

        Text { text: "HYPRTK"; color: Theme.accent; font.bold: true; font.pixelSize: 22; Layout.alignment: Qt.AlignHCenter }
        Text { text: "hyprtk-bar-qt  \u00b7  Qt/QML rewrite"; color: Theme.foreground; font.pixelSize: 13; Layout.alignment: Qt.AlignHCenter }
        Text {
            Layout.fillWidth: true
            Layout.topMargin: 8
            text: "A modern, pywal-themed taskbar for the Hyprland desktop — the Qt counterpart to the GTK4 hyprtk-bar (QML presentation + a toolkit-free Python backend)."
            color: Theme.dim
            font.pixelSize: 12
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
        }
        Text { text: "github.com/hyprtk"; color: Theme.accent2; font.pixelSize: 12; Layout.alignment: Qt.AlignHCenter }
        Item { Layout.fillHeight: true }
        RowLayout {
            Layout.fillWidth: true
            Item { Layout.fillWidth: true }
            Rectangle {
                implicitWidth: 80; implicitHeight: 30; radius: 8
                color: hover.hovered ? Theme.alpha(Theme.accent2, 0.28) : Theme.alpha(Theme.accent2, 0.14)
                border.width: 1; border.color: Theme.alpha(Theme.accent2, 0.35)
                Text { anchors.centerIn: parent; text: "Close"; color: Theme.foreground; font.pixelSize: 12 }
                HoverHandler { id: hover }
                TapHandler { onTapped: UiState.aboutOpen = false }
            }
        }
    }
}
