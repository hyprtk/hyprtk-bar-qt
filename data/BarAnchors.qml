// Window-relative anchor positions registered by bar modules, so screen-anchored
// popups (notification center) can line up under the module that opens them.
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    // Notification bell: x/width in bar-window coordinates.
    property real notifX: -1
    property real notifW: 22

    function setNotif(x, w) {
        root.notifX = x;
        root.notifW = w;
    }
}
