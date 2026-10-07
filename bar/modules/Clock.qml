// Clock module: date + time from Quickshell's SystemClock.
import QtQuick
import Quickshell
import "../../theme"
import "../../config"

Text {
    id: root

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    text: Qt.formatDateTime(clock.date, Config.clockFormat)
    color: Theme.foreground
    font.bold: true
    font.pixelSize: 13
    font.family: "Noto Sans"
}
