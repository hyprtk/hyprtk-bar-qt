// Themer window: sidebar of theming pages — Wallpaper (thumbnail picker),
// Pywal, Rofi, Bar Themes (9 shipped), Matuwall, Lock Screen, Icons,
// SDDM & GRUB, and Import (waybar themes from disk).
//
// Script-driven actions call the same hyprtk scripts as the GTK bar. The
// Matuwall TOML editor is a later pass.
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Io
import "../theme"
import "../config"
import "../state"
import "../components"

FloatingWindow {
    id: win

    title: "hyprtk-bar-qt themer"
    visible: UiState.themerOpen
    implicitWidth: 760
    implicitHeight: 620
    color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, Theme.opacity)

    readonly property string home: Quickshell.env("HOME") || ""
    readonly property string base: Qt.resolvedUrl("../backend/hyprtk_bar_qt/").toString().replace("file://", "")
    readonly property string scripts: win.home + "/.local/share/hyprtk-bar/scripts"

    readonly property var pages: [
        { key: "wallpaper", glyph: "\uf03e", label: "Wallpaper" },
        { key: "pywal", glyph: "\uf043", label: "Pywal" },
        { key: "rofi", glyph: "\uf009", label: "Rofi" },
        { key: "bar", glyph: "\uf1fc", label: "Bar Themes" },
        { key: "matuwall", glyph: "\uf1c5", label: "Matuwall" },
        { key: "swaylock", glyph: "\uf023", label: "Lock Screen" },
        { key: "icons", glyph: "\uf02d", label: "Icons" },
        { key: "sddm", glyph: "\uf005", label: "SDDM & GRUB" },
        { key: "import", glyph: "\uf019", label: "Import" }
    ]
    property int page: 0
    readonly property var swatchNames: ["bg", "fg", "accent", "accent2", "dim", "err", "warn"]

    property var themes: []
    property var importable: []
    property var images: []
    property string currentWall: ""
    property var rofiVariants: []
    property string rofiActive: ""
    property string statusMsg: ""
    property string importPath: ""
    property string lockConf: ""
    property string iconHex: "#2196F3"
    property var mwConfig: ({})
    property var mwSections: []

    function wallDir() {
        return Config.wallpaperDir.length > 0 ? Config.wallpaperDir : win.home + "/Pictures/Wallpapers";
    }

    property real reveal: 0
    readonly property int animMs: Config.animations ? Config.animationDuration : 0
    Behavior on reveal { NumberAnimation { duration: win.animMs; easing.type: Easing.OutCubic } }

    onVisibleChanged: {
        win.reveal = visible ? 1 : 0;
        if (!visible)
            return;
        win.refreshThemes();
        win.refreshImportable();
        win.refreshWallpapers();
        win.refreshRofi();
        currentProc.running = true;
        lockFile.reload();
        mwGetProc.running = true;
    }

    function toast(msg) {
        win.statusMsg = msg;
        statusTimer.restart();
    }
    function refreshThemes() { if (!themeProc.running) themeProc.running = true; }
    function refreshImportable() { if (!installedProc.running) installedProc.running = true; }
    function refreshWallpapers() {
        scanProc.command = ["python3", win.base + "wallpapers.py", "scan", win.wallDir()];
        scanProc.running = true;
    }
    function refreshRofi() {
        win.rofiVariants = [];
        win.rofiActive = "";
        rofiProc.running = true;
    }

    Process {
        id: themeProc
        command: ["python3", win.base + "themes.py", "list"]
        stdout: SplitParser {
            onRead: line => {
                try { win.themes = JSON.parse(line).themes || []; } catch (e) { win.themes = []; }
            }
        }
    }
    Process {
        id: installedProc
        command: ["python3", win.base + "themes.py", "installed"]
        stdout: SplitParser {
            onRead: line => {
                try { win.importable = JSON.parse(line).installed || []; } catch (e) { win.importable = []; }
            }
        }
    }
    Process {
        id: scanProc
        stdout: SplitParser {
            onRead: line => {
                try { win.images = JSON.parse(line).images || []; } catch (e) { win.images = []; }
            }
        }
    }
    Process {
        id: currentProc
        command: ["python3", win.base + "wallpapers.py", "current"]
        stdout: SplitParser {
            onRead: line => {
                try { win.currentWall = JSON.parse(line).current || ""; } catch (e) { win.currentWall = ""; }
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
        onExited: (code, status) => { win.refreshThemes(); win.refreshImportable(); }
    }
    Process {
        id: rofiProc
        command: ["bash", "-c",
            "printf 'LINK=%s\\n' \"$(readlink ~/.config/rofi/variant.rasi 2>/dev/null)\"; " +
            "ls -1 ~/.local/share/hyprtk-bar/scripts/rofi/variants/*.rasi 2>/dev/null || " +
            "ls -1 ~/.config/rofi/variants/*.rasi 2>/dev/null"]
        stdout: SplitParser {
            onRead: line => {
                if (line.startsWith("LINK=")) {
                    const p = line.substring(5);
                    win.rofiActive = p.length ? p.split("/").pop().replace(/\.rasi$/, "") : "";
                } else if (line.endsWith(".rasi")) {
                    win.rofiVariants = win.rofiVariants.concat([{ name: line.split("/").pop().replace(/\.rasi$/, ""), path: line }]);
                }
            }
        }
    }
    FileView {
        id: lockFile
        path: win.home + "/.cache/wal/hyprlock-colors.conf"
        watchChanges: true
        printErrors: false
        onLoaded: win.lockConf = lockFile.text()
        onTextChanged: win.lockConf = lockFile.text()
        onFileChanged: reload()
    }
    Timer { id: statusTimer; interval: 3000; onTriggered: win.statusMsg = "" }

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
        if (!path) { win.toast("Enter a theme path"); return; }
        importProc.command = ["python3", win.base + "themes.py", "import", path];
        importProc.running = true;
    }
    function doRemove(name) {
        removeProc.command = ["python3", win.base + "themes.py", "remove", name];
        removeProc.running = true;
    }
    function applyRofi(path) {
        Quickshell.execDetached(["bash", "-c",
            "ln -sf '" + path + "' ~/.config/rofi/variant.rasi && bash '" + win.scripts + "/sync-rofi-theme.sh'"]);
        win.toast("Rofi variant: " + path.split("/").pop().replace(/\.rasi$/, ""));
        rofiRefresh.restart();
    }
    function regenRofi() {
        Quickshell.execDetached(["bash", win.scripts + "/sync-rofi-theme.sh"]);
        win.toast("Regenerating rofi variant\u2026");
        rofiRefresh.restart();
    }
    function lockColors() {
        const lines = (win.lockConf || "").split("\n").filter(l => l.trim().startsWith("$lock_"));
        return lines.length ? lines.join("\n") : "No pywal colours rendered yet \u2014 pick a wallpaper first.";
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

    Timer { id: rofiRefresh; interval: 800; onTriggered: win.refreshRofi() }

    // ── matuwall ───────────────────────────────────────────────────────
    Process {
        id: mwGetProc
        command: ["python3", win.base + "matuwall.py", "get"]
        stdout: SplitParser {
            onRead: line => {
                try {
                    const o = JSON.parse(line);
                    win.mwConfig = o.config || ({});
                    win.mwSections = o.sections || [];
                } catch (e) {}
            }
        }
    }
    Process {
        id: mwSetProc
        onExited: (code, status) => win.toast(code === 0 ? "Matuwall config saved" : "Save failed")
    }
    function mwValue(section, key) {
        let node = win.mwConfig;
        for (const p of section.split(".")) {
            if (!node || typeof node !== "object")
                return undefined;
            node = node[p];
        }
        return node ? node[key] : undefined;
    }
    function mwSet(section, key, value) {
        const c = JSON.parse(JSON.stringify(win.mwConfig || ({})));
        let node = c;
        for (const p of section.split("."))
            node = (node[p] = node[p] || ({}));
        node[key] = value;
        win.mwConfig = c;
    }
    function mwIdx(choices, v) {
        const i = (choices || []).indexOf(v);
        return i < 0 ? 0 : i;
    }
    function mwSave() {
        mwSetProc.command = ["python3", win.base + "matuwall.py", "set", "--json", JSON.stringify(win.mwConfig || ({}))];
        mwSetProc.running = true;
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0
        opacity: win.reveal
        transform: Translate { y: (1 - win.reveal) * -8 }

        Rectangle {
            Layout.fillHeight: true
            implicitWidth: 150
            color: Theme.alpha(Theme.background, 0.6)
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 3
                Repeater {
                    model: win.pages
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        implicitHeight: 30
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

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 16
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                Text { text: win.pages[win.page].label; color: Theme.accent; font.bold: true; font.pixelSize: 15; Layout.fillWidth: true }
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
                            TTextField {
                                Layout.fillWidth: true
                                text: win.wallDir()
                                color: Theme.foreground
                                onEditingFinished: { Config.wallpaperDir = text; win.refreshWallpapers(); }
                            }
                            TButton { text: "Rescan"; onClicked: win.refreshWallpapers() }
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

                // Pywal ────────────────────────────────────────────────
                ColumnLayout {
                    spacing: 10
                    Text { text: "Live pywal palette"; color: Theme.dim; font.pixelSize: 11 }
                    RowLayout {
                        spacing: 6
                        Repeater {
                            model: win.swatchNames
                            delegate: Rectangle {
                                required property string modelData
                                width: 34; height: 34; radius: 8
                                color: win.col(modelData)
                                border.color: Theme.alpha(Theme.foreground, 0.3); border.width: 1
                            }
                        }
                        Item { Layout.fillWidth: true }
                    }
                    RowLayout {
                        spacing: 8
                        TButton {
                            text: "Regenerate from wallpaper"
                            onClicked: {
                                Quickshell.execDetached(["bash", win.scripts + "/updatewal-awww.sh"]);
                                win.toast("Regenerating palette\u2026");
                            }
                        }
                        Item { Layout.fillWidth: true }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: "Regenerating re-runs pywal on the current wallpaper and updates every themed app."
                        color: Theme.dim
                        font.pixelSize: 10
                        wrapMode: Text.WordWrap
                    }
                    Item { Layout.fillHeight: true }
                }

                // Rofi ─────────────────────────────────────────────────
                ColumnLayout {
                    spacing: 8
                    Text { text: "Active variant: " + (win.rofiActive.length ? win.rofiActive : "(none)"); color: Theme.foreground; font.pixelSize: 12 }
                    Flickable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentHeight: rofiList.implicitHeight
                        clip: true
                        ColumnLayout {
                            id: rofiList
                            width: parent.width
                            spacing: 3
                            Repeater {
                                model: win.rofiVariants
                                delegate: Rectangle {
                                    id: rr
                                    required property var modelData
                                    Layout.fillWidth: true
                                    implicitHeight: 28
                                    radius: 6
                                    color: rrHover.hovered ? Theme.alpha(Theme.accent2, 0.15)
                                        : (win.rofiActive === rr.modelData.name ? Theme.alpha(Theme.accent, 0.25) : "transparent")
                                    Text { anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 10; text: rr.modelData.name; color: Theme.foreground; font.pixelSize: 12 }
                                    HoverHandler { id: rrHover }
                                    TapHandler { onTapped: win.applyRofi(rr.modelData.path) }
                                }
                            }
                        }
                    }
                    TButton { text: "Regenerate from Pywal"; onClicked: win.regenRofi() }
                }

                // Bar Themes ────────────────────────────────────────────
                ColumnLayout {
                    spacing: 6
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Active: " + (Theme.themeName.length ? Theme.themeName : "(pywal)"); color: Theme.foreground; Layout.fillWidth: true }
                        TButton { text: "Follow pywal"; onClicked: win.clearOverrides() }
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

                // Matuwall ──────────────────────────────────────────────
                ColumnLayout {
                    spacing: 8
                    Flickable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentHeight: mwCol.implicitHeight
                        clip: true
                        ColumnLayout {
                            id: mwCol
                            width: parent.width
                            spacing: 8
                            Repeater {
                                model: win.mwSections
                                delegate: ColumnLayout {
                                    id: mwSec
                                    required property var modelData
                                    Layout.fillWidth: true
                                    spacing: 4
                                    Text { text: mwSec.modelData.title; color: Theme.accent; font.bold: true; font.pixelSize: 12 }
                                    Repeater {
                                        model: mwSec.modelData.fields
                                        delegate: RowLayout {
                                            id: mwRow
                                            required property var modelData
                                            Layout.fillWidth: true
                                            spacing: 8
                                            Text {
                                                text: mwRow.modelData.label
                                                color: Theme.foreground
                                                font.pixelSize: 11
                                                Layout.preferredWidth: 170
                                                elide: Text.ElideRight
                                            }
                                            // bool
                                            TCheckBox {
                                                visible: mwRow.modelData.kind === "bool"
                                                checked: win.mwValue(mwSec.modelData.section, mwRow.modelData.key) === true
                                                onToggled: win.mwSet(mwSec.modelData.section, mwRow.modelData.key, checked)
                                            }
                                            // choice
                                            TComboBox {
                                                visible: mwRow.modelData.kind === "choice"
                                                model: mwRow.modelData.choices
                                                currentIndex: win.mwIdx(mwRow.modelData.choices, win.mwValue(mwSec.modelData.section, mwRow.modelData.key))
                                                onActivated: win.mwSet(mwSec.modelData.section, mwRow.modelData.key, model[currentIndex])
                                            }
                                            // str / int / list
                                            TTextField {
                                                visible: mwRow.modelData.kind !== "bool" && mwRow.modelData.kind !== "choice"
                                                Layout.fillWidth: true
                                                color: Theme.foreground
                                                text: {
                                                    const v = win.mwValue(mwSec.modelData.section, mwRow.modelData.key);
                                                    if (v === undefined || v === null)
                                                        return "";
                                                    return Array.isArray(v) ? v.join(", ") : String(v);
                                                }
                                                onEditingFinished: {
                                                    const kind = mwRow.modelData.kind;
                                                    if (kind === "int")
                                                        win.mwSet(mwSec.modelData.section, mwRow.modelData.key, parseInt(text) || 0);
                                                    else if (kind === "list")
                                                        win.mwSet(mwSec.modelData.section, mwRow.modelData.key, text.split(",").map(s => s.trim()).filter(s => s.length));
                                                    else
                                                        win.mwSet(mwSec.modelData.section, mwRow.modelData.key, text);
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Writes through the pywal symlink; colour keys stay live."; color: Theme.dim; font.pixelSize: 10; Layout.fillWidth: true }
                        TButton { text: "Save Matuwall"; onClicked: win.mwSave() }
                    }
                }

                // Lock Screen ───────────────────────────────────────────
                ColumnLayout {
                    spacing: 10
                    Text {
                        Layout.fillWidth: true
                        text: "hyprlock is themed from your wallpaper automatically: pywal renders the lock colours to ~/.cache/wal/hyprlock-colors.conf and hyprlock.conf sources them."
                        color: Theme.foreground
                        font.pixelSize: 11
                        wrapMode: Text.WordWrap
                    }
                    TButton {
                        text: "Re-apply Pywal Theme"
                        onClicked: {
                            Quickshell.execDetached(["wal", "-R", "-q"]);
                            win.toast("Re-applying pywal theme");
                            lockFile.reload();
                        }
                    }
                    Text { text: "Current colours"; color: Theme.dim; font.pixelSize: 11 }
                    Text {
                        Layout.fillWidth: true
                        text: win.lockColors()
                        color: Theme.dim
                        font.pixelSize: 10
                        wrapMode: Text.WordWrap
                    }
                    Item { Layout.fillHeight: true }
                }

                // Icons ─────────────────────────────────────────────────
                ColumnLayout {
                    spacing: 10
                    Text { text: "Papirus folder colour"; color: Theme.dim; font.pixelSize: 11 }
                    TButton {
                        text: "Apply pywal colour match"
                        onClicked: {
                            Quickshell.execDetached(["bash", win.scripts + "/change-icons.sh"]);
                            win.toast("Applying pywal folder colour match");
                        }
                    }
                    RowLayout {
                        spacing: 8
                        TTextField {
                            Layout.preferredWidth: 140
                            text: win.iconHex
                            color: Theme.foreground
                            onEditingFinished: win.iconHex = text
                        }
                        TButton {
                            text: "Apply custom hex"
                            onClicked: {
                                const hex = win.iconHex.replace(/^#/, "");
                                Quickshell.execDetached(["papirus-folders", "-C", hex, "-t", "Papirus-Dark"]);
                                win.toast("Folder colour: #" + hex);
                            }
                        }
                        Item { Layout.fillWidth: true }
                    }
                    Text { text: "Sets the Papirus-Dark folder colour (needs papirus-folders on PATH)."; color: Theme.dim; font.pixelSize: 10 }
                    Item { Layout.fillHeight: true }
                }

                // SDDM & GRUB ───────────────────────────────────────────
                ColumnLayout {
                    spacing: 10
                    Text {
                        Layout.fillWidth: true
                        text: "Update the login screen (SDDM) and bootloader (GRUB) with your current wallpaper. Runs as root via pkexec."
                        color: Theme.foreground
                        font.pixelSize: 11
                        wrapMode: Text.WordWrap
                    }
                    Image {
                        source: win.currentWall.length ? "file://" + win.currentWall : ""
                        sourceSize.width: 260
                        sourceSize.height: 146
                        Layout.preferredWidth: 260
                        Layout.preferredHeight: 146
                        fillMode: Image.PreserveAspectCrop
                        Layout.alignment: Qt.AlignHCenter
                        visible: win.currentWall.length > 0
                    }
                    RowLayout {
                        spacing: 8
                        TButton {
                            text: "Update SDDM & GRUB Wallpaper"
                            onClicked: {
                                Quickshell.execDetached(["pkexec", "bash", win.home + "/hyprtk/configs/sddm/update.sh"]);
                                win.toast("Updating SDDM & GRUB\u2026");
                            }
                        }
                        Item { Layout.fillWidth: true }
                    }
                    Item { Layout.fillHeight: true }
                }

                // Import ────────────────────────────────────────────────
                RowLayout {
                    spacing: 12
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Text { text: "Importable themes"; color: Theme.dim; font.pixelSize: 11 }
                        Text { Layout.fillWidth: true; visible: win.importable.length === 0; text: "None found"; color: Theme.dim; font.pixelSize: 11 }
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
                                            Text { text: ir.modelData.path; color: Theme.dim; font.pixelSize: 9; Layout.preferredWidth: 150; elide: Text.ElideMiddle }
                                            TButton { text: "Import"; onClicked: win.doImport(ir.modelData.path) }
                                        }
                                        HoverHandler { id: irHover }
                                    }
                                }
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            TTextField {
                                Layout.fillWidth: true
                                placeholderText: "Path to a theme folder or style.css"
                                color: Theme.foreground
                                onTextChanged: win.importPath = text
                            }
                            TButton { text: "Import"; onClicked: win.doImport(win.importPath) }
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
                                        TButton { text: "\u2715"; onClicked: win.doRemove(modelData.name) }
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
                TSlider {
                    Layout.preferredWidth: 160
                    from: 0.2; to: 1.0; stepSize: 0.01
                    value: Config.opacity >= 0 ? Config.opacity : Theme.opacity
                    onMoved: Config.opacity = value
                }
                Text { text: win.statusMsg; color: Theme.accent; font.pixelSize: 10; Layout.fillWidth: true; elide: Text.ElideRight }
                TButton { text: "Save"; onClicked: Config.save() }
                TButton { text: "Close"; onClicked: UiState.themerOpen = false }
            }
        }
    }
}
