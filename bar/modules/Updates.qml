// Package-update indicator: runs the hyprtk updates script periodically and
// shows the pending count, coloured by threshold. Click runs the installer.
import QtQuick
import Quickshell
import Quickshell.Io
import "../../theme"

Text {
    id: root

    property int count: 0

    readonly property string script: root.home + "/.local/share/hyprtk-bar/scripts/updates.sh"
    readonly property string home: Quickshell.env("HOME") || ""

    visible: count > 0
    text: "\uf021 " + count
    color: count >= 20 ? Theme.err : (count > 0 ? Theme.warn : Theme.dim)
    font.pixelSize: 12

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
        interval: 1800000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["sh", "-c",
            "~/.local/share/hyprtk-bar/scripts/installupdates.sh 2>/dev/null || true"])
    }
}
