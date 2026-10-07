// Package-update indicator: runs the hyprtk updates script periodically and
// shows the pending count, coloured by threshold. Click runs the installer.
import QtQuick
import Quickshell
import Quickshell.Io
import "../../theme"
import "../../data"

Text {
    id: root

    property int count: 0

    readonly property string home: Quickshell.env("HOME") || ""
    readonly property string script: BarConfig.updates.script || (root.home + "/.local/share/hyprtk-bar/scripts/updates.sh")
    readonly property string install: BarConfig.updates.install_command || (root.home + "/.local/share/hyprtk-bar/scripts/installupdates.sh")
    readonly property int intervalS: BarConfig.updates.interval || 3600

    visible: count > 0
    text: "\uf021 " + count
    color: count >= 20 ? Theme.err : (count > 0 ? Theme.warn : Theme.dim)
    font.pixelSize: BarConfig.fontSize(Theme.fontSize)

    Process {
        id: proc
        command: ["sh", "-c", "[ -x '" + root.script + "' ] && '" + root.script + "' 2>/dev/null || true"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = (text || "").match(/[0-9]+/);
                root.count = m ? parseInt(m[0]) : 0;
            }
        }
    }

    Timer {
        interval: Math.max(30, root.intervalS) * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["sh", "-c", "'" + root.install + "' 2>/dev/null || true"])
    }
}
