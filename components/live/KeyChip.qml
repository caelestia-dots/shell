import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.config

StyledRect {
    id: root

    required property string keyText
    
    readonly property bool isIcon: keyText.startsWith("icon:")
    readonly property var iconList: isIcon ? keyText.split(" ") : []

    implicitWidth: isIcon ? iconRow.implicitWidth + Appearance.padding.normal * 2 : keyLabel.implicitWidth + Appearance.padding.normal * 2
    implicitHeight: isIcon ? iconRow.implicitHeight + Appearance.padding.small * 2 : keyLabel.implicitHeight + Appearance.padding.small * 2
    radius: Appearance.rounding.small
    color: Colours.palette.m3surfaceContainerHigh

    StyledText {
        id: keyLabel

        anchors.centerIn: parent
        visible: !root.isIcon
        text: root.keyText
        font.family: "monospace"
        font.pointSize: Appearance.font.size.small
        color: Colours.palette.m3onSurface
    }
    
    RowLayout {
        id: iconRow
        
        anchors.centerIn: parent
        visible: root.isIcon
        spacing: Appearance.spacing.small
        
        Repeater {
            model: root.iconList
            
            delegate: MaterialIcon {
                required property string modelData
                
                text: modelData.substring(5)
                font.pointSize: Appearance.font.size.normal
                color: Colours.palette.m3onSurface
            }
        }
    }
}
