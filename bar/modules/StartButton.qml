import QtQuick
import "../../components"
import "../../state"
import "../../data"

BarIconButton {
    visible: BarConfig.center.start_button !== false
    glyph: BarConfig.center.start_glyph || "\uf015"
    tooltip: "Open menu"
    active: UiState.startMenuOpen
    onActivated: UiState.startMenuOpen = !UiState.startMenuOpen
}
