// Desktop widgets — free-floating layer-shell surfaces owned by the shell.
//
// Config is read from the shared hyprtk-bar `widgets` block (data/Widgets.qml);
// Clock / Resources / Disk / Network are implemented so far. Weather,
// Visualizer and SysInfo are a later pass.
import QtQuick
import Quickshell
import "../data"
import "widgets"

Scope {
    ClockWidget {
        visible: Widgets.active("clock")
        block: Widgets.block("clock")
    }
    ResourcesWidget {
        visible: Widgets.active("resources")
        block: Widgets.block("resources")
    }
    DiskWidget {
        visible: Widgets.active("disk")
        block: Widgets.block("disk")
    }
    NetworkWidget {
        visible: Widgets.active("network")
        block: Widgets.block("network")
    }
    WeatherWidget {
        visible: Widgets.active("weather")
        block: Widgets.block("weather")
    }
    SysInfoWidget {
        visible: Widgets.active("sysinfo")
        block: Widgets.block("sysinfo")
    }
}
