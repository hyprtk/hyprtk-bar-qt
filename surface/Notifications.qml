// Notification toast stack, via the shared NotifyData singleton.
//
// The daemon (and history) live in data/NotifyData.qml; this surface only
// renders the transient toasts. It is loaded by shell.qml behind the
// HYPRTK_BAR_QT_NOTIFICATIONS=1 env gate.
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../theme"
import "../data"

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
    visible: NotifyData.toasts.length > 0

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
                model: NotifyData.toasts

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
                            text: toast.modelData.appName || "Notification"
                            color: Theme.dim
                            font.pixelSize: 10
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            visible: text.length > 0
                        }
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

                    TapHandler {
                        onTapped: NotifyData.dropToast(toast.modelData)
                    }

                    Timer {
                        running: true
                        interval: {
                            const t = toast.modelData.expireTimeout;
                            return t && t > 0 ? Math.max(1500, t) : NotifyData.defaultTimeout;
                        }
                        onTriggered: NotifyData.dropToast(toast.modelData)
                    }
                }
            }
        }
    }
}
