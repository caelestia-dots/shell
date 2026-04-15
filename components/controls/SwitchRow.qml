import ".."
import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

StyledRect {
    id: root

    required property string label
    required property bool checked
    property var onToggled: function (checked) {}

    Layout.fillWidth: true
    implicitHeight: row.implicitHeight + Tokens.padding.large * 2
    radius: Tokens.rounding.normal
    color: Colours.layer(Colours.palette.m3surfaceContainer, 2)

    Behavior on implicitHeight {
        Anim {}
    }

    RowLayout {
        id: row

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.normal

        StyledText {
            Layout.fillWidth: true
            text: root.label
        }

        StyledSwitch {
            checked: root.checked
            enabled: root.enabled
            onToggled: {
                root.onToggled(checked); // qmllint disable use-proper-function
            }
        }
    }
}
