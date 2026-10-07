import QtQuick
import "../../components"
import "../../state"

BarIconButton {
    glyph: "\uf1fc"
    active: UiState.themerOpen
    onActivated: UiState.themerOpen = !UiState.themerOpen
}
