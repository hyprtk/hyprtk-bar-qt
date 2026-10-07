// Base layer-shell surface for a desktop widget: placement, size, pill
// background/border and pywal theming. Children go into the padded column.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../theme"
import "../../data"

PanelWindow {
    id: frame

    // ── placement ──────────────────────────────────────────────────────
    property string position: "top-left"   // free | 9-way
    property int marginX: 40
    property int marginY: 40
    property string layer: "bottom"        // background | bottom | top

    // ── appearance ─────────────────────────────────────────────────────
    property int widgetWidth: 280
    property int widgetHeight: 0           // 0 = auto
    property real widgetOpacity: 0.75
    property int radius: 16
    property int padding: 18
    property real scale: 1.0
    property color backgroundOverride: "transparent"
    property color foregroundOverride: "transparent"
    property color accentOverride: "transparent"

    readonly property var walColors: Theme.wal.colors || ({})
    readonly property var walSpecial: Theme.wal.special || ({})
    readonly property color widgetBackground: frame._pick(frame.backgroundOverride, frame.walSpecial.background, "#1e1e2e")
    readonly property color widgetForeground: frame._pick(frame.foregroundOverride, frame.walSpecial.foreground, "#e5e7eb")
    readonly property color widgetAccent: frame._pick(frame.accentOverride, frame.walColors.color5, "#c084fc")

    default property alias contentData: contentCol.data

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: frame._layer()
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    readonly property var pos: frame._pos()
    anchors.top: pos.top
    anchors.bottom: pos.bottom
    anchors.left: pos.left
    anchors.right: pos.right
    margins.top: pos.top ? frame.marginY : 0
    margins.bottom: pos.bottom ? frame.marginY : 0
    margins.left: pos.left ? frame.marginX : 0
    margins.right: pos.right ? frame.marginX : 0

    implicitWidth: frame.widgetWidth
    implicitHeight: frame.widgetHeight > 0
        ? frame.widgetHeight
        : contentCol.implicitHeight + frame.padding * 2

    function _pick(override, wal, fallback) {
        if (override.a > 0)
            return override;
        return (typeof wal === "string" && wal.length > 0) ? wal : fallback;
    }
    function _pos() {
        if (frame.position === "free")
            return { top: true, bottom: false, left: true, right: false };
        const parts = frame.position.split("-");
        const v = parts.length > 1 ? parts[0] : (parts[0] === "top" || parts[0] === "bottom" ? parts[0] : "center");
        const h = parts.length > 1 ? parts[1] : "center";
        return { top: v === "top", bottom: v === "bottom", left: h === "left", right: h === "right" };
    }
    function _layer() {
        if (frame.layer === "background")
            return WlrLayer.Background;
        if (frame.layer === "top")
            return WlrLayer.Top;
        return WlrLayer.Bottom;
    }

    Rectangle {
        anchors.fill: parent
        radius: frame.radius
        color: Widgets.transparent
            ? "transparent"
            : Qt.rgba(frame.widgetBackground.r, frame.widgetBackground.g, frame.widgetBackground.b, frame.widgetOpacity)
        border.width: Widgets.transparent ? 0 : 1
        border.color: Qt.rgba(frame.widgetAccent.r, frame.widgetAccent.g, frame.widgetAccent.b, 0.25)

        ColumnLayout {
            id: contentCol
            anchors.fill: parent
            anchors.margins: frame.padding
            spacing: Math.round(8 * frame.scale)
        }
    }
}
