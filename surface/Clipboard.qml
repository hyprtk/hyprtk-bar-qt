// In-bar clipboard history (cliphist), replacing the old cliphist + rofi flow.
//
// Lists the history, copies an entry on click (text or image), deletes a single
// entry, and wipes the history. Toggle from the clipboard quicklink or:
//   qs ipc call clipboard toggle
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Io
import "../theme"
import "../config"
import "../state"
import "../components"

PanelWindow {
    id: clip

    readonly property string backend:
        Qt.resolvedUrl("../backend/hyprtk_bar_qt/clipboard.py").toString().replace("file://", "")

    visible: UiState.clipboardOpen
    color: "transparent"
    focusable: true
    exclusionMode: ExclusionMode.Ignore

    anchors.top: Config.barPosition === "top"
    anchors.bottom: Config.barPosition === "bottom"
    margins.top: Config.barPosition === "top" ? Config.barHeight + Config.gapOut + 6 : 0
    margins.bottom: Config.barPosition === "bottom" ? Config.barHeight + Config.gapOut + 6 : 0
    implicitWidth: 420
    implicitHeight: 480

    property var entries: []
    property string query: ""
    property bool clearArmed: false

    function filtered() {
        const q = clip.query.trim().toLowerCase();
        if (!q)
            return clip.entries;
        return clip.entries.filter(e => (e.info || "").toLowerCase().includes(q));
    }

    function reload() {
        if (!listProc.running)
            listProc.running = true;
    }

    property real reveal: 0
    readonly property int animMs: Config.animations ? Config.animationDuration : 0
    Behavior on reveal { NumberAnimation { duration: clip.animMs; easing.type: Easing.OutCubic } }

    onVisibleChanged: {
        clip.reveal = visible ? 1 : 0;
        if (visible) {
            clip.query = "";
            clip.clearArmed = false;
            clip.reload();
            search.forceActiveFocus();
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: clip.visible
        onActivated: UiState.clipboardOpen = false
    }

    IpcHandler {
        target: "clipboard"
        function toggle() { UiState.clipboardOpen = !UiState.clipboardOpen; }
        function open() { UiState.clipboardOpen = true; }
        function close() { UiState.clipboardOpen = false; }
    }

    Process {
        id: listProc
        command: ["python3", clip.backend, "list"]
        stdout: SplitParser {
            onRead: line => {
                try {
                    clip.entries = (JSON.parse(line).entries) || [];
                } catch (e) {
                    clip.entries = [];
                }
            }
        }
    }
    Process {
        id: copyProc
        onExited: (code, status) => {
            if (code === 0)
                UiState.clipboardOpen = false;
        }
    }
    Process {
        id: mutProc
        onExited: (code, status) => clip.reload()
    }

    function doCopy(entry) {
        const args = ["python3", clip.backend, "copy", String(entry.id)];
        if (entry.image)
            args.push("--image", entry.image);
        copyProc.command = args;
        copyProc.running = true;
    }
    function doDelete(entry) {
        mutProc.command = ["python3", clip.backend, "delete", String(entry.id)];
        mutProc.running = true;
    }
    function doWipe() {
        mutProc.command = ["python3", clip.backend, "wipe"];
        mutProc.running = true;
    }

    Timer {
        id: clearReset
        interval: 3000
        onTriggered: clip.clearArmed = false
    }

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, Math.max(0.96, Theme.opacity))
        border.width: 1
        border.color: Theme.alpha(Theme.accent2, 0.2)
        opacity: clip.reveal
        transform: Translate { y: (1 - clip.reveal) * -8 }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                Text { text: "Clipboard"; color: Theme.accent; font.bold: true; font.pixelSize: 15; Layout.fillWidth: true }
                Rectangle {
                    implicitWidth: clearText.implicitWidth + 18
                    implicitHeight: 26
                    radius: 6
                    color: clip.clearArmed ? Theme.alpha(Theme.err, 0.5)
                        : (clearHover.hovered ? Theme.alpha(Theme.accent2, 0.25) : Theme.alpha(Theme.accent2, 0.12))
                    Text { id: clearText; anchors.centerIn: parent; text: clip.clearArmed ? "Confirm?" : "Clear all"; color: Theme.foreground; font.pixelSize: 11 }
                    HoverHandler { id: clearHover }
                    TapHandler {
                        onTapped: {
                            if (!clip.clearArmed) {
                                clip.clearArmed = true;
                                clearReset.restart();
                            } else {
                                clearReset.stop();
                                clip.clearArmed = false;
                                clip.doWipe();
                            }
                        }
                    }
                }
                Text {
                    text: "\u00d7"
                    color: Theme.dim
                    font.pixelSize: 18
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: UiState.clipboardOpen = false
                    }
                }
            }

            TTextField {
                id: search
                Layout.fillWidth: true
                placeholderText: "Search history\u2026"
                color: Theme.foreground
                onTextChanged: clip.query = text
            }

            Text {
                Layout.fillWidth: true
                visible: clip.filtered().length === 0
                text: clip.entries.length === 0 ? "Clipboard is empty" : "No matches"
                color: Theme.dim
                font.pixelSize: 12
                topPadding: 12
            }

            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: list.implicitHeight
                clip: true
                visible: clip.filtered().length > 0
                ColumnLayout {
                    id: list
                    width: parent.width
                    spacing: 2
                    Repeater {
                        model: clip.filtered()
                        delegate: Rectangle {
                            id: row
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: 28
                            radius: 6
                            color: rowHover.hovered ? Theme.alpha(Theme.accent2, 0.15) : "transparent"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 4
                                spacing: 8
                                Text {
                                    text: row.modelData.info || ""
                                    color: row.modelData.image ? Theme.warn : Theme.foreground
                                    font.pixelSize: 11
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                                Text {
                                    text: "\u2715"
                                    color: Theme.dim
                                    font.pixelSize: 12
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: clip.doDelete(row.modelData)
                                    }
                                }
                            }

                            HoverHandler { id: rowHover }
                            TapHandler {
                                onTapped: clip.doCopy(row.modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}
