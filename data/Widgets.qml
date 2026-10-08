// Desktop-widget configuration, read from the shared hyprtk-bar config
// (`widgets` block in ~/.config/hyprtk-bar/config.json).
//
// The Qt bar renders the same widgets as the GTK bar so the two stay in sync;
// editing lives on the Settings → Widgets page.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME") || ""
    readonly property var ids: ["clock", "weather", "visualizer", "disk", "network", "resources", "sysinfo"]

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
            root.cfg = (JSON.parse(cfgFile.text()).widgets) || ({});
        } catch (e) {
            root.cfg = ({});
        }
    }

    readonly property bool masterEnabled: root.cfg.enabled === true
    readonly property bool transparent: root.cfg.transparent === true

    function block(id) {
        return root.cfg[id] || ({});
    }
    function active(id) {
        return root.masterEnabled && root.block(id).enabled === true;
    }
    function activeIds() {
        return root.ids.filter(id => root.active(id));
    }
}
