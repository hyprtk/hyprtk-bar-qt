import QtQuick
import "../../components"
import "../../state"
import "../../data"

BarIconButton {
    glyph: "\uf013"
    visible: BarConfig.quicksettings.enabled !== false
    active: UiState.quickSettingsOpen
    onActivated: UiState.quickSettingsOpen = !UiState.quickSettingsOpen
}
