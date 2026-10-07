// Themer window: the live palette, the 9 shipped bar themes, a bar-opacity
// control, and shortcuts to the hyprtk theming scripts.
//
// Selecting a shipped theme writes explicit Theme overrides (background /
// foreground / accent); "Follow pywal" clears them. Rofi/Swaylock/Icons/
// SDDM-GRUB pages are a later pass.
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Io
import "../theme"
import "../config"
import "../state"

FloatingWindow {
    id: win

    title: "hyprtk-bar-qt themer"
    visible: UiState.themerOpen
    implicitWidth: 560
    implicitHeight: 600
    color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, Theme.opacity)

    readonly property string backend:
        Qt.resolvedUrl("../backend/hyprtk_bar_qt/themes.py").toString().replace("file://", "")
    readonly property var swatchNames: ["bg", "fg", "accent", "accent2", "dim", "err", "warn"]

    property var themes: []

    onVisibleChanged: if (visible && !listProc.running) listProc.running = true

    Process {
        id: listProc
        command: ["python3", win.backend, "list"]
        stdout: SplitParser {
            onRead: line => {
                try {
                    win.themes = JSON.parse(line).themes || [];
                } catch (e) {
                    win.themes = [];
                }
            }
        }
    }

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

    function applyTheme(t) {
        Config.themeSource = "manual";
        Config.themeName = t.name;
        Config.themeBackground = t.palette.background;
        Config.themeForeground = t.palette.foreground;
        Config.themeAccent = t.palette.accent;
    }
    function clearOverrides() {
        Config.themeSource = "";
        Config.themeName = "";
        Config.themeBackground = "";
        Config.themeForeground = "";
        Config.themeAccent = "";
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            Text { text: "Themer"; color: Theme.accent; font.bold: true; font.pixelSize: 16; Layout.fillWidth: true }
            Text { text: "\u00d7"; color: Theme.dim; font.pixelSize: 18; MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: UiState.themerOpen = false } }
        }

        RowLayout {
            Layout.fillWidth: true
            Text { text: "Active theme"; color: Theme.dim; Layout.fillWidth: true }
            Text { text: Theme.themeName.length > 0 ? Theme.themeName : "(pywal)"; color: Theme.foreground }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Repeater {
                model: win.swatchNames
                delegate: Rectangle {
                    required property string modelData
                    width: 34
                    height: 34
                    radius: 8
                    color: win.col(modelData)
                    border.color: Theme.alpha(Theme.foreground, 0.3)
                    border.width: 1
                }
            }
            Item { Layout.fillWidth: true }
        }

        Text { text: "Bar themes"; color: Theme.accent; font.bold: true; font.pixelSize: 13 }

        Flickable {
            Layout.fillWidth: true
            Layout.preferredHeight: 168
            contentHeight: themeList.implicitHeight
            clip: true
            ColumnLayout {
                id: themeList
                width: parent.width
                spacing: 3
                Repeater {
                    model: win.themes
                    delegate: Rectangle {
                        id: tr
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: 30
                        radius: 6
                        color: trHover.hovered ? Theme.alpha(Theme.accent2, 0.15)
                            : (Theme.themeName === tr.modelData.name ? Theme.alpha(Theme.accent, 0.25) : "transparent")
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8
                            Text { text: tr.modelData.name; color: Theme.foreground; font.pixelSize: 12; Layout.fillWidth: true }
                            Repeater {
                                model: [tr.modelData.palette.background, tr.modelData.palette.foreground, tr.modelData.palette.accent]
                                delegate: Rectangle {
                                    required property var modelData
                                    width: 16
                                    height: 16
                                    radius: 4
                                    color: modelData
                                    border.color: Theme.alpha(Theme.foreground, 0.25)
                                    border.width: 1
                                }
                            }
                        }
                        HoverHandler { id: trHover }
                        TapHandler { onTapped: win.applyTheme(tr.modelData) }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Button { text: "Follow hyprtk-bar / pywal"; onClicked: win.clearOverrides() }
            Item { Layout.fillWidth: true }
        }

        RowLayout {
            Layout.fillWidth: true
            Text { text: "Bar opacity"; color: Theme.foreground; Layout.fillWidth: true }
            Slider {
                id: op
                Layout.preferredWidth: 200
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

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Button {
                text: "Regenerate palette"
                onClicked: Quickshell.execDetached(["sh", "-c",
                    "~/.local/share/hyprtk-bar/scripts/updatewal-awww.sh 2>/dev/null || true"])
            }
            Button { text: "Save"; onClicked: Config.save() }
            Item { Layout.fillWidth: true }
            Button { text: "Close"; onClicked: UiState.themerOpen = false }
        }
    }
}
