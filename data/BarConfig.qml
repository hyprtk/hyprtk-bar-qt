// The hyprtk-bar config blocks the Qt bar mirrors (module options, font,
// animations and the `monitors` selector). Read from the shared config so the
// GTK and Qt bars stay in sync.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME") || ""
    property var cfg: ({})

    FileView {
        id: cfgFile
        path: root.home + "/.config/hyprtk-bar/config.json"
        watchChanges: true
        printErrors: false
        onLoaded: root._parse()
        onTextChanged: root._parse()
        onFileChanged: reload()
    }
    function _parse() {
        try {
            root.cfg = JSON.parse(cfgFile.text()) || ({});
        } catch (e) {
            root.cfg = ({});
        }
    }

    function block(key) {
        const b = root.cfg[key];
        return (b && typeof b === "object") ? b : ({});
    }

    readonly property var workspaces: block("workspaces")
    readonly property var clock: block("clock")
    readonly property var tray: block("tray")
    readonly property var windowBlock: block("window")
    readonly property var updates: block("updates")
    readonly property var quicksettings: block("quicksettings")
    readonly property var notifications: block("notifications")
    readonly property var arcmenu: block("arcmenu")
    readonly property var font: block("font")
    readonly property var animations: block("animations")
    readonly property var monitors: root.cfg.monitors !== undefined ? root.cfg.monitors : "primary"

    // font.family "" = follow the Qt bar's own font.
    function fontFamily(fallback) {
        const f = root.font.family;
        return (typeof f === "string" && f.length > 0) ? f : fallback;
    }
    function fontSize(fallback) {
        const s = root.font.size;
        return (typeof s === "number" && s > 0) ? s : fallback;
    }
}
