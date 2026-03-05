pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components.live
import qs.services
import qs.config

ColumnLayout {
    id: root

    required property string sectionId
    required property string sectionName
    required property string sectionIcon
    
    property alias sectionHeader: header
    default property alias contentItems: contentArea.data
    property real sectionBottomSpacing: Appearance.padding.larger * 4

    Layout.fillWidth: true
    Layout.margins: Appearance.padding.larger
    spacing: Appearance.spacing.larger

    SectionHeader {
        id: header
    }

    ColumnLayout {
        id: contentArea
        
        Layout.fillWidth: true
        spacing: 0
    }

    Item {
        Layout.preferredHeight: root.sectionBottomSpacing
    }
}
