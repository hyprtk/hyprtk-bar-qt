import QtQuick
import "../../components"
import "../../state"

BarIconButton {
    glyph: "\u2261"
    active: UiState.quickSettingsOpen
    onActivated: UiState.quickSettingsOpen = !UiState.quickSettingsOpen
}
