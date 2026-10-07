// Snap-group layout for the desktop widgets (layout comes from the backend).
//
// Widgets sharing a snap_group are laid out together; WidgetFrame reads the
// override for its id. Empty unless at least one widget has a snap_group.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string backend:
        Qt.resolvedUrl("../backend/hyprtk_bar_qt/widgets_layout.py").toString().replace("file://", "")

    readonly property bool hasGroups: {
        const cfg = Widgets.cfg || ({});
        for (const k in cfg) {
            const b = cfg[k];
            if (b && typeof b === "object" && String(b.snap_group || "").length > 0)
                return true;
        }
        return false;
    }

    property var layout: ({})

    Process {
        id: proc
        running: root.hasGroups
        command: ["python3", root.backend, "layout", "--json", JSON.stringify(Widgets.cfg || ({}))]
        stdout: SplitParser {
            onRead: line => {
                try { root.layout = JSON.parse(line).layout || ({}); } catch (e) {}
            }
        }
    }

    function forId(id) {
        return root.hasGroups ? (root.layout[id] || null) : null;
    }
}
