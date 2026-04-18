import ".."
import "../components"
import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

ColumnLayout {
    id: root

    property string label: ""
    property real value: 0
    property real from: 0
    property real to: 100
    property string suffix: ""
    property bool readonly: false

    spacing: Tokens.spacing.small

    RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.normal

        StyledText {
            visible: root.label !== ""
            text: root.label
            font.pointSize: Tokens.font.size.normal
            color: root.readonly ? Colours.palette.m3outline : Colours.palette.m3onSurface
        }

        Item {
            Layout.fillWidth: true
        }

        MaterialIcon {
            visible: root.readonly
            text: "lock"
            color: Colours.palette.m3outline
            font.pointSize: Tokens.font.size.small
        }

        StyledText {
            text: Math.round(root.value) + (root.suffix !== "" ? " " + root.suffix : "")
            font.pointSize: Tokens.font.size.normal
            color: root.readonly ? Colours.palette.m3outline : Colours.palette.m3onSurface
        }
    }

    StyledRect {
        Layout.fillWidth: true
        implicitHeight: Tokens.padding.normal
        radius: Tokens.rounding.full
        color: Colours.layer(Colours.palette.m3surfaceContainerHighest, 1)
        opacity: root.readonly ? 0.5 : 1.0

        StyledRect {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * ((root.value - root.from) / (root.to - root.from))
            radius: parent.radius
            color: root.readonly ? Colours.palette.m3outline : Colours.palette.m3primary
        }
    }
}
