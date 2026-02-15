import qs.components
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property string label
    required property string value
    property bool showTopMargin: false

    spacing: Appearance.spacing.small / 2

    StyledText {
        Layout.topMargin: root.showTopMargin ? Appearance.spacing.normal : 0
        text: root.label
    }

    StyledText {
        text: root.value
        color: Colours.palette.m3outline
        font.pointSize: Appearance.font.size.small
    }
}

