// Window-relative anchor positions registered by bar modules, so screen-anchored
// popups (notification center, quick settings, start menu, bar menu) can line up
// under the module that opens them — on the correct monitor. Each anchor also
// records the Wayland output name so the popup can set its own `screen`.
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    // Notification bell: x/width in bar-window coords + its screen name.
    property real notifX: -1
    property real notifW: 22
    property string notifScreen: ""

    function setNotif(x, w, screen) {
        root.notifX = x;
        root.notifW = w;
        if (screen)
            root.notifScreen = screen;
    }

    // Quick-settings button: x/width in bar-window coords + its screen name.
    property real qsX: -1
    property real qsW: 22
    property string qsScreen: ""

    function setQs(x, w, screen) {
        root.qsX = x;
        root.qsW = w;
        if (screen)
            root.qsScreen = screen;
    }

    // Screen that last opened the start menu / bar context menu (set on click).
    property string menuScreen: ""
    property string barMenuScreen: ""

    function setMenuScreen(name) { if (name) root.menuScreen = name; }
    function setBarMenuScreen(name) { if (name) root.barMenuScreen = name; }
}
