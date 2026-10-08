import QtQuick
import "../../components"
import "../../state"
import "../../data"

BarIconButton {
    glyph: "\uf0e7"
    tooltip: "Arc menu"
    visible: BarConfig.arcmenu.enabled !== false
    active: UiState.arcMenuOpen
    onActivated: UiState.arcMenuOpen = !UiState.arcMenuOpen
}
