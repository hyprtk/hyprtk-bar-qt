// Window list (tasklist): one button per app, grouped by appId.
//
// Left-click activates the app's most-recent window, or minimises it when it is
// already focused; middle-click closes it. Backed by the Quickshell Hyprland
// service (HyprlandToplevel: title / activated / address / workspace), with
// actions dispatched by window address.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../../theme"
import "../../data"

RowLayout {
    id: root
    spacing: 4
    readonly property int fs: BarConfig.fontSize(11)

    function _appId(t) {
        return (t.wayland && t.wayland.appId) ? t.wayland.appId : (t.title || "app");
    }
    function groups() {
        const map = {};
        for (const t of (Hyprland.toplevels.values || [])) {
            const k = root._appId(t);
            (map[k] = map[k] || []).push(t);
        }
        return Object.keys(map).map(k => ({ appId: k, wins: map[k] }));
    }
    function _recent(wins) {
        return wins.find(w => w.activated) || wins[0];
    }

    Repeater {
        model: root.groups()

        delegate: Rectangle {
            id: grp
            required property var modelData

            readonly property var wins: grp.modelData.wins
            readonly property bool act: grp.wins.some(w => w.activated)
            readonly property var recent: root._recent(grp.wins)
            readonly property string title: grp.recent ? (grp.recent.title || root._appId(grp.recent)) : "?"

            implicitWidth: Math.min(label.implicitWidth, 180) + 16
            implicitHeight: 22
            radius: 6
            color: grp.act
                ? Theme.alpha(Theme.accent, 0.85)
                : Theme.alpha(Theme.accent2, 0.12)

            Text {
                id: label
                anchors.centerIn: parent
                width: Math.min(implicitWidth, 180)
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                text: grp.title
                color: grp.act ? "#000000" : Theme.foreground
                font.pixelSize: root.fs
            }

            // running indicator
            Rectangle {
                visible: grp.wins.length > 0
                width: 4
                height: 4
                radius: 2
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 1
                color: grp.act ? "#000000" : Theme.accent2
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => {
                    const wins = grp.wins;
                    if (!wins.length)
                        return;
                    const focused = wins.find(w => w.activated);
                    if (mouse.button === Qt.MiddleButton) {
                        const w = focused || root._recent(wins);
                        if (w.address)
                            Hyprland.dispatch("closewindow address:" + w.address);
                        return;
                    }
                    if (focused) {
                        if (focused.address)
                            Hyprland.dispatch("movetoworkspacesilent special:minimized,address:" + focused.address);
                        return;
                    }
                    const w = root._recent(wins);
                    if (w.address)
                        Hyprland.dispatch("focuswindow address:" + w.address);
                }
            }
        }
    }
}
