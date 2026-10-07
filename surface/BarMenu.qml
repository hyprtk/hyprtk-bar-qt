// Right-click context menu for the bar.
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../theme"
import "../config"
import "../state"

PanelWindow {
    id: menu

    anchors.top: true
    anchors.left: true
    margins.top: Config.barHeight + 6
    margins.left: Math.max(4, UiState.barMenuX)
    implicitWidth: 224
    implicitHeight: col.implicitHeight + 16
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    focusable: true
    visible: UiState.barMenuOpen

    readonly property var entries: [
        { glyph: "\uf009", label: "Start Menu", act: "start" },
        { glyph: "\uf013", label: "Settings", act: "settings" },
        { glyph: "\uf1fc", label: "Themer", act: "themer" },
        { glyph: "\u2261", label: "Quick Settings", act: "qs" },
        { glyph: "\u229e", label: "Arc Menu", act: "arc" },
        { glyph: "\uf021", label: "Reload", act: "reload" },
        { glyph: "\uf023", label: "Lock", act: "lock" }
    ]

    function dispatch(action) {
        UiState.barMenuOpen = false;
        switch (action) {
        case "start":
            UiState.startMenuOpen = true;
            break;
        case "settings":
            UiState.settingsOpen = true;
            break;
        case "themer":
            UiState.themerOpen = true;
            break;
        case "qs":
            UiState.quickSettingsOpen = true;
            break;
        case "arc":
            UiState.arcMenuOpen = true;
            break;
        case "reload":
            Quickshell.reload(true);
            break;
        case "lock":
            Quickshell.execDetached(["sh", "-c", Config.menuPower.lock]);
            break;
        }
    }

    property real reveal: 0
    readonly property int animMs: Config.animations ? Config.animationDuration : 0
    Behavior on reveal { NumberAnimation { duration: menu.animMs; easing.type: Easing.OutCubic } }
    onVisibleChanged: reveal = visible ? 1 : 0

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, Theme.opacity)
        border.color: Theme.alpha(Theme.accent2, 0.3)
        border.width: 1
        opacity: menu.reveal
        transform: Translate { y: (1 - menu.reveal) * -8 }

        ColumnLayout {
            id: col
            anchors.fill: parent
            anchors.margins: 8
            spacing: 2

            Repeater {
                model: menu.entries

                delegate: Rectangle {
                    id: row
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 30
                    radius: 6
                    color: hover.hovered ? Theme.alpha(Theme.accent2, 0.18) : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 10
                        Text {
                            text: row.modelData.glyph
                            color: Theme.accent
                            font.pixelSize: 13
                        }
                        Text {
                            text: row.modelData.label
                            color: Theme.foreground
                            font.pixelSize: 12
                            Layout.fillWidth: true
                        }
                    }

                    HoverHandler { id: hover }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: menu.dispatch(row.modelData.act)
                    }
                }
            }
        }
    }
}
