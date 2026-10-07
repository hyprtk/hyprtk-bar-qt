// Themer window (v1): the live palette, a bar-opacity control, and shortcuts
// to the hyprtk theming scripts. Full page set (Wallpaper / Pywal / Rofi / Bar
// themes / Matuwall / Swaylock / Icons / SDDM & GRUB) is a later pass.
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell
import "../theme"
import "../config"
import "../state"

FloatingWindow {
    id: win

    title: "hyprtk-bar-qt themer"
    visible: UiState.themerOpen
    implicitWidth: 540
    implicitHeight: 440
    color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, Theme.opacity)

    readonly property var swatchNames: ["bg", "fg", "accent", "accent2", "dim", "err", "warn"]

    function col(name) {
        switch (name) {
        case "bg": return Theme.background;
        case "fg": return Theme.foreground;
        case "accent": return Theme.accent;
        case "accent2": return Theme.accent2;
        case "dim": return Theme.dim;
        case "err": return Theme.err;
        case "warn": return Theme.warn;
        }
        return Theme.foreground;
    }

    readonly property string scripts: (Quickshell.env("HOME") || "") + "/.local/share/hyprtk-bar/scripts"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 14

        Text {
            text: "Themer"
            color: Theme.accent
            font.bold: true
            font.pixelSize: 16
        }

        RowLayout {
            Layout.fillWidth: true
            Text { text: "Active theme"; color: Theme.dim; Layout.fillWidth: true }
            Text {
                text: Theme.themeName.length > 0 ? Theme.themeName : "(pywal)"
                color: Theme.foreground
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Repeater {
                model: win.swatchNames
                delegate: Rectangle {
                    required property string modelData
                    width: 40
                    height: 40
                    radius: 8
                    color: win.col(modelData)
                    border.color: Theme.alpha(Theme.foreground, 0.3)
                    border.width: 1
                }
            }
            Item { Layout.fillWidth: true }
        }

        RowLayout {
            Layout.fillWidth: true
            Text { text: "Bar opacity"; color: Theme.foreground; Layout.fillWidth: true }
            Slider {
                id: op
                Layout.preferredWidth: 220
                from: 0.2
                to: 1.0
                stepSize: 0.01
                value: Config.opacity >= 0 ? Config.opacity : Theme.opacity
                onMoved: Config.opacity = value
            }
            Text {
                text: Math.round((Config.opacity >= 0 ? Config.opacity : Theme.opacity) * 100) + "%"
                color: Theme.foreground
                Layout.preferredWidth: 42
            }
        }

        Text {
            text: "qt opacity override (" + (Config.opacity >= 0 ? "set" : "following hyprtk-bar") + ")"
            color: Theme.dim
            font.pixelSize: 10
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Button {
                text: "Regenerate palette"
                onClicked: Quickshell.execDetached(["sh", "-c",
                    "~/.local/share/hyprtk-bar/scripts/updatewal-awww.sh 2>/dev/null || true"])
            }
            Button {
                text: "Save"
                onClicked: Config.save()
            }
            Item { Layout.fillWidth: true }
            Button {
                text: "Close"
                onClicked: UiState.themerOpen = false
            }
        }
    }
}
