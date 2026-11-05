import QtQuick
import Caelestia.Config
import Caelestia.I18n
import qs.components.controls

StyledTextField {
    id: root

    required property DialogState dState

    implicitWidth: Math.max(Tokens.sizes.fileDialog.minSearchWidth, parent.width * 0.7)
    radius: Tokens.rounding.small
    verticalPadding: Tokens.padding.small
    placeholderText: dState.save ? Tr.tr("Save As") : Tr.tr("Search")

    Binding {
        target: root.dState
        property: "search"
        value: root.text
    }
}
