// CPU / memory / disk module: live percentage + a rolling sparkline each.
//
// Values come from the shared SysData singleton (Python backend), not from a
// per-widget process. Percentages colour at 70% (warn) / 90% (high).
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
    visible: BarConfig.sysmon.enabled !== false

    readonly property int fs: BarConfig.fontSize(11)
    readonly property bool monitorEnabled: BarConfig.sysmon.monitor !== false

    function levelColor(pct) {
        return pct >= 90 ? Theme.err : (pct >= 70 ? Theme.warn : Theme.foreground);
    }

    component Metric: RowLayout {
        id: m
        property string glyph: ""
        property color glyphColor: Theme.dim
        property var values: []
        property color lineColor: Theme.accent
        property real pct: 0
        spacing: 4
        Text { text: m.glyph; color: m.glyphColor; font.family: BarConfig.glyphFont; font.pixelSize: root.fs + 1 }
        Sparkline {
            Layout.preferredWidth: 46
            Layout.preferredHeight: 16
            values: m.values
            color: m.lineColor
            scale: 1.0
        }
        Text {
            text: Math.round(m.pct) + "%"
            color: root.levelColor(m.pct)
            font.pixelSize: root.fs
            Layout.preferredWidth: 30
        }
    }

    Metric { glyph: "\uf2db"; glyphColor: Theme.accent; values: SysData.cpuHist; lineColor: Theme.accent; pct: SysData.cpu * 100 }
    Metric { glyph: "\uefc5"; glyphColor: Theme.accent2; values: SysData.memHist; lineColor: Theme.accent2; pct: SysData.mem * 100 }
    Metric { glyph: "\uDBC0\uDECA"; glyphColor: Theme.dim; values: SysData.diskHist; lineColor: Theme.dim; pct: SysData.disk * 100 }

    // Left-click opens the Mission Center-style system monitor dialog.
    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: {
            if (root.monitorEnabled)
                UiState.sysMonitorOpen = true;
        }
    }
    HoverHandler {
        cursorShape: root.monitorEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    }
}
