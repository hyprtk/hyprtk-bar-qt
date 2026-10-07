// Settings window — nine pages (Bar / Themes / Fonts / Animations / Arc Menu /
// Menu / Quicklinks / Modules / Widgets) editing config/Config.qml.
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell
import "../theme"
import "../config"
import "../state"

FloatingWindow {
    id: win

    title: "hyprtk-bar-qt settings"
    visible: UiState.settingsOpen
    implicitWidth: 760
    implicitHeight: 560
    color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, Math.max(0.95, Theme.opacity))

    property int page: 0
    readonly property var pageNames: ["Bar", "Themes", "Fonts", "Animations", "Arc Menu", "Menu", "Quicklinks", "Modules", "Widgets"]
    readonly property var moduleNames: [
        "start_button", "quicklinks", "workspaces", "tasklist", "window", "updates",
        "net", "tray", "kbstate", "notifications", "clock", "sysmon",
        "arcmenu", "themer", "settings", "quicksettings"
    ]
    readonly property var arcPositions: ["top-left", "top-center", "top-right", "bottom-left", "bottom-center", "bottom-right"]

    function idx(list, v) {
        const i = list.indexOf(v);
        return i < 0 ? 0 : i;
    }
    function inList(list, name) {
        return (list || []).indexOf(name) >= 0;
    }
    function setSide(name, side, on) {
        let L = Config.layoutLeft.filter(x => x !== name);
        let R = Config.layoutRight.filter(x => x !== name);
        if (on) {
            if (side === "left")
                L.push(name);
            else
                R.push(name);
        }
        Config.layoutLeft = L;
        Config.layoutRight = R;
    }
    function setLink(i, field, value) {
        const arr = Config.quicklinksLinks.slice();
        arr[i] = Object.assign({}, arr[i]);
        arr[i][field] = value;
        Config.quicklinksLinks = arr;
    }
    function addLink() {
        Config.quicklinksLinks = Config.quicklinksLinks.concat([{ glyph: "\uf013", command: "" }]);
    }
    function removeLink(i) {
        const arr = Config.quicklinksLinks.slice();
        arr.splice(i, 1);
        Config.quicklinksLinks = arr;
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ── sidebar ────────────────────────────────────────────────────
        Rectangle {
            Layout.fillHeight: true
            implicitWidth: 150
            color: Theme.alpha(Theme.background, 0.6)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 4

                Repeater {
                    model: win.pageNames

                    delegate: Rectangle {
                        required property string modelData
                        required property int index
                        Layout.fillWidth: true
                        implicitHeight: 32
                        radius: 8
                        color: win.page === index
                            ? Theme.alpha(Theme.accent, 0.85)
                            : (sbHover.hovered ? Theme.alpha(Theme.accent2, 0.15) : "transparent")

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            text: modelData
                            color: win.page === index ? "#000000" : Theme.foreground
                            font.pixelSize: 12
                        }
                        HoverHandler { id: sbHover }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: win.page = index
                        }
                    }
                }
                Item { Layout.fillHeight: true }
            }
        }

        // ── content ────────────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 16
            spacing: 12

            StackLayout {
                id: stack
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: win.page

                // Bar
                ColumnLayout {
                    spacing: 10
                    RowLayout {
                        Text { text: "Position"; color: Theme.foreground; Layout.fillWidth: true }
                        ComboBox {
                            model: ["top", "bottom"]
                            currentIndex: win.idx(["top", "bottom"], Config.barPosition)
                            onActivated: Config.barPosition = model[currentIndex]
                        }
                    }
                    RowLayout {
                        Text { text: "Height"; color: Theme.foreground; Layout.fillWidth: true }
                        SpinBox { from: 24; to: 64; value: Config.barHeight; onValueChanged: Config.barHeight = value }
                    }
                    RowLayout {
                        Text { text: "Gap (edge)"; color: Theme.foreground; Layout.fillWidth: true }
                        SpinBox { from: 0; to: 40; value: Config.gapOut; onValueChanged: Config.gapOut = value }
                    }
                    RowLayout {
                        Text { text: "Gap (windows)"; color: Theme.foreground; Layout.fillWidth: true }
                        SpinBox { from: 0; to: 40; value: Config.gapIn; onValueChanged: Config.gapIn = value }
                    }
                    RowLayout {
                        Text { text: "Corner radius"; color: Theme.foreground; Layout.fillWidth: true }
                        SpinBox { from: 0; to: 30; value: Config.radius; onValueChanged: Config.radius = value }
                    }
                    RowLayout {
                        Text { text: "Width"; color: Theme.foreground; Layout.fillWidth: true }
                        TextField { Layout.preferredWidth: 120; text: Config.barWidth; onEditingFinished: Config.barWidth = text }
                    }
                    RowLayout {
                        Text { text: "Align"; color: Theme.foreground; Layout.fillWidth: true }
                        ComboBox {
                            model: ["left", "center", "right"]
                            currentIndex: win.idx(["left", "center", "right"], Config.barAlign)
                            onActivated: Config.barAlign = model[currentIndex]
                        }
                    }
                    RowLayout {
                        Text { text: "Opacity"; color: Theme.foreground; Layout.fillWidth: true }
                        Slider {
                            Layout.preferredWidth: 200
                            from: 0.2; to: 1.0; stepSize: 0.01
                            value: Config.opacity >= 0 ? Config.opacity : Theme.opacity
                            onMoved: Config.opacity = value
                        }
                        Text { text: Math.round((Config.opacity >= 0 ? Config.opacity : Theme.opacity) * 100) + "%"; color: Theme.dim }
                    }
                    Item { Layout.fillHeight: true }
                }

                // Themes
                ColumnLayout {
                    spacing: 10
                    Text { text: "Overrides (blank = follow hyprtk-bar / pywal)"; color: Theme.dim; font.pixelSize: 11 }
                    RowLayout {
                        Text { text: "Source"; color: Theme.foreground; Layout.fillWidth: true }
                        ComboBox {
                            model: ["", "pywal", "manual"]
                            currentIndex: win.idx(["", "pywal", "manual"], Config.themeSource)
                            onActivated: Config.themeSource = model[currentIndex]
                        }
                    }
                    RowLayout {
                        Text { text: "Theme name"; color: Theme.foreground; Layout.fillWidth: true }
                        TextField { Layout.preferredWidth: 220; text: Config.themeName; onEditingFinished: Config.themeName = text }
                    }
                    RowLayout {
                        Text { text: "Background"; color: Theme.foreground; Layout.fillWidth: true }
                        TextField { Layout.preferredWidth: 220; placeholderText: "#1e1e2e"; text: Config.themeBackground; onEditingFinished: Config.themeBackground = text }
                    }
                    RowLayout {
                        Text { text: "Foreground"; color: Theme.foreground; Layout.fillWidth: true }
                        TextField { Layout.preferredWidth: 220; placeholderText: "#e5e7eb"; text: Config.themeForeground; onEditingFinished: Config.themeForeground = text }
                    }
                    RowLayout {
                        Text { text: "Accent"; color: Theme.foreground; Layout.fillWidth: true }
                        TextField { Layout.preferredWidth: 220; placeholderText: "#c084fc"; text: Config.themeAccent; onEditingFinished: Config.themeAccent = text }
                    }
                    RowLayout {
                        spacing: 8
                        Repeater {
                            model: win.swatchList()
                            delegate: Rectangle {
                                required property var modelData
                                width: 32; height: 32; radius: 6
                                color: modelData.c
                                border.color: Theme.alpha(Theme.foreground, 0.3); border.width: 1
                            }
                        }
                        Item { Layout.fillWidth: true }
                    }
                    Item { Layout.fillHeight: true }
                }

                // Fonts
                ColumnLayout {
                    spacing: 10
                    RowLayout {
                        Text { text: "Font family"; color: Theme.foreground; Layout.fillWidth: true }
                        TextField { Layout.preferredWidth: 220; text: Config.fontFamily; onEditingFinished: Config.fontFamily = text }
                    }
                    RowLayout {
                        Text { text: "Font size"; color: Theme.foreground; Layout.fillWidth: true }
                        SpinBox { from: 8; to: 20; value: Config.fontSize; onValueChanged: Config.fontSize = value }
                    }
                    Text { text: "Applies to modules that read Theme.fontFamily/fontSize."; color: Theme.dim; font.pixelSize: 10; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                    Item { Layout.fillHeight: true }
                }

                // Animations
                ColumnLayout {
                    spacing: 10
                    RowLayout {
                        Text { text: "Enable animations"; color: Theme.foreground; Layout.fillWidth: true }
                        CheckBox { checked: Config.animations; onToggled: Config.animations = checked }
                    }
                    RowLayout {
                        Text { text: "Duration (ms)"; color: Theme.foreground; Layout.fillWidth: true }
                        SpinBox { from: 0; to: 1000; stepSize: 10; value: Config.animationDuration; onValueChanged: Config.animationDuration = value }
                    }
                    Item { Layout.fillHeight: true }
                }

                // Arc Menu
                ColumnLayout {
                    spacing: 10
                    RowLayout {
                        Text { text: "Position"; color: Theme.foreground; Layout.fillWidth: true }
                        ComboBox {
                            model: win.arcPositions
                            currentIndex: win.idx(win.arcPositions, Config.arcMenuPosition)
                            onActivated: Config.arcMenuPosition = model[currentIndex]
                        }
                    }
                    Text { text: "Items (" + Config.arcMenuItems.length + ")"; color: Theme.dim; font.pixelSize: 11 }
                    Repeater {
                        model: Config.arcMenuItems
                        delegate: RowLayout {
                            required property var modelData
                            Text { text: (modelData.glyph || "?") + "  " + (modelData.tooltip || modelData.command || modelData.action || ""); color: Theme.foreground; font.pixelSize: 11 }
                            Item { Layout.fillWidth: true }
                        }
                    }
                    Text { text: "Item editing is a later pass."; color: Theme.dim; font.pixelSize: 10 }
                    Item { Layout.fillHeight: true }
                }

                // Menu
                ColumnLayout {
                    spacing: 10
                    RowLayout {
                        Text { text: "Start-menu layout"; color: Theme.foreground; Layout.fillWidth: true }
                        ComboBox {
                            model: ["whisker", "win7", "win11", "plasma"]
                            currentIndex: win.idx(["whisker", "win7", "win11", "plasma"], Config.menuLayout)
                            onActivated: Config.menuLayout = model[currentIndex]
                        }
                    }
                    Text { text: "Layout variants are a later pass (v1 grid is used for all)."; color: Theme.dim; font.pixelSize: 10 }
                    Repeater {
                        model: ["lock", "logout", "reboot", "shutdown", "suspend"]
                        delegate: RowLayout {
                            required property string modelData
                            Text { text: modelData; color: Theme.foreground; Layout.preferredWidth: 90 }
                            TextField {
                                Layout.fillWidth: true
                                text: Config.menuPower[modelData] || ""
                                onEditingFinished: {
                                    const mp = Object.assign({}, Config.menuPower);
                                    mp[modelData] = text;
                                    Config.menuPower = mp;
                                }
                            }
                        }
                    }
                    Item { Layout.fillHeight: true }
                }

                // Quicklinks
                ColumnLayout {
                    spacing: 8
                    Repeater {
                        model: Config.quicklinksLinks
                        delegate: RowLayout {
                            required property var modelData
                            required property int index
                            TextField {
                                Layout.preferredWidth: 40
                                text: modelData.glyph || ""
                                onEditingFinished: win.setLink(index, "glyph", text)
                            }
                            TextField {
                                Layout.fillWidth: true
                                placeholderText: "command"
                                text: modelData.command || ""
                                onEditingFinished: win.setLink(index, "command", text)
                            }
                            TextField {
                                Layout.preferredWidth: 160
                                placeholderText: "alt (r/m-click)"
                                text: modelData.alt || ""
                                onEditingFinished: win.setLink(index, "alt", text)
                            }
                            Button { text: "\u2715"; onClicked: win.removeLink(index) }
                        }
                    }
                    RowLayout {
                        Button { text: "Add link"; onClicked: win.addLink() }
                        Item { Layout.fillWidth: true }
                    }
                    Item { Layout.fillHeight: true }
                }

                // Modules (placement editor)
                ColumnLayout {
                    spacing: 6
                    Text { text: "Place modules on the left or right of the bar."; color: Theme.dim; font.pixelSize: 11 }
                    Repeater {
                        model: win.moduleNames
                        delegate: RowLayout {
                            required property string modelData
                            Text { text: modelData; color: Theme.foreground; Layout.preferredWidth: 140 }
                            CheckBox {
                                text: "Left"
                                checked: win.inList(Config.layoutLeft, modelData)
                                onToggled: win.setSide(modelData, "left", checked)
                            }
                            CheckBox {
                                text: "Right"
                                checked: win.inList(Config.layoutRight, modelData)
                                onToggled: win.setSide(modelData, "right", checked)
                            }
                            Item { Layout.fillWidth: true }
                        }
                    }
                    Item { Layout.fillHeight: true }
                }

                // Widgets
                ColumnLayout {
                    spacing: 10
                    Text { text: "Desktop widgets"; color: Theme.accent; font.bold: true }
                    Text { text: "clock \u00b7 weather \u00b7 visualizer \u00b7 disk \u00b7 network \u00b7 resources \u00b7 sysinfo"; color: Theme.dim; font.pixelSize: 11; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                    Text { text: "Not yet implemented in the Qt rewrite (see PARITY.md)."; color: Theme.warn; font.pixelSize: 11 }
                    Item { Layout.fillHeight: true }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Text { text: "Settings write ~/.config/hyprtk-bar-qt/config.json"; color: Theme.dim; font.pixelSize: 10; Layout.fillWidth: true }
                Button { text: "Save"; onClicked: Config.save() }
                Button { text: "Close"; onClicked: UiState.settingsOpen = false }
            }
        }
    }

    function swatchList() {
        return [
            { c: Theme.background }, { c: Theme.foreground }, { c: Theme.accent },
            { c: Theme.accent2 }, { c: Theme.dim }, { c: Theme.err }, { c: Theme.warn }
        ];
    }
}
