// Desktop clock widget (digital / text styles; dials fall back to digital).
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../theme"

WidgetFrame {
    id: win

    property var block: ({})

    position: block.position || "top-left"
    marginX: block.margin_x !== undefined ? block.margin_x : 40
    marginY: block.margin_y !== undefined ? block.margin_y : 40
    layer: block.layer || "bottom"
    widgetWidth: block.width || 220
    widgetHeight: block.height || 0
    widgetOpacity: block.opacity !== undefined ? block.opacity : 0.75
    radius: block.radius || 16
    padding: block.padding || 18
    scale: block.scale || 1.0
    backgroundOverride: block.background || "transparent"
    foregroundOverride: block.foreground || "transparent"
    accentOverride: block.accent || "transparent"

    property SystemClock clock: SystemClock { precision: SystemClock.Seconds }

    function qtFormat(fmt) {
        return (fmt || "%H:%M").replace(/%[HIpMSAadyBbm]/g, m => {
            switch (m) {
            case "%H": return "HH";
            case "%I": return "hh";
            case "%p": return "AP";
            case "%M": return "mm";
            case "%S": return "ss";
            case "%A": return "dddd";
            case "%a": return "ddd";
            case "%d": return "dd";
            case "%B": return "MMMM";
            case "%b": return "MMM";
            case "%m": return "MM";
            case "%Y": return "yyyy";
            case "%y": return "yy";
            }
            return m;
        });
    }
    function spell(h, m) {
        const hours = ["twelve", "one", "two", "three", "four", "five", "six", "seven",
            "eight", "nine", "ten", "eleven"];
        const tens = ["", "ten", "twenty", "thirty", "forty", "fifty"];
        const ones = ["", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine"];
        let mm = m < 10 ? "oh " + ones[m] : (m % 10 === 0 ? tens[m / 10] : tens[Math.floor(m / 10)] + " " + ones[m % 10]);
        if (m === 0)
            return hours[h % 12] + " o'clock";
        if (m === 15)
            return "quarter past " + hours[h % 12];
        if (m === 30)
            return "half past " + hours[h % 12];
        if (m === 45)
            return "quarter to " + hours[(h + 1) % 12];
        return hours[h % 12] + " " + mm;
    }

    readonly property var now: win.clock.date
    readonly property string style: block.style || "digital"

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Math.round(4 * win.scale)

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: win.style === "text"
                ? win.spell(win.now.getHours(), win.now.getMinutes())
                : Qt.formatDateTime(win.now, win.qtFormat(win.block.time_format || "%H:%M"))
            color: win.widgetForeground
            font.pixelSize: Math.round((win.style === "text" ? 22 : 42) * win.scale)
            font.bold: win.style !== "text"
            font.family: win.block.font && win.block.font.length ? win.block.font : Theme.fontFamily
            wrapMode: Text.WordWrap
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            visible: win.block.show_date !== false
            text: Qt.formatDateTime(win.now, win.qtFormat(win.block.date_format || "%A, %d %B"))
            color: win.widgetAccent
            font.pixelSize: Math.round(13 * win.scale)
            font.family: win.block.font && win.block.font.length ? win.block.font : Theme.fontFamily
        }
    }
}
