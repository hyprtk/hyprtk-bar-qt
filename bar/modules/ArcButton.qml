import QtQuick
import "../../components"
import "../../state"
import "../../data"

BarIconButton {
    glyph: "\u229e"
    visible: BarConfig.arcmenu.enabled !== false
    active: UiState.arcMenuOpen
    onActivated: UiState.arcMenuOpen = !UiState.arcMenuOpen
}
