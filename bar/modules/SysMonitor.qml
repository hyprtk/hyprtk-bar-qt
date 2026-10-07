// CPU / memory module: live percentage + a rolling sparkline each.
//
// Values come from the shared SysData singleton (Python backend), not from a
// per-widget process.
import QtQuick
import QtQuick.Layouts
import "../../theme"
import "../../config"
import "../../state"
import "../../data"
import "../../components"

RowLayout {
    id: root
    spacing: 10

    RowLayout {
        spacing: 4
        Text { text: "CPU"; color: Theme.dim; font.pixelSize: 11 }
        Sparkline {
            Layout.preferredWidth: 46
            Layout.preferredHeight: 16
            values: SysData.cpuHist
            color: Theme.accent
            scale: 1.0
        }
        Text {
            text: Math.round(SysData.cpu * 100) + "%"
            color: Theme.foreground
            font.pixelSize: 11
            Layout.preferredWidth: 30
        }
    }

    RowLayout {
        spacing: 4
        Text { text: "MEM"; color: Theme.dim; font.pixelSize: 11 }
        Sparkline {
            Layout.preferredWidth: 46
            Layout.preferredHeight: 16
            values: SysData.memHist
            color: Theme.accent2
            scale: 1.0
        }
        Text {
            text: Math.round(SysData.mem * 100) + "%"
            color: Theme.foreground
            font.pixelSize: 11
            Layout.preferredWidth: 30
        }
    }

    // Left-click opens the Mission Center-style system monitor dialog.
    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: {
            if (Config.sysmonMonitor)
                UiState.sysMonitorOpen = true;
        }
    }
    HoverHandler {
        cursorShape: Config.sysmonMonitor ? Qt.PointingHandCursor : Qt.ArrowCursor
    }
}
