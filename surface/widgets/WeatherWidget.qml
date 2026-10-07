// Desktop weather widget: current conditions + daily forecast (Open-Meteo).
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../theme"

WidgetFrame {
    id: win
    property var block: ({})
    widgetId: "weather"

    readonly property string backend:
        Qt.resolvedUrl("../../backend/hyprtk_bar_qt/weather.py").toString().replace("file://", "")
    readonly property string city: block.city || "London"
    readonly property int days: Math.max(1, block.forecast_days || 3)
    readonly property int refreshMin: Math.max(1, block.refresh_minutes || 15)

    position: block.position || "top-left"
    marginX: block.margin_x !== undefined ? block.margin_x : 40
    marginY: block.margin_y !== undefined ? block.margin_y : 40
    layer: block.layer || "bottom"
    widgetWidth: block.width || 280
    widgetHeight: block.height || 0
    widgetOpacity: block.opacity !== undefined ? block.opacity : 0.75
    radius: block.radius || 16
    padding: block.padding || 18
    scale: block.scale || 1.0
    backgroundOverride: block.background || "transparent"
    foregroundOverride: block.foreground || "transparent"
    accentOverride: block.accent || "transparent"

    property var data: ({})

    // WMO code -> [label, day glyph, night glyph]
    readonly property var wmo: ({
        0: ["Clear", "\ue30d", "\ue32b"], 1: ["Mainly clear", "\ue30d", "\ue32b"],
        2: ["Partly cloudy", "\ue302", "\ue37e"], 3: ["Overcast", "\ue312", "\ue312"],
        45: ["Fog", "\ue313", "\ue313"], 48: ["Rime fog", "\ue313", "\ue313"],
        51: ["Light drizzle", "\ue31b", "\ue336"], 53: ["Drizzle", "\ue31b", "\ue336"],
        55: ["Dense drizzle", "\ue31b", "\ue336"], 56: ["Freezing drizzle", "\ue316", "\ue331"],
        57: ["Freezing drizzle", "\ue316", "\ue331"], 61: ["Light rain", "\ue308", "\ue325"],
        63: ["Rain", "\ue318", "\ue333"], 65: ["Heavy rain", "\ue317", "\ue332"],
        66: ["Freezing rain", "\ue3ad", "\ue3ad"], 67: ["Freezing rain", "\ue3ad", "\ue3ad"],
        71: ["Light snow", "\ue31a", "\ue335"], 73: ["Snow", "\ue31a", "\ue335"],
        75: ["Heavy snow", "\ue35e", "\ue35e"], 77: ["Snow grains", "\ue31a", "\ue335"],
        80: ["Light showers", "\ue309", "\ue326"], 81: ["Showers", "\ue319", "\ue334"],
        82: ["Violent showers", "\ue31c", "\ue329"], 85: ["Snow showers", "\ue30a", "\ue327"],
        86: ["Snow showers", "\ue30a", "\ue327"], 95: ["Thunderstorm", "\ue31d", "\ue32a"],
        96: ["Thunderstorm, hail", "\ue31d", "\ue32a"], 99: ["Thunderstorm, hail", "\ue31d", "\ue32a"]
    })
    function describe(code) {
        return win.wmo[code] || ["Unknown", "\ue33d", "\ue33d"];
    }
    function nowGlyph() {
        const d = win.describe(win.data.code);
        return win.data.is_day === 0 ? d[2] : d[1];
    }

    Process {
        id: proc
        command: ["python3", win.backend, "--city", win.city,
                  "--units", block.units || "metric", "--days", String(win.days),
                  "--max-age", String(win.refreshMin * 60)]
        stdout: SplitParser {
            onRead: line => {
                try {
                    const o = JSON.parse(line);
                    if (o.data)
                        win.data = o.data;
                } catch (e) {
                }
            }
        }
    }
    Timer {
        running: win.visible
        interval: win.refreshMin * 60 * 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Math.round(4 * win.scale)

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Text {
                visible: block.show_icon !== false
                text: win.data.code !== undefined ? win.nowGlyph() : "\ue33d"
                color: win.widgetAccent
                font.pixelSize: Math.round(34 * win.scale)
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Text {
                    visible: block.show_temp !== false
                    text: win.data.temp !== undefined && win.data.temp !== null
                        ? Math.round(win.data.temp) + (win.data.unit || "\u00b0C") : "--"
                    color: win.widgetForeground
                    font.pixelSize: Math.round(30 * win.scale)
                    font.bold: true
                }
                Text {
                    text: win.data.city ? win.data.city + (win.data.country ? ", " + win.data.country : "") : win.city
                    color: win.widgetForeground
                    font.pixelSize: Math.round(12 * win.scale)
                }
            }
        }

        Text {
            Layout.fillWidth: true
            visible: block.show_condition !== false && win.data.code !== undefined
            text: win.data.code !== undefined ? win.describe(win.data.code)[0] : ""
            color: win.widgetAccent
            font.pixelSize: Math.round(12 * win.scale)
        }

        Text {
            Layout.fillWidth: true
            visible: (block.show_feels_like !== false || block.show_humidity !== false || block.show_wind !== false) && win.data.temp !== undefined
            color: win.widgetForeground
            opacity: 0.85
            font.pixelSize: Math.round(11 * win.scale)
            text: {
                const parts = [];
                if (block.show_feels_like !== false && win.data.feels !== undefined && win.data.feels !== null)
                    parts.push("Feels " + Math.round(win.data.feels) + (win.data.unit || "\u00b0C"));
                if (block.show_humidity !== false && win.data.humidity !== undefined && win.data.humidity !== null)
                    parts.push(win.data.humidity + "% RH");
                if (block.show_wind !== false && win.data.wind !== undefined && win.data.wind !== null)
                    parts.push(win.data.wind + " " + (win.data.wind_unit || "km/h"));
                return parts.join("   ");
            }
        }

        Repeater {
            model: block.show_forecast !== false ? (win.data.daily || []) : []
            delegate: RowLayout {
                id: frow
                required property var modelData
                Layout.fillWidth: true
                spacing: 8
                Text {
                    text: frow.modelData.date ? Qt.formatDate(new Date(frow.modelData.date), "ddd") : ""
                    color: win.widgetForeground
                    opacity: 0.85
                    font.pixelSize: Math.round(11 * win.scale)
                    Layout.preferredWidth: Math.round(40 * win.scale)
                }
                Text {
                    text: win.describe(frow.modelData.code)[1]
                    color: win.widgetAccent
                    font.pixelSize: Math.round(13 * win.scale)
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: (frow.modelData.hi !== null ? Math.round(frow.modelData.hi) : "--")
                        + " / " + (frow.modelData.lo !== null ? Math.round(frow.modelData.lo) : "--")
                    color: win.widgetForeground
                    font.pixelSize: Math.round(11 * win.scale)
                }
            }
        }
    }
}
