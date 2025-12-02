import ".."
import qs.components
import qs.components.effects
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

StyledRect {
    id: root

    required property string label
    required property real value
    required property real min
    required property real max
    property real step: 1
    property var onValueModified: function(value) {}

    Layout.fillWidth: true
    implicitHeight: row.implicitHeight + Appearance.padding.large * 2
    radius: Appearance.rounding.normal
    color: Colours.layer(Colours.palette.m3surfaceContainer, 2)

    Behavior on implicitHeight {
        Anim {}
    }

    RowLayout {
        id: row

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: Appearance.padding.large
        spacing: Appearance.spacing.normal

        StyledText {
            Layout.fillWidth: true
            text: root.label
        }

        CustomSpinBox {
            min: root.min
            max: root.max
            step: root.step
            value: root.value
            onValueModified: value => {
                root.onValueModified(value);
            }
        }
    }
}

