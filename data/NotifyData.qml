// Notification daemon + history, shared by the bar bell, the toast stack and
// the notification center.
//
// Only one process can own org.freedesktop.Notifications, so the daemon is
// gated behind HYPRTK_BAR_QT_NOTIFICATIONS=1 (the GTK bar's daemon must be
// retired first). Without the gate the singleton still exists, so the bell and
// center render — they just never receive anything.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import "."

Singleton {
    id: root

    readonly property bool enabled:
        Quickshell.env("HYPRTK_BAR_QT_NOTIFICATIONS") === "1"
        && BarConfig.notifications.enabled !== false

    // Shared notifications config block (max_stored / default_timeout).
    readonly property int maxStored: BarConfig.notifications.max_stored || 50
    readonly property int defaultTimeout: BarConfig.notifications.default_timeout || 5000

    // History (all tracked notifications, newest last) + arrival timestamps.
    property var tracked: []
    property var stamps: ({})
    property int unread: 0

    // Transient toasts (a small subset of `tracked` shown briefly).
    property var toasts: []

    Loader {
        active: root.enabled
        sourceComponent: Component {
            NotificationServer {
                id: srv
                keepOnReload: false
                onNotification: (n) => {
                    n.tracked = true;
                    root.unread += 1;
                    const m = Object.assign({}, root.stamps);
                    m[n.id] = Date.now();
                    root.stamps = m;
                    root._pushToast(n);
                }
                onTrackedNotificationsChanged: root.tracked = srv.trackedNotifications.values
                Component.onCompleted: root.tracked = srv.trackedNotifications.values
            }
        }
    }

    function _pushToast(n) {
        const next = root.toasts.filter(x => x !== n);
        next.unshift(n);
        root.toasts = next.slice(0, 3);
    }
    function dropToast(n) {
        root.toasts = root.toasts.filter(x => x !== n);
    }

    function markRead() {
        root.unread = 0;
    }
    function remove(n) {
        n.dismiss();
    }
    function clearAll() {
        const items = root.tracked.slice();
        for (let i = 0; i < items.length; i++)
            items[i].dismiss();
    }

    // Newest-first history for the center (capped at max_stored).
    function history() {
        return root.tracked.slice().reverse().slice(0, root.maxStored);
    }

    function ago(id) {
        const t = root.stamps[id];
        if (!t)
            return "";
        const s = Math.max(0, Math.floor((Date.now() - t) / 1000));
        if (s < 60)
            return s + "s";
        if (s < 3600)
            return Math.floor(s / 60) + "m";
        if (s < 86400)
            return Math.floor(s / 3600) + "h";
        return Math.floor(s / 86400) + "d";
    }
}
