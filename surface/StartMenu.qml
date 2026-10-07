// Start menu: searchable application grid + Settings/Themer shortcuts + a
// power footer. (Layout variants — whisker/win7/win11/plasma — are a later
// pass; this is the functional v1.)
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Widgets
import "../theme"
import "../config"
import "../state"

PanelWindow {
    id: sm

    anchors.top: true
    anchors.left: true
    anchors.right: true
    anchors.bottom: true
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    focusable: true
    visible: UiState.startMenuOpen

    property string query: ""

    readonly property var allApps: DesktopEntries.applications.values
    readonly property var shown: {
        const q = query.trim().toLowerCase();
        const list = allApps || [];
        const base = list.filter(e => !e.noDisplay);
        if (q === "")
            return base;
        return base.filter(e => ((e.name || "") + " " + (e.keywords || "") + " " + (e.comment || "")).toLowerCase().includes(q));
    }

    function launch(entry) {
        UiState.startMenuOpen = false;
        entry.execute();
    }
    function power(cmd) {
        UiState.startMenuOpen = false;
        Quickshell.execDetached(["sh", "-c", cmd]);
    }

    // backdrop
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.35)
        MouseArea {
            anchors.fill: parent
            onClicked: UiState.startMenuOpen = false
        }
    }

    Rectangle {
        id: panel
        width: Math.min(680, parent.width - 40)
        height: Math.min(580, parent.height - 120)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 64
        radius: 16
        color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, Theme.opacity)
        border.color: Theme.alpha(Theme.accent2, 0.3)
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                TextField {
                    id: search
                    Layout.fillWidth: true
                    placeholderText: "Search applications\u2026"
                    focus: sm.visible
                    onTextChanged: sm.query = text
                    Keys.onEscapePressed: UiState.startMenuOpen = false
                }
                Button {
                    text: "Settings"
                    onClicked: {
                        UiState.startMenuOpen = false;
                        UiState.settingsOpen = true;
                    }
                }
                Button {
                    text: "Themer"
                    onClicked: {
                        UiState.startMenuOpen = false;
                        UiState.themerOpen = true;
                    }
                }
            }

            GridView {
                id: grid
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                cellWidth: 160
                cellHeight: 96
                model: sm.shown

                delegate: Rectangle {
                    id: cell
                    required property var modelData
                    width: grid.cellWidth - 8
                    height: grid.cellHeight - 8
                    radius: 10
                    color: hover.hovered ? Theme.alpha(Theme.accent2, 0.18) : "transparent"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 4

                        IconImage {
                            implicitSize: 40
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            Layout.alignment: Qt.AlignHCenter
                            source: Quickshell.iconPath(cell.modelData.icon, "application-x-executable")
                        }
                        Text {
                            Layout.fillWidth: true
                            text: cell.modelData.name || ""
                            color: Theme.foreground
                            font.pixelSize: 11
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }

                    HoverHandler { id: hover }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: sm.launch(cell.modelData)
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Item { Layout.fillWidth: true }
                Button { text: "Lock"; onClicked: sm.power(Config.menuPower.lock) }
                Button { text: "Suspend"; onClicked: sm.power(Config.menuPower.suspend) }
                Button { text: "Logout"; onClicked: sm.power(Config.menuPower.logout) }
                Button { text: "Reboot"; onClicked: sm.power(Config.menuPower.reboot) }
                Button { text: "Shut Down"; onClicked: sm.power(Config.menuPower.shutdown) }
            }
        }
    }
}
