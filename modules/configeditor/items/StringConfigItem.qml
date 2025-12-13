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

        StyledTextField {
            Layout.alignment: Qt.AlignRight
            Layout.preferredWidth: 200
            text: root.currentValue ?? ""
            placeholderText: qsTr("Enter value...")
            padding: Appearance.padding.small
            leftPadding: Appearance.padding.normal
            rightPadding: Appearance.padding.normal

            background: StyledRect {
                implicitWidth: 200
                implicitHeight: 36
                radius: Appearance.rounding.small
                color: Colours.tPalette.m3surfaceContainerHigh
            }

            onEditingFinished: root.updateValue(text)
        }
    }
}
