// Bell button with an unread badge; toggles the notification center.
import QtQuick
import "../../theme"
import "../../components"
import "../../state"
import "../../data"

Item {
    implicitWidth: 22
    implicitHeight: 22
    visible: BarConfig.notifications.enabled !== false

    BarIconButton {
        anchors.fill: parent
        glyph: "\uf0f3"
        active: UiState.notificationCenterOpen
        onActivated: {
            UiState.notificationCenterOpen = !UiState.notificationCenterOpen;
            if (UiState.notificationCenterOpen)
                NotifyData.markRead();
        }
    }

    Rectangle {
        visible: NotifyData.unread > 0
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: -4
        anchors.rightMargin: -4
        width: Math.max(14, badgeText.implicitWidth + 6)
        height: 14
        radius: 7
        color: Theme.err
        Text {
            id: badgeText
            anchors.centerIn: parent
            text: NotifyData.unread > 9 ? "9+" : String(NotifyData.unread)
            color: "#000000"
            font.pixelSize: 9
        }
    }
}
