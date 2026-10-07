import QtQuick
import "../../components"
import "../../state"

BarIconButton {
    glyph: "\u229e"
    active: UiState.arcMenuOpen
    onActivated: UiState.arcMenuOpen = !UiState.arcMenuOpen
}
