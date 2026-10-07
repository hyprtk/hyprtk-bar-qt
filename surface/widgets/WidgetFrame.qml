// Base layer-shell surface for a desktop widget: placement, size, pill
// background/border and pywal theming. Children go into the padded column.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../theme"
import "../../config"
import "../../data"

PanelWindow {
    id: frame

    // ── placement ──────────────────────────────────────────────────────
    property string widgetId: ""           // for snap-group overrides
    property string position: "top-left"   // free | 9-way
    property int marginX: 40
    property int marginY: 40
    property string layer: "bottom"        // background | bottom | top

    // Placement overrides: an active move wins over a snap-group override, which
    // wins over the widget's own config.
    readonly property var moveOver: WidgetMove.overFor(frame.widgetId)
    readonly property var snapOver: WidgetLayout.forId(frame.widgetId)
    readonly property var over: frame.moveOver !== null ? frame.moveOver : frame.snapOver
    readonly property bool hasOver: over !== null
    readonly property string effPos: frame.hasOver ? "free" : frame.position
    readonly property int effMarginX: frame.hasOver ? frame.over.x : frame.marginX
    readonly property int effMarginY: frame.hasOver ? frame.over.y : frame.marginY
    readonly property int effWidth: (frame.hasOver && frame.over.w > 0) ? frame.over.w : frame.widgetWidth
    readonly property int effHeight: (frame.hasOver && frame.over.h > 0) ? frame.over.h : frame.widgetHeight

    // Global rect (single monitor origin) for hit-testing a move.
    function _gx() {
        const sw = frame.screen ? frame.screen.width : 0;
        if (pos.left)
            return frame.effMarginX;
        if (pos.right)
            return sw - frame.effMarginX - frame.width;
        return Math.round((sw - frame.width) / 2);
    }
    function _gy() {
        const sh = frame.screen ? frame.screen.height : 0;
        if (pos.top)
            return frame.effMarginY;
        if (pos.bottom)
            return sh - frame.effMarginY - frame.height;
        return Math.round((sh - frame.height) / 2);
    }
    function _register() {
        WidgetMove.setGeometry(frame.widgetId, frame._gx(), frame._gy(), frame.width, frame.height);
    }
    Component.onCompleted: _register()
    onWidthChanged: _register()
    onHeightChanged: _register()
    onHasOverChanged: _register()

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

    // Usable area: never sit under the bar (its edge inset acts as a border).
    readonly property int barTop: BarConfig.barPosition === "top" ? BarConfig.barHeight + BarConfig.gapOut : 0
    readonly property int barBottom: BarConfig.barPosition === "bottom" ? BarConfig.barHeight + BarConfig.gapOut : 0

    readonly property var pos: frame._pos()
    anchors.top: pos.top
    anchors.bottom: pos.bottom
    anchors.left: pos.left
    anchors.right: pos.right
    margins.top: pos.top ? Math.max(frame.effMarginY, frame.barTop) : 0
    margins.bottom: pos.bottom ? Math.max(frame.effMarginY, frame.barBottom) : 0
    margins.left: pos.left ? frame.effMarginX : 0
    margins.right: pos.right ? frame.effMarginX : 0

    implicitWidth: frame.effWidth
    implicitHeight: frame.effHeight > 0
        ? frame.effHeight
        : contentCol.implicitHeight + frame.padding * 2

    function _pick(override, wal, fallback) {
        if (override.a > 0)
            return override;
        return (typeof wal === "string" && wal.length > 0) ? wal : fallback;
    }
    function _pos() {
        if (frame.effPos === "free")
            return { top: true, bottom: false, left: true, right: false };
        const parts = frame.effPos.split("-");
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
