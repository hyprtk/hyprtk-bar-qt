// Quick settings flyout: volume, brightness, Wi-Fi, Bluetooth + shortcuts.
//
// State is read/set with the same session tools the GTK bar used — wpctl
// (WirePlumber), brightnessctl, nmcli and bluetoothctl — via Quickshell Process.
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
    id: qs

    anchors.top: true
    anchors.right: true
    margins.top: 46
    margins.right: 8
    implicitWidth: 340
    implicitHeight: panel.implicitHeight + 28
    color: "transparent"
    focusable: true
    exclusionMode: ExclusionMode.Ignore
    visible: UiState.quickSettingsOpen

    // Reveal animation (gated by the shared animations switch).
    property real reveal: 0
    readonly property int animMs: Config.animations ? Config.animationDuration : 0
    Behavior on reveal { NumberAnimation { duration: qs.animMs; easing.type: Easing.OutCubic } }
    onVisibleChanged: {
        reveal = visible ? 1 : 0;
        if (visible)
            refresh();
    }

    property int volume: 0
    property bool muted: false
    property int brightness: 0
    property bool wifiOn: false
    property bool btOn: false

    function refresh() {
        volGet.running = true;
        brightGet.running = true;
        wifiGet.running = true;
        btGet.running = true;
    }
    // ── readers ────────────────────────────────────────────────────────
    Process {
        id: volGet
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: SplitParser {
            onRead: line => {
                const m = line.match(/([0-9.]+)/);
                if (m)
                    qs.volume = Math.round(parseFloat(m[1]) * 100);
                qs.muted = /MUTED/.test(line);
            }
        }
    }
    Process {
        id: brightGet
        command: ["brightnessctl", "-m"]
        stdout: SplitParser {
            onRead: line => {
                const m = line.match(/([0-9]+)%/);
                if (m)
                    qs.brightness = parseInt(m[1]);
            }
        }
    }
    Process {
        id: wifiGet
        command: ["nmcli", "radio", "wifi"]
        stdout: SplitParser {
            onRead: line => { qs.wifiOn = line.trim() === "enabled"; }
        }
    }
    Process {
        id: btGet
        command: ["bluetoothctl", "show"]
        stdout: SplitParser {
            onRead: line => {
                if (/Powered:\s+yes/.test(line))
                    qs.btOn = true;
                else if (/Powered:\s+no/.test(line))
                    qs.btOn = false;
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, Theme.opacity)
        opacity: qs.reveal
        transform: Translate { y: (1 - qs.reveal) * -8 }

        ColumnLayout {
            id: panel
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Quick Settings"
                    color: Theme.accent
                    font.bold: true
                    font.pixelSize: 15
                    Layout.fillWidth: true
                }
                Text {
                    text: "\u00d7"
                    color: Theme.dim
                    font.pixelSize: 16
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: UiState.quickSettingsOpen = false
                    }
                }
            }

            // volume
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Text { text: qs.muted ? "\u2716" : "\u266b"; color: Theme.foreground; font.pixelSize: 15 }
                Slider {
                    id: vol
                    Layout.fillWidth: true
                    from: 0
                    to: 100
                    stepSize: 1
                    value: qs.volume
                    onMoved: Quickshell.execDetached(
                        ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (value / 100).toFixed(2)])
                }
                Text { text: qs.volume + "%"; color: Theme.foreground; font.pixelSize: 12; Layout.preferredWidth: 38 }
                Text {
                    text: qs.muted ? "unmute" : "mute"
                    color: Theme.accent2
                    font.pixelSize: 11
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]);
                            qs.refresh();
                        }
                    }
                }
            }

            // brightness
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Text { text: "\u263c"; color: Theme.warn; font.pixelSize: 15 }
                Slider {
                    Layout.fillWidth: true
                    from: 0
                    to: 100
                    stepSize: 1
                    value: qs.brightness
                    onMoved: Quickshell.execDetached(["brightnessctl", "set", Math.round(value) + "%"])
                }
                Text { text: qs.brightness + "%"; color: Theme.foreground; font.pixelSize: 12; Layout.preferredWidth: 38 }
            }

            // wifi
            RowLayout {
                Layout.fillWidth: true
                Text { text: "Wi-Fi"; color: Theme.foreground; Layout.fillWidth: true }
                Toggle {
                    checked: qs.wifiOn
                    onColor: Theme.accent
                    offColor: Theme.accent2
                    onToggled: (v) => {
                        Quickshell.execDetached(["nmcli", "radio", "wifi", v ? "on" : "off"]);
                        qs.wifiOn = v;
                    }
                }
            }

            // bluetooth
            RowLayout {
                Layout.fillWidth: true
                Text { text: "Bluetooth"; color: Theme.foreground; Layout.fillWidth: true }
                Toggle {
                    checked: qs.btOn
                    onColor: Theme.accent
                    offColor: Theme.accent2
                    onToggled: (v) => {
                        Quickshell.execDetached(["bluetoothctl", "power", v ? "on" : "off"]);
                        qs.btOn = v;
                    }
                }
            }

            // shortcuts
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Button {
                    text: "Settings"
                    onClicked: {
                        UiState.settingsOpen = true;
                        UiState.quickSettingsOpen = false;
                    }
                }
                Button {
                    text: "Lock"
                    onClicked: Quickshell.execDetached(["sh", "-c", "hyprlock || loginctl lock-session"])
                }
                Item { Layout.fillWidth: true }
            }
        }
    }
}
