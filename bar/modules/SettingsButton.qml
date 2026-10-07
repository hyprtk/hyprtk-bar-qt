import QtQuick
import "../../components"
import "../../state"

BarIconButton {
    glyph: "\uf013"
    active: UiState.settingsOpen
    onActivated: UiState.settingsOpen = !UiState.settingsOpen
}
