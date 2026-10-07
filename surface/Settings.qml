// Settings window — nine pages editing the shared hyprtk-bar config
// (~/.config/hyprtk-bar/config.json), so the Qt and GTK bars share settings.
//
// Bar / Themes / Fonts / Animations / Arc Menu / Menu / Quicklinks / Modules /
// Widgets. Changes are debounced and written via backend/.../barsettings.py.
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Io
import "../theme"
import "../config"
import "../state"
import "../data"
import "../components"

FloatingWindow {
    id: win

    title: "hyprtk-bar-qt settings"
    visible: UiState.settingsOpen
    implicitWidth: 820
    implicitHeight: 620
    color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, Math.max(0.95, Theme.opacity))

    property real reveal: 0
    readonly property int animMs: Config.animations ? Config.animationDuration : 0
    Behavior on reveal { NumberAnimation { duration: win.animMs; easing.type: Easing.OutCubic } }
    onVisibleChanged: reveal = visible ? 1 : 0

    readonly property string backend:
        Qt.resolvedUrl("../backend/hyprtk_bar_qt/barsettings.py").toString().replace("file://", "")

    property int page: 0
    readonly property var pageNames: ["Bar", "Themes", "Fonts", "Animations", "Arc Menu", "Menu", "Quicklinks", "Modules", "Widgets"]
    readonly property var arcPositions: ["top-left", "top-center", "top-right", "bottom-left", "bottom-center", "bottom-right"]
    readonly property var moduleIds: ["start_button", "quicklinks", "workspaces", "tasklist", "window", "updates", "net", "tray", "kbstate", "notifications", "clock", "sysmon", "arcmenu", "themer", "settings", "quicksettings"]
    readonly property var widgetIds: ["clock", "weather", "visualizer", "disk", "network", "resources", "sysinfo"]

    // ── debounced shared-config writer ─────────────────────────────────
    property var pending: ({})
    Timer { id: flushTimer; interval: 200; onTriggered: win.flush() }
    Process { id: setProc; onExited: (code, status) => {} }

    function set(path, value) {
        const parts = String(path).split(".");
        let node = win.pending;
        for (let i = 0; i < parts.length - 1; i++)
            node = (node[parts[i]] = node[parts[i]] || ({}));
        node[parts[parts.length - 1]] = value;
        flushTimer.restart();
    }
    function flush() {
        if (Object.keys(win.pending).length === 0)
            return;
        const patch = win.pending;
        win.pending = ({});
        setProc.command = ["python3", win.backend, "set", "--json", JSON.stringify(patch)];
        setProc.running = true;
    }
    // Read a dotted path from the shared config.
    function g(path, fallback) {
        let node = BarConfig.cfg;
        for (const p of String(path).split(".")) {
            if (node === null || node === undefined)
                return fallback;
            node = node[p];
        }
        return (node === undefined || node === null) ? fallback : node;
    }
    function idx(list, v) {
        const i = (list || []).indexOf(v);
        return i < 0 ? 0 : i;
    }

    // ── layout (modules) helpers ───────────────────────────────────────
    function sectionOf(id) {
        if ((BarConfig.layoutLeft || []).indexOf(id) >= 0) return "left";
        if ((BarConfig.layoutCenter || []).indexOf(id) >= 0) return "center";
        if ((BarConfig.layoutRight || []).indexOf(id) >= 0) return "right";
        return "";
    }
    function setSection(id, section) {
        const clean = (list) => (list || []).filter(x => x !== id);
        let L = clean(BarConfig.layoutLeft);
        let C = clean(BarConfig.layoutCenter);
        let R = clean(BarConfig.layoutRight);
        if (section === "left") L.push(id);
        else if (section === "center") C.push(id);
        else if (section === "right") R.push(id);
        win.set("layout", { left: L, center: C, right: R });
    }
    function moduleEnabledBlock(id) {
        const map = {
            start_button: "center", themer: "themer", quicklinks: "quicklinks",
            workspaces: "workspaces", window: "window", updates: "updates",
            tray: "tray", notifications: "notifications", clock: "clock",
            sysmon: "sysmon", arcmenu: "arcmenu", quicksettings: "quicksettings"
        };
        return map[id] || "";
    }

    // ── quicklinks helpers ─────────────────────────────────────────────
    function links() { return win.g("quicklinks.links", []); }
    function setLink(i, field, value) {
        const arr = JSON.parse(JSON.stringify(win.links()));
        arr[i][field] = value;
        win.set("quicklinks.links", arr);
    }
    function addLink() {
        const arr = JSON.parse(JSON.stringify(win.links()));
        arr.push({ id: "custom" + arr.length, label: "", icon: "\uf013", command: "", command_right: "", command_middle: "" });
        win.set("quicklinks.links", arr);
    }
    function removeLink(i) {
        const arr = JSON.parse(JSON.stringify(win.links()));
        arr.splice(i, 1);
        win.set("quicklinks.links", arr);
    }

    // ── widgets helpers ────────────────────────────────────────────────
    function widgetVal(id, key, fallback) { return win.g("widgets." + id + "." + key, fallback); }
    function setWidget(id, key, value) { win.set("widgets." + id + "." + key, value); }
    function cloneArr(a) { return JSON.parse(JSON.stringify(a || [])); }
    function widgetStyles(id) {
        if (id === "clock")
            return ["digital", "text", "dials"];
        if (id === "visualizer")
            return ["bars", "wave", "mirror", "dots", "glow"];
        return [];
    }
    function hasColors(id) {
        return ["clock", "weather", "visualizer", "disk", "network", "resources", "sysinfo"].indexOf(id) >= 0;
    }

    // ── arc menu item editor ───────────────────────────────────────────
    function arcItems() { return win.g("arcmenu.items", []); }
    function setArcItem(i, field, value) {
        const a = win.cloneArr(win.arcItems());
        a[i][field] = value;
        win.set("arcmenu.items", a);
    }
    function addArcItem() {
        const a = win.cloneArr(win.arcItems());
        a.push({ glyph: "\uf013", command: "", tooltip: "", action: "" });
        win.set("arcmenu.items", a);
    }
    function removeArcItem(i) {
        const a = win.cloneArr(win.arcItems());
        a.splice(i, 1);
        win.set("arcmenu.items", a);
    }
    function moveArcItem(i, dir) {
        const a = win.cloneArr(win.arcItems());
        const j = i + dir;
        if (j < 0 || j >= a.length)
            return;
        const t = a[i]; a[i] = a[j]; a[j] = t;
        win.set("arcmenu.items", a);
    }

    // ── menu power + favourites ────────────────────────────────────────
    readonly property var powerKeys: ["lock", "logout", "reboot", "shutdown", "suspend", "hibernate"]
    function powerVal(k) { return win.g("menu.power." + k, ""); }
    function setPower(k, v) { win.set("menu.power", { [k]: v }); }
    function favorites() { return win.g("menu.favorites", []); }
    function removeFavorite(i) {
        const a = win.cloneArr(win.favorites());
        a.splice(i, 1);
        win.set("menu.favorites", a);
    }
    function addFavorite(id) {
        if (!id) return;
        const a = win.cloneArr(win.favorites());
        if (a.indexOf(id) < 0) a.push(id);
        win.set("menu.favorites", a);
    }

    // ── reusable row ───────────────────────────────────────────────────
    component SRow: RowLayout {
        id: r
        default property alias content: r.data
        Layout.fillWidth: true
        spacing: 8
        property string label: ""
        Text {
            text: r.label
            color: Theme.foreground
            font.pixelSize: 12
            Layout.preferredWidth: 150
            elide: Text.ElideRight
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0
        opacity: win.reveal
        transform: Translate { y: (1 - win.reveal) * -8 }

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
                    model: win.pageNames
                    delegate: Rectangle {
                        required property string modelData
                        required property int index
                        Layout.fillWidth: true
                        implicitHeight: 32
                        radius: 8
                        color: win.page === index
                            ? Theme.alpha(Theme.accent, 0.85)
                            : (sbHover.hovered ? Theme.alpha(Theme.accent2, 0.15) : "transparent")
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            text: modelData
                            color: win.page === index ? "#000000" : Theme.foreground
                            font.pixelSize: 12
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
            spacing: 12

            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: win.page

                // Bar ──────────────────────────────────────────────────
                Flickable {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    contentHeight: barCol.implicitHeight; clip: true
                    ColumnLayout {
                        id: barCol
                        width: parent.width
                        spacing: 8
                        SRow {
                            label: "Position"
                            TComboBox {
                                model: ["top", "bottom"]
                                currentIndex: win.idx(model, win.g("position", "top"))
                                onActivated: win.set("position", model[currentIndex])
                            }
                        }
                        SRow {
                            label: "Height"
                            TSpinBox { from: 20; to: 120; value: win.g("height", 38); onValueChanged: win.set("height", value) }
                        }
                        SRow {
                            label: "Width (% or px)"
                            TTextField { Layout.preferredWidth: 120; text: win.g("width", "75%"); onEditingFinished: win.set("width", text) }
                        }
                        SRow {
                            label: "Align"
                            TComboBox {
                                model: ["left", "center", "right"]
                                currentIndex: win.idx(model, win.g("align", "center"))
                                onActivated: win.set("align", model[currentIndex])
                            }
                        }
                        SRow {
                            label: "Gap in (bar\u2194windows)"
                            TSpinBox { from: 0; to: 60; value: win.g("gap_in", 0); onValueChanged: win.set("gap_in", value) }
                        }
                        SRow {
                            label: "Gap out (bar\u2194edge)"
                            TSpinBox { from: 0; to: 60; value: win.g("gap_out", 0); onValueChanged: win.set("gap_out", value) }
                        }
                        SRow {
                            label: "Corner radius"
                            TSpinBox { from: 0; to: 40; value: win.g("radius", 12); onValueChanged: win.set("radius", value) }
                        }
                        SRow {
                            label: "Opacity"
                            TSlider {
                                Layout.preferredWidth: 200
                                from: 0.2; to: 1.0; stepSize: 0.01
                                value: win.g("opacity", 0.75)
                                onMoved: win.set("opacity", value)
                            }
                            Text { text: Math.round(win.g("opacity", 0.75) * 100) + "%"; color: Theme.dim; font.pixelSize: 11 }
                        }
                        Item { Layout.fillHeight: true }
                    }
                }

                // Themes ────────────────────────────────────────────────
                Flickable {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    contentHeight: thCol.implicitHeight; clip: true
                    ColumnLayout {
                        id: thCol
                        width: parent.width
                        spacing: 8
                        SRow {
                            label: "Source"
                            TComboBox {
                                model: ["pywal", "manual", ""]
                                currentIndex: win.idx(["pywal", "manual", ""], win.g("theme.source", "pywal"))
                                onActivated: win.set("theme.source", model[currentIndex])
                            }
                        }
                        SRow {
                            label: "Theme name"
                            TTextField { Layout.fillWidth: true; text: win.g("theme.theme_name", ""); onEditingFinished: win.set("theme.theme_name", text) }
                        }
                        SRow {
                            label: "Background"
                            TTextField { Layout.fillWidth: true; placeholderText: "#1a1b26"; text: win.g("theme.background", ""); onEditingFinished: win.set("theme.background", text) }
                        }
                        SRow {
                            label: "Foreground"
                            TTextField { Layout.fillWidth: true; placeholderText: "#c0caf5"; text: win.g("theme.foreground", ""); onEditingFinished: win.set("theme.foreground", text) }
                        }
                        SRow {
                            label: "Accent"
                            TTextField { Layout.fillWidth: true; placeholderText: "#7aa2f7"; text: win.g("theme.accent", ""); onEditingFinished: win.set("theme.accent", text) }
                        }
                        SRow {
                            label: "Border animation"
                            TCheckBox { checked: win.g("theme.border_animation", true); onToggled: win.set("theme.border_animation", checked) }
                        }
                        SRow {
                            label: "Swatches"
                            Repeater {
                                model: [Theme.background, Theme.foreground, Theme.accent, Theme.accent2, Theme.dim, Theme.err, Theme.warn]
                                delegate: Rectangle {
                                    required property var modelData
                                    width: 30; height: 30; radius: 6; color: modelData
                                    border.color: Theme.alpha(Theme.foreground, 0.3); border.width: 1
                                }
                            }
                            Item { Layout.fillWidth: true }
                        }
                        Item { Layout.fillHeight: true }
                    }
                }

                // Fonts ─────────────────────────────────────────────────
                Flickable {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    contentHeight: fnCol.implicitHeight; clip: true
                    ColumnLayout {
                        id: fnCol
                        width: parent.width
                        spacing: 8
                        SRow {
                            label: "Family (blank = sys)"
                            TTextField { Layout.fillWidth: true; text: win.g("font.family", ""); onEditingFinished: win.set("font.family", text) }
                        }
                        SRow {
                            label: "Size (px)"
                            TSpinBox { from: 8; to: 40; value: win.g("font.size", 12); onValueChanged: win.set("font.size", value) }
                        }
                        SRow {
                            label: "Icon size (0=auto)"
                            TSpinBox { from: 0; to: 48; value: win.g("font.icon_size", 0); onValueChanged: win.set("font.icon_size", value) }
                        }
                        SRow {
                            label: "Quicklink icons"
                            TSpinBox { from: 0; to: 48; value: win.g("quicklinks.icon_size", 0); onValueChanged: win.set("quicklinks.icon_size", value) }
                        }
                        Item { Layout.fillHeight: true }
                    }
                }

                // Animations ────────────────────────────────────────────
                Flickable {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    contentHeight: anCol.implicitHeight; clip: true
                    ColumnLayout {
                        id: anCol
                        width: parent.width
                        spacing: 8
                        Text {
                            Layout.fillWidth: true
                            text: "Animate the bar's border colour. Low/High follow Hyprland's animation files; Custom is independent."
                            color: Theme.dim; font.pixelSize: 11; wrapMode: Text.WordWrap
                        }
                        SRow {
                            label: "Animated border"
                            TCheckBox { checked: win.g("theme.border_animation", true); onToggled: win.set("theme.border_animation", checked) }
                        }
                        SRow {
                            label: "Mode"
                            TComboBox {
                                model: ["low", "high", "custom"]
                                currentIndex: win.idx(model, win.g("animations.mode", "high"))
                                onActivated: win.set("animations.mode", model[currentIndex])
                            }
                        }
                        SRow {
                            label: "Custom speed"
                            TSpinBox { from: 1; to: 200; value: win.g("animations.speed", 15); onValueChanged: win.set("animations.speed", value) }
                        }
                        SRow {
                            label: "UI animations"
                            TCheckBox { checked: Config.animations; onToggled: Config.animations = checked }
                        }
                        Item { Layout.fillHeight: true }
                    }
                }

                // Arc Menu ──────────────────────────────────────────────
                Flickable {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    contentHeight: arcCol.implicitHeight; clip: true
                    ColumnLayout {
                        id: arcCol
                        width: parent.width
                        spacing: 8
                        SRow {
                            label: "Enabled"
                            TCheckBox { checked: win.g("arcmenu.enabled", true); onToggled: win.set("arcmenu.enabled", checked) }
                        }
                        SRow {
                            label: "Position"
                            TComboBox {
                                model: win.arcPositions
                                currentIndex: win.idx(win.arcPositions, win.g("arcmenu.position", "bottom-right"))
                                onActivated: win.set("arcmenu.position", model[currentIndex])
                            }
                        }
                        SRow {
                            label: "Shape"
                            TComboBox {
                                model: ["circle", "square"]
                                currentIndex: win.idx(model, win.g("arcmenu.shape", "circle"))
                                onActivated: win.set("arcmenu.shape", model[currentIndex])
                            }
                        }
                        SRow { label: "Radius"; TSpinBox { from: 40; to: 400; value: win.g("arcmenu.radius", 140); onValueChanged: win.set("arcmenu.radius", value) } }
                        SRow { label: "FAB size"; TSpinBox { from: 24; to: 96; value: win.g("arcmenu.fab_size", 56); onValueChanged: win.set("arcmenu.fab_size", value) } }
                        SRow { label: "Item size"; TSpinBox { from: 24; to: 96; value: win.g("arcmenu.item_size", 48); onValueChanged: win.set("arcmenu.item_size", value) } }
                        SRow { label: "Margin"; TSpinBox { from: 0; to: 200; value: win.g("arcmenu.margin", 24); onValueChanged: win.set("arcmenu.margin", value) } }
                        SRow { label: "Animation (ms)"; TSpinBox { from: 0; to: 1000; stepSize: 20; value: win.g("arcmenu.animation_time", 300); onValueChanged: win.set("arcmenu.animation_time", value) } }
                        SRow {
                            label: "FAB glyph"
                            TTextField { Layout.fillWidth: true; text: win.g("arcmenu.fab_glyph", "\uf00a"); onEditingFinished: win.set("arcmenu.fab_glyph", text) }
                        }
                        SRow {
                            label: "Use pywal colours"
                            TCheckBox { checked: win.g("arcmenu.use_pywal", true); onToggled: win.set("arcmenu.use_pywal", checked) }
                        }
                        SRow {
                            label: "FAB colour"
                            TTextField { Layout.preferredWidth: 120; text: win.g("arcmenu.fab_color", "#C084FC"); onEditingFinished: win.set("arcmenu.fab_color", text) }
                        }
                        SRow {
                            label: "Item colour"
                            TTextField { Layout.preferredWidth: 120; text: win.g("arcmenu.item_color", "#22D3EE"); onEditingFinished: win.set("arcmenu.item_color", text) }
                        }
                        SRow {
                            label: "Close on click"
                            TCheckBox { checked: win.g("arcmenu.close_on_click", true); onToggled: win.set("arcmenu.close_on_click", checked) }
                        }
                        Text { text: "Menu items"; color: Theme.accent; font.bold: true; font.pixelSize: 12; Layout.topMargin: 6 }
                        Repeater {
                            model: win.arcItems()
                            delegate: RowLayout {
                                id: arcItem
                                required property var modelData
                                required property int index
                                Layout.fillWidth: true
                                spacing: 6
                                TTextField { Layout.preferredWidth: 40; text: arcItem.modelData.glyph || ""; onEditingFinished: win.setArcItem(arcItem.index, "glyph", text) }
                                TTextField { Layout.fillWidth: true; placeholderText: "command"; text: arcItem.modelData.command || ""; onEditingFinished: win.setArcItem(arcItem.index, "command", text) }
                                TTextField { Layout.preferredWidth: 130; placeholderText: "tooltip"; text: arcItem.modelData.tooltip || ""; onEditingFinished: win.setArcItem(arcItem.index, "tooltip", text) }
                                TButton { text: "\u2191"; implicitWidth: 30; onClicked: win.moveArcItem(arcItem.index, -1) }
                                TButton { text: "\u2193"; implicitWidth: 30; onClicked: win.moveArcItem(arcItem.index, 1) }
                                TButton { text: "\u2715"; implicitWidth: 30; onClicked: win.removeArcItem(arcItem.index) }
                            }
                        }
                        TButton { text: "Add item"; onClicked: win.addArcItem() }
                        Item { Layout.fillHeight: true }
                    }
                }

                // Menu ──────────────────────────────────────────────────
                Flickable {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    contentHeight: mnCol.implicitHeight; clip: true
                    ColumnLayout {
                        id: mnCol
                        width: parent.width
                        spacing: 8
                        SRow {
                            label: "Layout"
                            TComboBox {
                                model: ["whisker", "win7", "win11", "plasma"]
                                currentIndex: win.idx(model, win.g("menu.layout", "whisker"))
                                onActivated: win.set("menu.layout", model[currentIndex])
                            }
                        }
                        SRow {
                            label: "Position"
                            TComboBox {
                                model: ["auto", "top", "bottom"]
                                currentIndex: win.idx(model, win.g("menu.position", "auto"))
                                onActivated: win.set("menu.position", model[currentIndex])
                            }
                        }
                        SRow {
                            label: "Align"
                            TComboBox {
                                model: ["left", "center", "right"]
                                currentIndex: win.idx(model, win.g("menu.align", "left"))
                                onActivated: win.set("menu.align", model[currentIndex])
                            }
                        }
                        SRow { label: "Width"; TSpinBox { from: 400; to: 1600; stepSize: 20; value: win.g("menu.width", 920); onValueChanged: win.set("menu.width", value) } }
                        SRow { label: "Height"; TSpinBox { from: 320; to: 1000; stepSize: 20; value: win.g("menu.height", 580); onValueChanged: win.set("menu.height", value) } }
                        SRow { label: "Sidebar width"; TSpinBox { from: 120; to: 300; value: win.g("menu.sidebar_width", 180); onValueChanged: win.set("menu.sidebar_width", value) } }
                        SRow { label: "Recents width"; TSpinBox { from: 120; to: 360; value: win.g("menu.recents_width", 230); onValueChanged: win.set("menu.recents_width", value) } }
                        SRow {
                            label: "Show recents"
                            TCheckBox { checked: win.g("menu.show_recents", true); onToggled: win.set("menu.show_recents", checked) }
                        }
                        SRow { label: "Max recents"; TSpinBox { from: 0; to: 30; value: win.g("menu.max_recents", 10); onValueChanged: win.set("menu.max_recents", value) } }
                        Text { text: "Power commands"; color: Theme.accent; font.bold: true; font.pixelSize: 12; Layout.topMargin: 6 }
                        Repeater {
                            model: win.powerKeys
                            delegate: SRow {
                                required property string modelData
                                label: modelData
                                TTextField { Layout.fillWidth: true; text: win.powerVal(modelData); onEditingFinished: win.setPower(modelData, text) }
                            }
                        }
                        Text { text: "Favourites"; color: Theme.accent; font.bold: true; font.pixelSize: 12; Layout.topMargin: 6 }
                        Repeater {
                            model: win.favorites()
                            delegate: RowLayout {
                                required property var modelData
                                required property int index
                                Layout.fillWidth: true
                                Text { text: modelData; color: Theme.foreground; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
                                TButton { text: "\u2715"; implicitWidth: 30; onClicked: win.removeFavorite(index) }
                            }
                        }
                        Item { Layout.fillHeight: true }
                    }
                }

                // Quicklinks ─────────────────────────────────────────────
                ColumnLayout {
                    spacing: 8
                    SRow {
                        label: "Enabled"
                        TCheckBox { checked: win.g("quicklinks.enabled", true); onToggled: win.set("quicklinks.enabled", checked) }
                    }
                    Flickable {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        contentHeight: qlCol.implicitHeight; clip: true
                        ColumnLayout {
                            id: qlCol
                            width: parent.width
                            spacing: 6
                            Repeater {
                                model: win.links()
                                delegate: RowLayout {
                                    id: ql
                                    required property var modelData
                                    required property int index
                                    Layout.fillWidth: true
                                    spacing: 6
                                    TTextField { Layout.preferredWidth: 40; text: ql.modelData.icon || ""; onEditingFinished: win.setLink(ql.index, "icon", text) }
                                    TTextField { Layout.fillWidth: true; placeholderText: "command"; text: ql.modelData.command || ""; onEditingFinished: win.setLink(ql.index, "command", text) }
                                    TTextField { Layout.preferredWidth: 160; placeholderText: "right command"; text: ql.modelData.command_right || ""; onEditingFinished: win.setLink(ql.index, "command_right", text) }
                                    TButton { text: "\u2715"; onClicked: win.removeLink(ql.index) }
                                }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                TButton { text: "Add link"; onClicked: win.addLink() }
                                Item { Layout.fillWidth: true }
                            }
                        }
                    }
                }

                // Modules ────────────────────────────────────────────────
                Flickable {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    contentHeight: modCol.implicitHeight; clip: true
                    ColumnLayout {
                        id: modCol
                        width: parent.width
                        spacing: 6
                        Text { text: "Place each module left / center / right; the checkbox toggles it."; color: Theme.dim; font.pixelSize: 11 }
                        Repeater {
                            model: win.moduleIds
                            delegate: RowLayout {
                                id: mrow
                                required property string modelData
                                Layout.fillWidth: true
                                spacing: 8
                                Text { text: mrow.modelData; color: Theme.foreground; font.pixelSize: 12; Layout.preferredWidth: 130 }
                                TCheckBox {
                                    text: "Enabled"
                                    visible: win.moduleEnabledBlock(mrow.modelData) !== ""
                                    checked: win.g(win.moduleEnabledBlock(mrow.modelData) + ".enabled", true)
                                    onToggled: win.set(win.moduleEnabledBlock(mrow.modelData) + ".enabled", checked)
                                }
                                TComboBox {
                                    model: ["", "left", "center", "right"]
                                    currentIndex: win.idx(["", "left", "center", "right"], win.sectionOf(mrow.modelData))
                                    onActivated: win.setSection(mrow.modelData, model[currentIndex])
                                }
                                Item { Layout.fillWidth: true }
                            }
                        }
                        Item { Layout.fillHeight: true }
                    }
                }

                // Widgets ────────────────────────────────────────────────
                ColumnLayout {
                    spacing: 8
                    SRow {
                        label: "Widgets enabled"
                        TCheckBox { checked: win.g("widgets.enabled", false); onToggled: win.set("widgets.enabled", checked) }
                    }
                    SRow {
                        label: "Transparent pills"
                        TCheckBox { checked: win.g("widgets.transparent", false); onToggled: win.set("widgets.transparent", checked) }
                    }
                    Flickable {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        contentHeight: wCol.implicitHeight; clip: true
                        ColumnLayout {
                            id: wCol
                            width: parent.width
                            spacing: 6
                            Repeater {
                                model: win.widgetIds
                                delegate: ColumnLayout {
                                    id: wr
                                    required property string modelData
                                    Layout.fillWidth: true
                                    spacing: 4
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8
                                        Text { text: wr.modelData; color: Theme.foreground; font.pixelSize: 12; Layout.preferredWidth: 90 }
                                        TCheckBox { text: "On"; checked: win.g("widgets." + wr.modelData + ".enabled", false); onToggled: win.setWidget(wr.modelData, "enabled", checked) }
                                        TComboBox {
                                            model: ["top-left", "top-center", "top-right", "center-left", "center", "center-right", "bottom-left", "bottom-center", "bottom-right", "free"]
                                            currentIndex: win.idx(model, win.widgetVal(wr.modelData, "position", "top-left"))
                                            onActivated: win.setWidget(wr.modelData, "position", model[currentIndex])
                                        }
                                        Text { text: "op"; color: Theme.dim; font.pixelSize: 10 }
                                        TSlider {
                                            Layout.preferredWidth: 100
                                            from: 0.1; to: 1.0; stepSize: 0.05
                                            value: win.widgetVal(wr.modelData, "opacity", 0.75)
                                            onMoved: win.setWidget(wr.modelData, "opacity", value)
                                        }
                                    }
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Layout.leftMargin: 98
                                        spacing: 6
                                        Text { text: "style"; color: Theme.dim; font.pixelSize: 10 }
                                        TComboBox {
                                            Layout.preferredWidth: 120
                                            visible: win.widgetStyles(wr.modelData).length > 0
                                            model: win.widgetStyles(wr.modelData)
                                            currentIndex: win.idx(model, win.widgetVal(wr.modelData, "style", ""))
                                            onActivated: win.setWidget(wr.modelData, "style", model[currentIndex])
                                        }
                                        Text { text: "bg"; color: Theme.dim; font.pixelSize: 10; visible: win.hasColors(wr.modelData) }
                                        TTextField { Layout.preferredWidth: 96; visible: win.hasColors(wr.modelData); placeholderText: "#rrggbb"; text: win.widgetVal(wr.modelData, "background", ""); onEditingFinished: win.setWidget(wr.modelData, "background", text) }
                                        Text { text: "fg"; color: Theme.dim; font.pixelSize: 10; visible: win.hasColors(wr.modelData) }
                                        TTextField { Layout.preferredWidth: 96; visible: win.hasColors(wr.modelData); placeholderText: "#rrggbb"; text: win.widgetVal(wr.modelData, "foreground", ""); onEditingFinished: win.setWidget(wr.modelData, "foreground", text) }
                                        Text { text: "accent"; color: Theme.dim; font.pixelSize: 10; visible: win.hasColors(wr.modelData) }
                                        TTextField { Layout.preferredWidth: 96; visible: win.hasColors(wr.modelData); placeholderText: "#rrggbb"; text: win.widgetVal(wr.modelData, "accent", ""); onEditingFinished: win.setWidget(wr.modelData, "accent", text) }
                                        Item { Layout.fillWidth: true }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Text { text: "Saves to ~/.config/hyprtk-bar/config.json (shared with the GTK bar)"; color: Theme.dim; font.pixelSize: 10; Layout.fillWidth: true }
                TButton { text: "Close"; onClicked: UiState.settingsOpen = false }
            }
        }
    }
}
