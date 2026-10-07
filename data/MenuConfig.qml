// Start-menu configuration, read from the shared hyprtk-bar `menu` block.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../config"

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
            root.cfg = (JSON.parse(cfgFile.text()).menu) || ({});
        } catch (e) {
            root.cfg = ({});
        }
    }

    readonly property string layout: cfg.layout || "whisker"
    readonly property var favorites: cfg.favorites || []
    readonly property var recents: cfg.recents || []
    readonly property bool showRecents: cfg.show_recents !== false
    readonly property int maxRecents: cfg.max_recents || 10
    readonly property int sidebarWidth: cfg.sidebar_width || 180
    readonly property int recentsWidth: cfg.recents_width || 230
    readonly property int width: cfg.width || 920
    readonly property int height: cfg.height || 580

    // Power commands: menu block overrides, else the Qt bar's own defaults.
    function power(cmd) {
        const p = cfg.power || ({});
        return p[cmd] || Config.menuPower[cmd] || "";
    }
}
