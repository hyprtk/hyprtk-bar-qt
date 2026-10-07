import QtQuick
import "../../components"
import "../../state"

BarIconButton {
    glyph: "\uf009"
    active: UiState.startMenuOpen
    onActivated: UiState.startMenuOpen = !UiState.startMenuOpen
}
