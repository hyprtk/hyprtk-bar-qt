// hyprtk-bar-qt's own settings.
//
// Loaded from ~/.config/hyprtk-bar-qt/config.json at startup and written back
// by the Settings/Themer windows. Distinct from the GTK bar's config (which
// Theme still reads for colours/opacity), so the two bars can coexist.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME") || ""
    readonly property string filePath: root.home + "/.config/hyprtk-bar-qt/config.json"

    // ── appearance override ────────────────────────────────────────────
    // Bar geometry/layout is authoritative in the SHARED hyprtk-bar config
    // (data/BarConfig.qml) so the GTK and Qt bars match; only the opacity
    // override lives here.
    property real opacity: -1              // -1 = follow Theme.opacity

    // ── clock / fonts / animations ─────────────────────────────────────
    property string clockFormat: "ddd HH:mm:ss"
    property string fontFamily: "Noto Sans"
    property int fontSize: 12
    property bool animations: true
    property int animationDuration: 140

    // ── module layout (data-driven) ────────────────────────────────────
    property var layoutLeft: ["start_button", "quicklinks", "workspaces", "tasklist", "window"]
    property var layoutCenter: []
    property var layoutRight: ["updates", "net", "tray", "kbstate", "notifications", "clock", "sysmon", "arcmenu", "themer", "settings", "quicksettings"]

    // ── theme overrides ("" = follow hyprtk-bar / pywal) ───────────────
    property string wallpaperDir: ""       // "" = ~/Pictures/Wallpapers
    property string themeSource: ""
    property string themeName: ""
    property string themeBackground: ""
    property string themeForeground: ""
    property string themeAccent: ""

    // ── start menu / quicklinks / arc menu ─────────────────────────────
    property var quicklinksLinks: [
        { glyph: "\uf120", command: "alacritty", alt: "thunar", tooltip: "Terminal" },
        { glyph: "\uf07c", command: "thunar", tooltip: "Files" },
        { glyph: "\uf0ac", command: "firefox", tooltip: "Browser" },
        { glyph: "\uf03e", action: "themer", tooltip: "Wallpaper" },
        { glyph: "\uf0ea", action: "clipboard", tooltip: "Clipboard history" }
    ]
    property string arcMenuPosition: "top-right"
    property var arcMenuItems: [
        { glyph: "\uf120", command: "alacritty", tooltip: "Terminal" },
        { glyph: "\uf07c", command: "thunar", tooltip: "Files" },
        { glyph: "\uf0ac", command: "firefox", tooltip: "Browser" },
        { glyph: "\uf013", action: "settings", tooltip: "Settings" }
    ]

    // ── system monitor dialog ──────────────────────────────────────────
    property int sysmonInterval: 1          // seconds between samples
    property int sysmonDataPoints: 60       // history length for the graphs
    property string sysmonDiskPath: "/"     // mount point for the disk-usage readout
    property string sysmonNetworkIface: "auto"
    property var sysmonPages: ["cpu", "memory", "disks", "network", "gpu", "apps"]

    // ── power actions (same strings as the GTK bar) ────────────────────
    property var menuPower: ({
        "lock": "pidof hyprlock swaylock || ~/.config/hypr/scripts/lock.sh 2>/dev/null || hyprlock || swaylock",
        "logout": "hyprctl dispatch exit",
        "reboot": "systemctl reboot",
        "shutdown": "systemctl poweroff",
        "suspend": "systemctl suspend",
        "hibernate": "systemctl hibernate"
    })

    // All persisted keys, so load/save stay in sync.
    readonly property var _keys: [
        "opacity",
        "clockFormat", "fontFamily", "fontSize",
        "animations", "animationDuration", "layoutLeft", "layoutCenter", "layoutRight",
        "wallpaperDir", "themeSource", "themeName", "themeBackground", "themeForeground", "themeAccent",
        "quicklinksLinks", "arcMenuPosition", "arcMenuItems", "menuPower",
        "sysmonInterval", "sysmonDataPoints", "sysmonDiskPath",
        "sysmonNetworkIface", "sysmonPages"
    ]

    Process {
        running: true
        command: ["mkdir", "-p", root.home + "/.config/hyprtk-bar-qt"]
    }

    FileView {
        id: file
        path: root.filePath
        blockLoading: true
        printErrors: false
        onLoaded: root._load()
    }

    function _load() {
        let o = ({});
        try {
            o = JSON.parse(file.text()) || ({});
        } catch (e) {
            o = ({});
        }
        for (const k of root._keys) {
            if (o[k] !== undefined && o[k] !== null)
                root[k] = o[k];
        }
    }

    function save() {
        const o = ({});
        for (const k of root._keys)
            o[k] = root[k];
        file.setText(JSON.stringify(o, null, 2) + "\n");
    }
}
