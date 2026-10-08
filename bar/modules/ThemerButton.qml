import QtQuick
import "../../components"
import "../../state"
import "../../data"

BarIconButton {
    glyph: "\uf1fc"
    tooltip: "Theme Manager"
    visible: BarConfig.themer.enabled !== false
    active: UiState.themerOpen
    onActivated: UiState.themerOpen = !UiState.themerOpen
}
