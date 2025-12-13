import "../"
import qs.components
import qs.components.controls
import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts

BaseConfigItem {
    id: root

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Appearance.padding.normal
        anchors.rightMargin: Appearance.padding.normal
        spacing: Appearance.spacing.normal

        StyledText {
            Layout.fillWidth: true
            text: ConfigParser.formatPropertyName(root.propertyData.name)
            font.pointSize: Appearance.font.size.normal
            color: Colours.palette.m3onSurface
        }

        StyledSwitch {
            Layout.alignment: Qt.AlignRight
            checked: root.currentValue ?? false
            onToggled: root.updateValue(checked)
        }
    }
}
