import QtQuick
import "../../components"
import "../../state"
import "../../data"

BarIconButton {
    id: qsBtn
    glyph: "\uf013"
    tooltip: "Quick settings"
    visible: BarConfig.quicksettings.enabled !== false
    active: UiState.quickSettingsOpen
    onActivated: UiState.quickSettingsOpen = !UiState.quickSettingsOpen

    // Register our window-relative position so the flyout lines up under us.
    function _register() { BarAnchors.setQs(mapToItem(null, 0, 0).x, width); }
    Component.onCompleted: _register()
    onXChanged: _register()
    onWidthChanged: _register()
}
