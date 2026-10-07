// Themer window: sidebar of theming pages — Wallpaper (thumbnail picker),
// Bar Themes (9 shipped themes) and Import (waybar themes from disk).
//
// Wallpaper selection sets the wallpaper and regenerates pywal via the hyprtk
// wallpaper script; bar themes write explicit Theme overrides. Rofi/Lock/Icons/
// SDDM pages are a later pass.
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Io
import "../theme"
import "../config"
import "../state"

FloatingWindow {
    id: win

    title: "hyprtk-bar-qt themer"
    visible: UiState.themerOpen
    implicitWidth: 720
    implicitHeight: 600
    color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, Theme.opacity)

    readonly property string home: Quickshell.env("HOME") || ""
    readonly property string base: Qt.resolvedUrl("../backend/hyprtk_bar_qt/").toString().replace("file://", "")

    readonly property var pages: [
        { key: "wallpaper", glyph: "\uf03e", label: "Wallpaper" },
        { key: "bar", glyph: "\uf1fc", label: "Bar Themes" },
        { key: "import", glyph: "\uf019", label: "Import" }
    ]
    property int page: 0
    readonly property var swatchNames: ["bg", "fg", "accent", "accent2", "dim", "err", "warn"]

    // ── state ──────────────────────────────────────────────────────────
    property var themes: []           // [{name, palette{bg,fg,accent}}]
    property var importable: []       // [{name, path}]
    property var images: []           // wallpaper paths
    property string currentWall: ""
    property string statusMsg: ""
    property string importPath: ""

    function wallDir() {
        return Config.wallpaperDir.length > 0
            ? Config.wallpaperDir
            : win.home + "/Pictures/Wallpapers";
    }

    onVisibleChanged: {
        if (!visible)
            return;
        win.refreshThemes();
        win.refreshImportable();
        win.refreshWallpapers();
        currentProc.running = true;
    }

    function refreshThemes() {
        if (!themeProc.running)
            themeProc.running = true;
    }
    function refreshImportable() {
        if (!installedProc.running)
            installedProc.running = true;
    }
    function refreshWallpapers() {
        scanProc.command = ["python3", win.base + "wallpapers.py", "scan", win.wallDir()];
        scanProc.running = true;
    }
    function toast(msg) {
        win.statusMsg = msg;
        statusTimer.restart();
    }

    Process {
        id: themeProc
        command: ["python3", win.base + "themes.py", "list"]
        stdout: SplitParser {
            onRead: line => {
                try {
                    win.themes = JSON.parse(line).themes || [];
                } catch (e) {
                    win.themes = [];
                }
            }
        }
    }
    Process {
        id: installedProc
        command: ["python3", win.base + "themes.py", "installed"]
        stdout: SplitParser {
            onRead: line => {
                try {
                    win.importable = JSON.parse(line).installed || [];
                } catch (e) {
                    win.importable = [];
                }
            }
        }
    }
    Process {
        id: scanProc
        stdout: SplitParser {
            onRead: line => {
                try {
                    win.images = JSON.parse(line).images || [];
                } catch (e) {
                    win.images = [];
                }
            }
        }
    }
    Process {
        id: currentProc
        command: ["python3", win.base + "wallpapers.py", "current"]
        stdout: SplitParser {
            onRead: line => {
                try {
                    win.currentWall = JSON.parse(line).current || "";
                } catch (e) {
                    win.currentWall = "";
                }
            }
        }
    }
    Process {
        id: applyProc
        onExited: (code, status) => {
            win.toast(code === 0 ? "Applying wallpaper\u2026" : "Could not apply wallpaper");
            currentProc.running = true;
        }
    }
    Process {
        id: importProc
        onExited: (code, status) => {
            win.toast(code === 0 ? "Theme imported" : "Import failed");
            win.refreshThemes();
            win.refreshImportable();
        }
    }
    Process {
        id: removeProc
        onExited: (code, status) => {
            win.refreshThemes();
            win.refreshImportable();
        }
    }

    Timer {
        id: statusTimer
        interval: 3000
        onTriggered: win.statusMsg = ""
    }

    function applyWallpaper(path) {
        applyProc.command = ["python3", win.base + "wallpapers.py", "apply", path];
        applyProc.running = true;
    }
    function applyTheme(t) {
        Config.themeSource = "manual";
        Config.themeName = t.name;
        Config.themeBackground = t.palette.background;
        Config.themeForeground = t.palette.foreground;
        Config.themeAccent = t.palette.accent;
        win.toast("Theme: " + t.name);
    }
    function clearOverrides() {
        Config.themeSource = "";
        Config.themeName = "";
        Config.themeBackground = "";
        Config.themeForeground = "";
        Config.themeAccent = "";
    }
    function doImport(path) {
        if (!path) {
            win.toast("Enter a theme path");
            return;
        }
        importProc.command = ["python3", win.base + "themes.py", "import", path];
        importProc.running = true;
    }
    function doRemove(name) {
        removeProc.command = ["python3", win.base + "themes.py", "remove", name];
        removeProc.running = true;
    }
    function col(name) {
        switch (name) {
        case "bg": return Theme.background;
        case "fg": return Theme.foreground;
        case "accent": return Theme.accent;
        case "accent2": return Theme.accent2;
        case "dim": return Theme.dim;
        case "err": return Theme.err;
        case "warn": return Theme.warn;
        }
        return Theme.foreground;
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ── sidebar ────────────────────────────────────────────────────
        Rectangle {
            Layout.fillHeight: true
            implicitWidth: 150
            color: Theme.alpha(Theme.background, 0.6)
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 4
                Repeater {
                    model: win.pages
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        implicitHeight: 32
                        radius: 8
                        color: win.page === index
                            ? Theme.alpha(Theme.accent, 0.85)
                            : (sbHover.hovered ? Theme.alpha(Theme.accent2, 0.15) : "transparent")
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 8
                            spacing: 8
                            Text { text: modelData.glyph; color: win.page === index ? "#000000" : Theme.accent; font.pixelSize: 13 }
                            Text { text: modelData.label; color: win.page === index ? "#000000" : Theme.foreground; font.pixelSize: 12; Layout.fillWidth: true }
                        }
                        HoverHandler { id: sbHover }
                        TapHandler { onTapped: win.page = index }
                    }
                }
                Item { Layout.fillHeight: true }
            }
        }

        // ── content ────────────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 16
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: win.pages[win.page].label
                    color: Theme.accent
                    font.bold: true
                    font.pixelSize: 15
                    Layout.fillWidth: true
                }
                Text { text: "\u00d7"; color: Theme.dim; font.pixelSize: 18; MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: UiState.themerOpen = false } }
            }

            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: win.page

                // Wallpaper ────────────────────────────────────────────
                ColumnLayout {
                    spacing: 8
                    RowLayout {
                        spacing: 10
                        Image {
                            source: win.currentWall.length ? "file://" + win.currentWall : ""
                            sourceSize.width: 200
                            sourceSize.height: 112
                            Layout.preferredWidth: 200
                            Layout.preferredHeight: 112
                            fillMode: Image.PreserveAspectCrop
                            visible: win.currentWall.length > 0
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            Text { text: "Wallpaper folder"; color: Theme.dim; font.pixelSize: 11 }
                            TextField {
                                Layout.fillWidth: true
                                text: win.wallDir()
                                color: Theme.foreground
                                onEditingFinished: {
                                    Config.wallpaperDir = text;
                                    win.refreshWallpapers();
                                }
                            }
                            Button { text: "Rescan"; onClicked: win.refreshWallpapers() }
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        visible: win.images.length === 0
                        text: "No images in this folder"
                        color: Theme.dim
                        font.pixelSize: 11
                    }
                    Flickable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentHeight: grid.implicitHeight
                        clip: true
                        visible: win.images.length > 0
                        GridLayout {
                            id: grid
                            width: parent.width
                            columns: 4
                            columnSpacing: 8
                            rowSpacing: 8
                            Repeater {
                                model: win.images
                                delegate: Rectangle {
                                    id: thumb
                                    required property var modelData
                                    Layout.fillWidth: true
                                    implicitHeight: 78
                                    radius: 6
                                    color: Theme.alpha(Theme.background, 0.5)
                                    border.width: 1
                                    border.color: thumbHover.hovered ? Theme.accent : Theme.alpha(Theme.accent2, 0.2)
                                    Image {
                                        anchors.fill: parent
                                        anchors.margins: 2
                                        source: "file://" + thumb.modelData
                                        sourceSize.width: 160
                                        sourceSize.height: 72
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                    }
                                    HoverHandler { id: thumbHover }
                                    TapHandler { onTapped: win.applyWallpaper(thumb.modelData) }
                                }
                            }
                        }
                    }
                }

                // Bar Themes ────────────────────────────────────────────
                ColumnLayout {
                    spacing: 6
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Active: " + (Theme.themeName.length ? Theme.themeName : "(pywal)"); color: Theme.foreground; Layout.fillWidth: true }
                        Button { text: "Follow pywal"; onClicked: win.clearOverrides() }
                    }
                    RowLayout {
                        spacing: 6
                        Repeater {
                            model: win.swatchNames
                            delegate: Rectangle {
                                required property string modelData
                                width: 28; height: 28; radius: 6
                                color: win.col(modelData)
                                border.color: Theme.alpha(Theme.foreground, 0.3); border.width: 1
                            }
                        }
                        Item { Layout.fillWidth: true }
                    }
                    Flickable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentHeight: themeList.implicitHeight
                        clip: true
                        ColumnLayout {
                            id: themeList
                            width: parent.width
                            spacing: 3
                            Repeater {
                                model: win.themes
                                delegate: Rectangle {
                                    id: tr
                                    required property var modelData
                                    Layout.fillWidth: true
                                    implicitHeight: 30
                                    radius: 6
                                    color: trHover.hovered ? Theme.alpha(Theme.accent2, 0.15)
                                        : (Theme.themeName === tr.modelData.name ? Theme.alpha(Theme.accent, 0.25) : "transparent")
                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                        spacing: 8
                                        Text { text: tr.modelData.name; color: Theme.foreground; font.pixelSize: 12; Layout.fillWidth: true }
                                        Repeater {
                                            model: [tr.modelData.palette.background, tr.modelData.palette.foreground, tr.modelData.palette.accent]
                                            delegate: Rectangle {
                                                required property var modelData
                                                width: 16; height: 16; radius: 4
                                                color: modelData
                                                border.color: Theme.alpha(Theme.foreground, 0.25); border.width: 1
                                            }
                                        }
                                    }
                                    HoverHandler { id: trHover }
                                    TapHandler { onTapped: win.applyTheme(tr.modelData) }
                                }
                            }
                        }
                    }
                }

                // Import ────────────────────────────────────────────────
                RowLayout {
                    spacing: 12
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Text { text: "Importable themes"; color: Theme.dim; font.pixelSize: 11 }
                        Text {
                            Layout.fillWidth: true
                            visible: win.importable.length === 0
                            text: "None found"
                            color: Theme.dim
                            font.pixelSize: 11
                        }
                        Flickable {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            contentHeight: impList.implicitHeight
                            clip: true
                            ColumnLayout {
                                id: impList
                                width: parent.width
                                spacing: 3
                                Repeater {
                                    model: win.importable
                                    delegate: Rectangle {
                                        id: ir
                                        required property var modelData
                                        Layout.fillWidth: true
                                        implicitHeight: 28
                                        radius: 6
                                        color: irHover.hovered ? Theme.alpha(Theme.accent2, 0.15) : "transparent"
                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 8
                                            anchors.rightMargin: 6
                                            spacing: 8
                                            Text { text: ir.modelData.name; color: Theme.foreground; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
                                            Text { text: ir.modelData.path; color: Theme.dim; font.pixelSize: 9; Layout.preferredWidth: 160; elide: Text.ElideMiddle }
                                            Button { text: "Import"; onClicked: win.doImport(ir.modelData.path) }
                                        }
                                        HoverHandler { id: irHover }
                                    }
                                }
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            TextField {
                                Layout.fillWidth: true
                                placeholderText: "Path to a theme folder or style.css"
                                color: Theme.foreground
                                onTextChanged: win.importPath = text
                            }
                            Button { text: "Import"; onClicked: win.doImport(win.importPath) }
                        }
                    }
                    ColumnLayout {
                        Layout.preferredWidth: 240
                        Layout.fillHeight: true
                        Text { text: "Imported themes"; color: Theme.dim; font.pixelSize: 11 }
                        Flickable {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            contentHeight: haveList.implicitHeight
                            clip: true
                            ColumnLayout {
                                id: haveList
                                width: parent.width
                                spacing: 3
                                Repeater {
                                    model: win.themes
                                    delegate: RowLayout {
                                        required property var modelData
                                        Layout.fillWidth: true
                                        Text { text: modelData.name; color: Theme.foreground; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
                                        Button { text: "\u2715"; onClicked: win.doRemove(modelData.name) }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Text { text: "Bar opacity"; color: Theme.foreground }
                Slider {
                    Layout.preferredWidth: 160
                    from: 0.2; to: 1.0; stepSize: 0.01
                    value: Config.opacity >= 0 ? Config.opacity : Theme.opacity
                    onMoved: Config.opacity = value
                }
                Text { text: win.statusMsg; color: Theme.accent; font.pixelSize: 10; Layout.fillWidth: true; elide: Text.ElideRight }
                Button { text: "Save"; onClicked: Config.save() }
                Button { text: "Close"; onClicked: UiState.themerOpen = false }
            }
        }
    }
}
