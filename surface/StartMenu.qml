// Start menu: layout variants (whisker / win7 / win11 / plasma), search,
// favourites, recents, places-style sidebar and a power footer.
//
// Layout/favourites/recents come from the shared hyprtk-bar `menu` block
// (data/MenuConfig.qml); launches + favourite toggles are persisted via
// backend/.../menu.py.
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import "../theme"
import "../config"
import "../state"
import "../data"

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

    readonly property string backend:
        Qt.resolvedUrl("../backend/hyprtk_bar_qt/menu.py").toString().replace("file://", "")

    property string query: ""
    property string side: "all"   // all | favorites | recents
    property string layout: MenuConfig.layout
    readonly property bool isGrid: layout === "win11" || layout === "plasma"

    readonly property var allApps: DesktopEntries.applications.values
    function baseApps() {
        return (sm.allApps || []).filter(e => !e.noDisplay);
    }
    function byId(id) {
        return (sm.allApps || []).find(e => e.id === id);
    }
    function favoritesEntries() {
        return (MenuConfig.favorites || []).map(sm.byId).filter(e => e);
    }
    function recentsEntries() {
        return (MenuConfig.recents || []).map(sm.byId).filter(e => e);
    }
    function shown() {
        const q = sm.query.trim().toLowerCase();
        let list;
        if (q !== "")
            list = sm.baseApps().filter(e => ((e.name || "") + " " + (e.genericName || "") + " " + (e.comment || "") + " " + (e.keywords || "")).toLowerCase().includes(q));
        else if (sm.side === "favorites")
            list = sm.favoritesEntries();
        else if (sm.side === "recents")
            list = sm.recentsEntries();
        else
            list = sm.baseApps();
        return list;
    }
    function isFavorite(id) {
        return (MenuConfig.favorites || []).indexOf(id) >= 0;
    }

    function launch(entry) {
        UiState.startMenuOpen = false;
        entry.execute();
        recProc.command = ["python3", sm.backend, "record", entry.id];
        recProc.running = true;
    }
    function toggleFav(entry) {
        favProc.command = ["python3", sm.backend, sm.isFavorite(entry.id) ? "unfavorite" : "favorite", entry.id];
        favProc.running = true;
    }
    function power(cmd) {
        UiState.startMenuOpen = false;
        const c = MenuConfig.power(cmd);
        if (c)
            Quickshell.execDetached(["sh", "-c", c]);
    }

    Process { id: recProc }
    Process { id: favProc }

    // backdrop
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.35)
        MouseArea { anchors.fill: parent; onClicked: UiState.startMenuOpen = false }
    }

    Rectangle {
        id: panel
        width: Math.min(sm.isGrid ? 760 : MenuConfig.width, parent.width - 40)
        height: Math.min(MenuConfig.height, parent.height - 120)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 64
        radius: 16
        color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, Theme.opacity)
        border.color: Theme.alpha(Theme.accent2, 0.3)
        border.width: 1

        component AppIcon: IconImage {
            id: appIcon
            property var entry
            implicitSize: 36
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36
            source: Quickshell.iconPath(appIcon.entry ? appIcon.entry.icon : "", "application-x-executable")
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                TextField {
                    Layout.fillWidth: true
                    placeholderText: "Search applications\u2026"
                    focus: sm.visible
                    onTextChanged: sm.query = text
                    Keys.onEscapePressed: UiState.startMenuOpen = false
                }
                Button { text: "Settings"; onClicked: { UiState.startMenuOpen = false; UiState.settingsOpen = true; } }
                Button { text: "Themer"; onClicked: { UiState.startMenuOpen = false; UiState.themerOpen = true; } }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12

                // sidebar (whisker / win7)
                ColumnLayout {
                    visible: !sm.isGrid
                    Layout.preferredWidth: MenuConfig.sidebarWidth
                    Layout.fillHeight: true
                    spacing: 4
                    Repeater {
                        model: [
                            { key: "all", label: "All Applications" },
                            { key: "favorites", label: "Favorites" },
                            { key: "recents", label: "Recently Used" }
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: 30
                            radius: 6
                            color: sm.side === modelData.key ? Theme.alpha(Theme.accent, 0.8)
                                : (sideHover.hovered ? Theme.alpha(Theme.accent2, 0.15) : "transparent")
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                text: modelData.label
                                color: sm.side === modelData.key ? "#000000" : Theme.foreground
                                font.pixelSize: 12
                            }
                            HoverHandler { id: sideHover }
                            TapHandler { onTapped: sm.side = modelData.key }
                        }
                    }
                    Item { Layout.fillHeight: true }
                }

                // app list (whisker/win7)
                ListView {
                    visible: !sm.isGrid
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: sm.shown()
                    spacing: 2
                    delegate: Rectangle {
                        id: lrow
                        required property var modelData
                        width: ListView.view.width
                        height: 38
                        radius: 6
                        color: lrowHover.hovered ? Theme.alpha(Theme.accent2, 0.15) : "transparent"
                        // Launch surface sits *under* the row content so the
                        // star (on top) can take its own clicks.
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: sm.launch(lrow.modelData)
                        }
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 10
                            AppIcon { entry: lrow.modelData }
                            Text {
                                text: lrow.modelData.name || ""
                                color: Theme.foreground
                                font.pixelSize: 12
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                            Text {
                                text: sm.isFavorite(lrow.modelData.id) ? "\uf005" : "\uf006"
                                color: sm.isFavorite(lrow.modelData.id) ? Theme.warn : Theme.dim
                                font.pixelSize: 12
                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -6
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: sm.toggleFav(lrow.modelData)
                                }
                            }
                        }
                        HoverHandler { id: lrowHover }
                    }
                }

                // app grid (win11 / plasma)
                GridView {
                    visible: sm.isGrid
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    cellWidth: 150
                    cellHeight: 92
                    model: sm.shown()
                    delegate: Rectangle {
                        id: cell
                        required property var modelData
                        width: GridView.view.cellWidth - 8
                        height: GridView.view.cellHeight - 8
                        radius: 10
                        color: cellHover.hovered ? Theme.alpha(Theme.accent2, 0.18) : "transparent"
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 4
                            AppIcon { entry: cell.modelData; Layout.alignment: Qt.AlignHCenter }
                            Text {
                                Layout.fillWidth: true
                                text: cell.modelData.name || ""
                                color: Theme.foreground
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                        HoverHandler { id: cellHover }
                        TapHandler { onTapped: sm.launch(cell.modelData) }
                    }
                }

                // recents panel (whisker only)
                ColumnLayout {
                    visible: !sm.isGrid && layout === "whisker" && MenuConfig.showRecents
                    Layout.preferredWidth: MenuConfig.recentsWidth
                    Layout.fillHeight: true
                    spacing: 4
                    Text { text: "Recently Used"; color: Theme.dim; font.pixelSize: 11 }
                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        model: sm.recentsEntries()
                        spacing: 2
                        delegate: Rectangle {
                            id: rrow
                            required property var modelData
                            width: ListView.view.width
                            height: 34
                            radius: 6
                            color: rrowHover.hovered ? Theme.alpha(Theme.accent2, 0.15) : "transparent"
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 6
                                anchors.rightMargin: 6
                                spacing: 8
                                AppIcon { entry: rrow.modelData; implicitSize: 24; Layout.preferredWidth: 24; Layout.preferredHeight: 24 }
                                Text { text: rrow.modelData.name || ""; color: Theme.foreground; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
                            }
                            HoverHandler { id: rrowHover }
                            TapHandler { onTapped: sm.launch(rrow.modelData) }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Text { text: sm.layout; color: Theme.dim; font.pixelSize: 10; Layout.fillWidth: true }
                Button { text: "Lock"; onClicked: sm.power("lock") }
                Button { text: "Suspend"; onClicked: sm.power("suspend") }
                Button { text: "Logout"; onClicked: sm.power("logout") }
                Button { text: "Reboot"; onClicked: sm.power("reboot") }
                Button { text: "Shut Down"; onClicked: sm.power("shutdown") }
            }
        }
    }
}
