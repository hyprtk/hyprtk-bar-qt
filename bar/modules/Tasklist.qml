// Window list (tasklist): one button per app, grouped by appId, with optional
// pinned apps from the shared `center.pinned` config.
//
// Left-click activates the app's most-recent window, or minimises it when it is
// already focused; middle-click closes it; a pinned app with no window launches
// its command. Backed by the Quickshell Hyprland service (HyprlandToplevel:
// title / activated / address / workspace), with actions dispatched by address.
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
    readonly property var pinned: (BarConfig.center.pinned || [])

    function _appId(t) {
        return (t.wayland && t.wayland.appId) ? t.wayland.appId : (t.title || "app");
    }
    function _match(a, b) {
        a = String(a || "").toLowerCase().replace(/\.desktop$/, "");
        b = String(b || "").toLowerCase().replace(/\.desktop$/, "");
        return a.length > 0 && b.length > 0 && (a === b || a.includes(b) || b.includes(a));
    }
    function groups() {
        const map = {};
        for (const t of (Hyprland.toplevels.values || [])) {
            const k = root._appId(t);
            (map[k] = map[k] || []).push(t);
        }
        const out = [];
        const seen = {};
        for (const p of root.pinned) {
            let key = null;
            for (const k in map)
                if (root._match(p.class, k)) { key = k; break; }
            out.push({ pinned: p, wins: key ? map[key] : [] });
            if (key)
                seen[key] = true;
        }
        for (const k in map)
            if (!seen[k])
                out.push({ pinned: null, wins: map[k] });
        return out;
    }
    function _recent(wins) {
        return wins.find(w => w.activated) || wins[0];
    }
    function _menu(grp) {
        const w = root._recent(grp.wins);
        const items = [];
        if (w) {
            items.push({ label: "Minimise", action: () => {
                if (w.address) Hyprland.dispatch(Hypr.moveWindowTo("special:minimized", w.address));
            } });
            items.push({ label: "Close window", action: () => {
                if (w.address) Hyprland.dispatch(Hypr.closeWindow(w.address));
            } });
        } else if (grp.modelData.pinned && grp.modelData.pinned.command) {
            items.push({ label: "Launch", action: () => Quickshell.execDetached(["sh", "-c", grp.modelData.pinned.command]) });
        }
        PopupMenu.open(grp, items);
    }

    Repeater {
        model: root.groups()

        delegate: Rectangle {
            id: grp
            required property var modelData

            readonly property var wins: grp.modelData.wins
            readonly property var pin: grp.modelData.pinned
            readonly property bool act: grp.wins.some(w => w.activated)
            readonly property bool running: grp.wins.length > 0
            readonly property var recent: root._recent(grp.wins)
            readonly property string title: grp.running
                ? (grp.recent.title || root._appId(grp.recent))
                : (grp.pin && grp.pin.class ? grp.pin.class : "?")

            implicitWidth: Math.min(label.implicitWidth, 180) + 16
            implicitHeight: 22
            radius: 6
            color: grp.act
                ? Theme.alpha(Theme.accent, 0.85)
                : (grp.running ? Theme.alpha(Theme.accent2, 0.12) : Theme.alpha(Theme.dim, 0.18))

            Text {
                id: label
                anchors.centerIn: parent
                width: Math.min(implicitWidth, 180)
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                text: grp.title
                color: grp.act ? "#000000" : (grp.running ? Theme.foreground : Theme.dim)
                font.pixelSize: root.fs
            }

            // running indicator
            Rectangle {
                visible: grp.running
                width: 4
                height: 4
                radius: 2
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 1
                color: grp.act ? "#000000" : Theme.accent2
            }

            HoverHandler {
                id: grpHover
                onHoveredChanged: grpHover.hovered
                    ? Tooltips.showTip(grp, grp.title)
                    : Tooltips.hideTip()
            }
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => {
                    if (mouse.button === Qt.RightButton) {
                        root._menu(grp);
                        return;
                    }
                    const wins = grp.wins;
                    if (!wins.length) {
                        if (mouse.button === Qt.LeftButton && grp.pin && grp.pin.command)
                            Quickshell.execDetached(["sh", "-c", grp.pin.command]);
                        return;
                    }
                    const focused = wins.find(w => w.activated);
                    if (mouse.button === Qt.MiddleButton) {
                        const w = focused || root._recent(wins);
                        if (w.address)
                            Hyprland.dispatch(Hypr.closeWindow(w.address));
                        return;
                    }
                    if (focused) {
                        if (focused.address)
                            Hyprland.dispatch(Hypr.moveWindowTo("special:minimized", focused.address));
                        return;
                    }
                    const w = root._recent(wins);
                    if (w.address)
                        Hyprland.dispatch(Hypr.focusWindow(w.address));
                }
            }
        }
    }
}
