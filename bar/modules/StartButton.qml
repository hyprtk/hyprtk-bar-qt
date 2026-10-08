import QtQuick
import "../../components"
import "../../state"
import "../../data"

BarIconButton {
    glyph: BarConfig.center.start_glyph || "\uf015"
    active: UiState.startMenuOpen
    onActivated: UiState.startMenuOpen = !UiState.startMenuOpen
}
