// The bar surface: a frosted panel whose module row is data-driven from
// Config.layoutLeft / layoutCenter / layoutRight. Right-click opens the menu.
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../theme"
import "../config"
import "../state"
import "../data"
import "modules"

Rectangle {
    id: root

    readonly property real bgOpacity: Config.opacity >= 0 ? Config.opacity : Theme.opacity
    readonly property var leftMods: BarConfig.layoutLeft.length ? BarConfig.layoutLeft : Config.layoutLeft
    readonly property var centerMods: BarConfig.layoutCenter.length ? BarConfig.layoutCenter : Config.layoutCenter
    readonly property var rightMods: BarConfig.layoutRight.length ? BarConfig.layoutRight : Config.layoutRight

    color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, root.bgOpacity)
    radius: BarConfig.radius

    // Maps a layout entry to its module component.
    component ModuleChooser: DelegateChooser {
        role: "modelData"
        DelegateChoice { roleValue: "start_button"; delegate: StartButton {} }
        DelegateChoice { roleValue: "quicklinks"; delegate: Quicklinks {} }
        DelegateChoice { roleValue: "workspaces"; delegate: Workspaces {} }
        DelegateChoice { roleValue: "tasklist"; delegate: Tasklist {} }
        DelegateChoice { roleValue: "window"; delegate: ActiveWindow {} }
        DelegateChoice { roleValue: "updates"; delegate: Updates {} }
        DelegateChoice { roleValue: "net"; delegate: Net {} }
        DelegateChoice { roleValue: "tray"; delegate: Tray {} }
        DelegateChoice { roleValue: "kbstate"; delegate: KbState {} }
        DelegateChoice { roleValue: "notifications"; delegate: NotificationsButton {} }
        DelegateChoice { roleValue: "clock"; delegate: Clock {} }
        DelegateChoice { roleValue: "sysmon"; delegate: SysMonitor {} }
        DelegateChoice { roleValue: "arcmenu"; delegate: ArcButton {} }
        DelegateChoice { roleValue: "themer"; delegate: ThemerButton {} }
        DelegateChoice { roleValue: "settings"; delegate: SettingsButton {} }
        DelegateChoice { roleValue: "quicksettings"; delegate: QuickSettingsButton {} }
        DelegateChoice { delegate: Item {} }
    }

    // right-click anywhere on the bar opens the context menu
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: (mouse) => {
            UiState.barMenuX = mouse.x;
            UiState.barMenuOpen = true;
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 10

        RowLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 8
            Repeater {
                model: root.leftMods
                delegate: ModuleChooser {}
            }
        }

        Item { Layout.fillWidth: true }

        RowLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 8
            Repeater {
                model: root.centerMods
                delegate: ModuleChooser {}
            }
        }

        Item { Layout.fillWidth: true }

        RowLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 8
            Repeater {
                model: root.rightMods
                delegate: ModuleChooser {}
            }
        }
    }
}
