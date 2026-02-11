pragma ComponentBehavior: Bound

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
    property int expandedZ: 100
    property bool enabled: true

    property alias menuItems: splitButton.menuItems
    property alias active: splitButton.active
    property alias expanded: splitButton.expanded
    property alias type: splitButton.type

    signal selected(item: MenuItem)

    Layout.fillWidth: true
    implicitHeight: row.implicitHeight + Appearance.padding.large * 2
    radius: Appearance.rounding.normal
    color: Colours.layer(Colours.palette.m3surfaceContainer, 2)

    clip: false
    z: splitButton.menu.implicitHeight > 0 ? expandedZ : 1
    opacity: enabled ? 1.0 : 0.5

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.margins: Appearance.padding.large
        spacing: Appearance.spacing.normal

        StyledText {
            Layout.fillWidth: true
            text: root.label
            color: root.enabled ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant
        }

        SplitButton {
            id: splitButton
            enabled: root.enabled
            type: SplitButton.Filled

            menu.z: 1

            stateLayer.onClicked: {
                splitButton.expanded = !splitButton.expanded;
            }

            menu.onItemSelected: item => {
                root.selected(item);
            }
        }
    }
}
