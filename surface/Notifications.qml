// Notification daemon + toast stack, via Quickshell.Services.Notifications.
//
// Only one process can own org.freedesktop.Notifications, so this surface is
// loaded by shell.qml behind an env gate (HYPRTK_BAR_QT_NOTIFICATIONS=1) — it
// must not be enabled while the GTK bar's daemon is still running.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import "../theme"

Scope {
    id: root

    NotificationServer {
        id: server
        keepOnReload: false
        onNotification: (n) => { n.tracked = true; }
    }

    PanelWindow {
        id: toasts

        anchors.top: true
        anchors.right: true
        margins.top: 46
        margins.right: 8
        implicitWidth: 340
        implicitHeight: column.implicitHeight + 24
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        visible: server.trackedNotifications.values.length > 0

        Rectangle {
            anchors.fill: parent
            radius: 14
            color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, Theme.opacity)

            ColumnLayout {
                id: column
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                Repeater {
                    model: server.trackedNotifications

                    delegate: Rectangle {
                        id: toast
                        required property var modelData

                        Layout.fillWidth: true
                        implicitHeight: body.implicitHeight + 16
                        radius: 10
                        color: Theme.alpha(Theme.accent2, 0.15)
                        border.color: Theme.alpha(Theme.accent, 0.5)
                        border.width: 1

                        ColumnLayout {
                            id: body
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 2

                            Text {
                                text: toast.modelData.summary || ""
                                color: Theme.accent
                                font.bold: true
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                                visible: text.length > 0
                            }
                            Text {
                                text: toast.modelData.body || ""
                                color: Theme.foreground
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                visible: text.length > 0
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: toast.modelData.dismiss()
                        }

                        Timer {
                            running: true
                            interval: Math.max(1500, toast.modelData.expireTimeout || 5000)
                            onTriggered: toast.modelData.expire()
                        }
                    }
                }
            }
        }
    }
}
