// Desktop clock widget (digital / text styles; dials fall back to digital).
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../theme"

WidgetFrame {
    id: win

    property var block: ({})
    widgetId: "clock"

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

        Canvas {
            id: dial
            visible: win.style === "dials"
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Math.max(80, win.widgetWidth - 2 * win.padding)
            Layout.preferredHeight: Layout.preferredWidth
            onWidthChanged: requestPaint()
            Connections {
                target: win.clock
                function onDateChanged() { dial.requestPaint(); }
            }
            onPaint: {
                const ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                const cx = width / 2, cy = height / 2;
                const R = Math.min(width, height) / 2 - 3;
                const d = win.clock.date;
                ctx.strokeStyle = win.widgetAccent;
                ctx.lineWidth = 2;
                ctx.beginPath();
                ctx.arc(cx, cy, R, 0, Math.PI * 2);
                ctx.stroke();
                // ticks
                for (let i = 0; i < 12; i++) {
                    const a = i * Math.PI / 6;
                    const inner = (i % 3 === 0) ? R - 9 : R - 5;
                    ctx.beginPath();
                    ctx.moveTo(cx + Math.cos(a) * inner, cy + Math.sin(a) * inner);
                    ctx.lineTo(cx + Math.cos(a) * R, cy + Math.sin(a) * R);
                    ctx.stroke();
                }
                function hand(angle, len, w, color) {
                    ctx.beginPath();
                    ctx.lineWidth = w;
                    ctx.strokeStyle = color;
                    ctx.moveTo(cx, cy);
                    ctx.lineTo(cx + Math.cos(angle) * len, cy + Math.sin(angle) * len);
                    ctx.stroke();
                }
                const sec = d.getSeconds(), min = d.getMinutes(), hr = d.getHours() % 12;
                hand((hr + min / 60) * Math.PI / 6 - Math.PI / 2, R * 0.5, 3, win.widgetForeground);
                hand((min + sec / 60) * Math.PI / 30 - Math.PI / 2, R * 0.72, 2, win.widgetForeground);
                hand(sec * Math.PI / 30 - Math.PI / 2, R * 0.82, 1, win.widgetAccent);
            }
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            visible: win.style !== "dials"
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
