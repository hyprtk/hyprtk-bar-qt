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
import "../components"
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

    // Open on the start button's monitor (registered on click), else focused.
    property var targetScreen: null
    screen: Screens.byName(BarAnchors.menuScreen) || targetScreen

    readonly property string backend:
        Qt.resolvedUrl("../backend/hyprtk_bar_qt/menu.py").toString().replace("file://", "")
    readonly property string filesBackend:
        Qt.resolvedUrl("../backend/hyprtk_bar_qt/files.py").toString().replace("file://", "")
    readonly property string home: Quickshell.env("HOME") || ""

    property string query: ""
    property string side: "all"   // all | favorites | recents
    property bool plasmaComputer: false
    property string browsePath: "~"
    property string browseParent: ""
    property var browseEntries: []
    property var browseHistory: []
    property string layout: MenuConfig.layout
    readonly property bool isGrid: layout === "win11" || layout === "plasma"

    // Placement within the bar's extent (like the GTK menu: align + position).
    readonly property real screenW: sm.screen ? sm.screen.width : 0
    readonly property real screenH: sm.screen ? sm.screen.height : 0
    readonly property var insets: BarGeom.insets(sm.screenW)
    readonly property int barW: BarGeom.width(sm.screenW)
    readonly property int menuW: Math.min(sm.isGrid ? 760 : MenuConfig.width, sm.barW - 8)
    readonly property int menuH: Math.min(MenuConfig.height, sm.screenH - BarConfig.barHeight - 120)
    readonly property bool atBottom: (MenuConfig.position === "bottom")
        || (MenuConfig.position === "auto" && BarConfig.barPosition === "bottom")
    readonly property real menuX: {
        if (MenuConfig.align === "right")
            return sm.screenW - sm.insets.right - sm.menuW - 4;
        if (MenuConfig.align === "center")
            return Math.round(sm.insets.left + (sm.barW - sm.menuW) / 2);
        return sm.insets.left + 4;
    }
    readonly property real menuY: sm.atBottom
        ? sm.screenH - BarConfig.barHeight - BarConfig.gapOut - MenuConfig.gapIn - sm.menuH
        : BarConfig.barHeight + BarConfig.gapOut + MenuConfig.gapIn

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
        else if (sm.side !== "all")
            list = sm.baseApps().filter(e => sm.entryCategories(e).indexOf(sm.side) >= 0);
        else
            list = sm.baseApps();
        return list;
    }
    function isFavorite(id) {
        return (MenuConfig.favorites || []).indexOf(id) >= 0;
    }

    readonly property var categoryMap: ({
        "Utility": "Accessories", "Accessibility": "Accessories", "Archiving": "Accessories",
        "Development": "Development", "IDE": "Development", "Building": "Development", "Debugger": "Development",
        "Education": "Education", "Science": "Science",
        "Game": "Games", "ActionGame": "Games", "AdventureGame": "Games", "ArcadeGame": "Games",
        "BoardGame": "Games", "CardGame": "Games", "LogicGame": "Games", "SportGame": "Games", "StrategyGame": "Games",
        "Graphics": "Graphics", "2DGraphics": "Graphics", "3DGraphics": "Graphics", "RasterGraphics": "Graphics", "VectorGraphics": "Graphics",
        "Network": "Internet", "WebBrowser": "Internet", "Email": "Internet", "Chat": "Internet", "InstantMessaging": "Internet",
        "AudioVideo": "Multimedia", "Audio": "Multimedia", "Video": "Multimedia", "Music": "Multimedia", "Player": "Multimedia",
        "Office": "Office", "PIM": "Office", "Presentation": "Office", "Spreadsheet": "Office", "WordProcessor": "Office",
        "System": "System", "Monitor": "System", "TerminalEmulator": "System", "FileManager": "System", "Settings": "Settings"
    })
    readonly property var categoryOrder: ["Accessories", "Development", "Education", "Games", "Graphics", "Internet", "Multimedia", "Office", "Science", "Settings", "System"]

    function entryCategories(e) {
        const out = [];
        for (const c of String(e.categories || "").split(";")) {
            const m = sm.categoryMap[c.trim()];
            if (m && out.indexOf(m) < 0)
                out.push(m);
        }
        if (out.length === 0)
            out.push("Accessories");
        return out;
    }
    function categoriesPresent() {
        const have = ({});
        for (const e of sm.baseApps())
            for (const c of sm.entryCategories(e))
                have[c] = true;
        return sm.categoryOrder.filter(c => have[c]);
    }
    function sidebarItems() {
        const base = [
            { key: "all", label: "All Applications" },
            { key: "favorites", label: "Favorites" },
            { key: "recents", label: "Recently Used" }
        ];
        return base.concat(sm.categoriesPresent().map(c => ({ key: c, label: c })));
    }
    readonly property var places: [
        { label: "Documents", glyph: "\uf07b", path: "~/Documents" },
        { label: "Pictures", glyph: "\uf03e", path: "~/Pictures" },
        { label: "Music", glyph: "\uf001", path: "~/Music" },
        { label: "Videos", glyph: "\uf03d", path: "~/Videos" },
        { label: "Computer", glyph: "\uf109", path: "/" }
    ]
    function openPlace(path) {
        UiState.startMenuOpen = false;
        Quickshell.execDetached(["sh", "-c", "xdg-open " + path]);
    }

    // ── plasma file browser ────────────────────────────────────────────
    readonly property var browsePlaces: [
        { label: "Home", path: "~" },
        { label: "Desktop", path: "~/Desktop" },
        { label: "Documents", path: "~/Documents" },
        { label: "Downloads", path: "~/Downloads" },
        { label: "Music", path: "~/Music" },
        { label: "Pictures", path: "~/Pictures" },
        { label: "Videos", path: "~/Videos" },
        { label: "Root", path: "/" }
    ]
    function browseTo(path, push) {
        if (push)
            sm.browseHistory = sm.browseHistory.concat([sm.browsePath]);
        browseProc.command = ["python3", sm.filesBackend, "list", path];
        browseProc.running = true;
    }
    function browseBack() {
        if (sm.browseHistory.length === 0)
            return;
        const h = sm.browseHistory.slice();
        const prev = h.pop();
        sm.browseHistory = h;
        sm.browseTo(prev, false);
    }
    function browseUp() {
        if (sm.browseParent && sm.browseParent !== sm.browsePath)
            sm.browseTo(sm.browseParent, true);
    }
    function openEntry(e) {
        if (e.is_dir)
            sm.browseTo(e.path, true);
        else
            Quickshell.execDetached(["xdg-open", e.path]);
    }
    function fmtSize(b) {
        const units = ["B", "KiB", "MiB", "GiB", "TiB"];
        let v = b, i = 0;
        while (v >= 1024 && i < units.length - 1) {
            v /= 1024;
            i++;
        }
        return (i === 0 ? Math.round(v) : v.toFixed(1)) + " " + units[i];
    }

    Process {
        id: browseProc
        stdout: SplitParser {
            onRead: line => {
                try {
                    const o = JSON.parse(line);
                    sm.browsePath = o.path || "";
                    sm.browseParent = o.parent || "";
                    sm.browseEntries = o.entries || [];
                } catch (e) {}
            }
        }
    }

    property real reveal: 0
    readonly property int animMs: Config.animations ? Config.animationDuration : 0
    Behavior on reveal { NumberAnimation { duration: sm.animMs; easing.type: Easing.OutCubic } }
    onVisibleChanged: {
        sm.reveal = visible ? 1 : 0;
        if (visible) {
            sm.targetScreen = Screens.focused();
            sm.plasmaComputer = false;
            sm.side = "all";
            sm.browseHistory = [];
        }
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
        x: sm.menuX
        y: sm.menuY
        width: sm.menuW
        height: sm.menuH
        radius: 16
        color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, Theme.opacity)
        border.color: Theme.alpha(Theme.accent2, 0.3)
        border.width: 1
        opacity: sm.reveal
        transform: Translate { y: (1 - sm.reveal) * -8 }

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
                TTextField {
                    Layout.fillWidth: true
                    placeholderText: "Search applications\u2026"
                    focus: sm.visible
                    onTextChanged: sm.query = text
                    Keys.onEscapePressed: UiState.startMenuOpen = false
                }
                TButton { text: "Settings"; onClicked: { UiState.startMenuOpen = false; UiState.settingsOpen = true; } }
                TButton { text: "Themer"; onClicked: { UiState.startMenuOpen = false; UiState.themerOpen = true; } }
            }

            RowLayout {
                Layout.fillWidth: true
                visible: layout === "plasma"
                spacing: 6
                Repeater {
                    model: [
                        { key: "apps", label: "Applications" },
                        { key: "computer", label: "Computer" },
                        { key: "recent", label: "Recently Used" }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        implicitWidth: tabText.implicitWidth + 20
                        implicitHeight: 28
                        radius: 6
                        color: {
                            const on = (modelData.key === "computer" && sm.plasmaComputer)
                                || (modelData.key === "recent" && !sm.plasmaComputer && sm.recentsEntries().length > 0 && sm.side === "recents")
                                || (modelData.key === "apps" && !sm.plasmaComputer);
                            return on ? Theme.alpha(Theme.accent, 0.85) : Theme.alpha(Theme.accent2, 0.12);
                        }
                        Text {
                            id: tabText
                            anchors.centerIn: parent
                            text: modelData.label
                            color: Theme.foreground
                            font.pixelSize: 11
                        }
                        TapHandler {
                            onTapped: {
                                if (modelData.key === "computer") {
                                    sm.plasmaComputer = true;
                                    if (sm.browseEntries.length === 0)
                                        sm.browseTo("~", false);
                                } else if (modelData.key === "recent") {
                                    sm.plasmaComputer = false;
                                    sm.side = "recents";
                                } else {
                                    sm.plasmaComputer = false;
                                    sm.side = "all";
                                }
                            }
                        }
                    }
                }
                Item { Layout.fillWidth: true }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12

                // sidebar (whisker / win7)
                ColumnLayout {
                    visible: !sm.isGrid
                    Layout.preferredWidth: MenuConfig.sidebarWidth
                    Layout.minimumWidth: MenuConfig.sidebarWidth
                    Layout.maximumWidth: MenuConfig.sidebarWidth
                    Layout.fillHeight: true
                    spacing: 4
                    Repeater {
                        model: sm.sidebarItems()
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
                                font.family: BarConfig.glyphFont
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
                    visible: sm.isGrid && !(layout === "plasma" && sm.plasmaComputer)
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
                    Layout.minimumWidth: MenuConfig.recentsWidth
                    Layout.maximumWidth: MenuConfig.recentsWidth
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

                // places panel (win7)
                ColumnLayout {
                    visible: layout === "win7"
                    Layout.preferredWidth: MenuConfig.recentsWidth
                    Layout.minimumWidth: MenuConfig.recentsWidth
                    Layout.maximumWidth: MenuConfig.recentsWidth
                    Layout.fillHeight: true
                    spacing: 4
                    Text { text: "Places"; color: Theme.dim; font.pixelSize: 11 }
                    Repeater {
                        model: sm.places
                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: 32
                            radius: 6
                            color: placeHover.hovered ? Theme.alpha(Theme.accent2, 0.15) : "transparent"
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 8
                                Text { text: modelData.glyph; color: Theme.accent; font.family: BarConfig.glyphFont; font.pixelSize: 13 }
                                Text { text: modelData.label; color: Theme.foreground; font.pixelSize: 12; Layout.fillWidth: true }
                            }
                            HoverHandler { id: placeHover }
                            TapHandler { onTapped: sm.openPlace(modelData.path) }
                        }
                    }
                    Item { Layout.fillHeight: true }
                }

                // computer file browser (plasma)
                RowLayout {
                    visible: layout === "plasma" && sm.plasmaComputer
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 12

                    ColumnLayout {
                        Layout.preferredWidth: 150
                        Layout.minimumWidth: 150
                        Layout.maximumWidth: 150
                        Layout.fillHeight: true
                        spacing: 3
                        Repeater {
                            model: sm.browsePlaces
                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: 30
                                radius: 6
                                color: bpHover.hovered ? Theme.alpha(Theme.accent2, 0.15) : "transparent"
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: 10
                                    text: modelData.label
                                    color: Theme.foreground
                                    font.pixelSize: 12
                                }
                                HoverHandler { id: bpHover }
                                TapHandler { onTapped: sm.browseTo(modelData.path, false) }
                            }
                        }
                        Item { Layout.fillHeight: true }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 6
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            TButton { text: "\u2190"; enabled: sm.browseHistory.length > 0; onClicked: sm.browseBack() }
                            TButton { text: "\u2191"; onClicked: sm.browseUp() }
                            Text {
                                Layout.fillWidth: true
                                text: sm.browsePath
                                color: Theme.dim
                                font.pixelSize: 11
                                elide: Text.ElideMiddle
                            }
                        }
                        ListView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            model: sm.browseEntries
                            spacing: 2
                            delegate: Rectangle {
                                id: frow
                                required property var modelData
                                width: ListView.view.width
                                height: 30
                                radius: 6
                                color: frowHover.hovered ? Theme.alpha(Theme.accent2, 0.15) : "transparent"
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    spacing: 8
                                    Text { text: frow.modelData.is_dir ? "\uf07b" : "\uf15b"; color: Theme.accent; font.family: BarConfig.glyphFont; font.pixelSize: 13 }
                                    Text { text: frow.modelData.name; color: Theme.foreground; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
                                    Text {
                                        visible: !frow.modelData.is_dir
                                        text: sm.fmtSize(frow.modelData.size)
                                        color: Theme.dim
                                        font.pixelSize: 10
                                    }
                                }
                                HoverHandler { id: frowHover }
                                TapHandler { onTapped: sm.openEntry(frow.modelData) }
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Text { text: sm.layout; color: Theme.dim; font.pixelSize: 10; Layout.fillWidth: true }
                TButton { text: "Lock"; onClicked: sm.power("lock") }
                TButton { text: "Suspend"; onClicked: sm.power("suspend") }
                TButton { text: "Logout"; onClicked: sm.power("logout") }
                TButton { text: "Reboot"; onClicked: sm.power("reboot") }
                TButton { text: "Shut Down"; onClicked: sm.power("shutdown") }
            }
        }
    }
}
