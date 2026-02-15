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
    required property bool checked
    property bool enabled: true
    property var onToggled: function(checked) {}

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

        StyledSwitch {
            checked: root.checked
            enabled: root.enabled
            onToggled: {
                root.onToggled(checked);
            }
        }
    }
}

