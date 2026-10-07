// Notification center: the Win11-style history panel, opened from the bar bell.
//
// History comes from the shared NotifyData singleton (the daemon); toasts are
// rendered separately by surface/Notifications.qml.
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../theme"
import "../config"
import "../state"
import "../data"

PanelWindow {
    id: center

    visible: UiState.notificationCenterOpen
    color: "transparent"
    focusable: true
    exclusionMode: ExclusionMode.Ignore

    anchors.top: Config.barPosition === "top"
    anchors.bottom: Config.barPosition === "bottom"
    anchors.right: true
    margins.top: Config.barPosition === "top" ? Config.barHeight + Config.gapOut + 6 : 0
    margins.bottom: Config.barPosition === "bottom" ? Config.barHeight + Config.gapOut + 6 : 0
    margins.right: 8
    implicitWidth: 380
    implicitHeight: 420

    onVisibleChanged: if (visible) NotifyData.markRead()

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, Math.max(0.96, Theme.opacity))
        border.width: 1
        border.color: Theme.alpha(Theme.accent2, 0.2)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                Text { text: "Notifications"; color: Theme.accent; font.bold: true; font.pixelSize: 15; Layout.fillWidth: true }
                Rectangle {
                    implicitWidth: clearText.implicitWidth + 18
                    implicitHeight: 26
                    radius: 6
                    color: clearHover.hovered ? Theme.alpha(Theme.accent2, 0.25) : Theme.alpha(Theme.accent2, 0.12)
                    Text { id: clearText; anchors.centerIn: parent; text: "Clear all"; color: Theme.foreground; font.pixelSize: 11 }
                    HoverHandler { id: clearHover }
                    TapHandler { onTapped: NotifyData.clearAll() }
                }
                Text {
                    text: "\u00d7"
                    color: Theme.dim
                    font.pixelSize: 18
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: UiState.notificationCenterOpen = false
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                visible: !NotifyData.enabled
                text: "Notification daemon disabled. Start the bar with HYPRTK_BAR_QT_NOTIFICATIONS=1."
                color: Theme.warn
                font.pixelSize: 11
                wrapMode: Text.WordWrap
            }

            Text {
                Layout.fillWidth: true
                visible: NotifyData.tracked.length === 0
                text: "No notifications"
                color: Theme.dim
                font.pixelSize: 12
                topPadding: 12
            }

            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: list.implicitHeight
                clip: true
                visible: NotifyData.tracked.length > 0
                ColumnLayout {
                    id: list
                    width: parent.width
                    spacing: 6
                    Repeater {
                        model: NotifyData.history()
                        delegate: Rectangle {
                            id: row
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: rowBody.implicitHeight + 18
                            radius: 10
                            color: Theme.alpha(Theme.accent2, 0.1)
                            border.width: 1
                            border.color: Theme.alpha(Theme.accent, 0.25)

                            ColumnLayout {
                                id: rowBody
                                anchors.fill: parent
                                anchors.margins: 9
                                spacing: 3
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6
                                    Text { text: row.modelData.appName || "Notification"; color: Theme.dim; font.pixelSize: 10; Layout.fillWidth: true; elide: Text.ElideRight }
                                    Text { text: NotifyData.ago(row.modelData.id); color: Theme.dim; font.pixelSize: 10 }
                                    Text {
                                        text: "\u00d7"
                                        color: Theme.dim
                                        font.pixelSize: 13
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: NotifyData.remove(row.modelData)
                                        }
                                    }
                                }
                                Text {
                                    text: row.modelData.summary || ""
                                    color: Theme.accent
                                    font.bold: true
                                    font.pixelSize: 12
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                    visible: text.length > 0
                                }
                                Text {
                                    text: row.modelData.body || ""
                                    color: Theme.foreground
                                    font.pixelSize: 11
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                    visible: text.length > 0
                                }
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6
                                    visible: (row.modelData.actions || []).length > 0
                                    Item { Layout.fillWidth: true }
                                    Repeater {
                                        model: row.modelData.actions || []
                                        delegate: Rectangle {
                                            required property var modelData
                                            implicitWidth: actText.implicitWidth + 18
                                            implicitHeight: 24
                                            radius: 6
                                            color: actHover.hovered ? Theme.alpha(Theme.accent2, 0.3) : Theme.alpha(Theme.accent, 0.25)
                                            Text { id: actText; anchors.centerIn: parent; text: modelData.text || ""; color: Theme.foreground; font.pixelSize: 11 }
                                            HoverHandler { id: actHover }
                                            TapHandler { onTapped: modelData.invoke() }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
