pragma ComponentBehavior: Bound

import ".."
import qs.components
import qs.components.controls
import qs.components.effects
import qs.components.containers
import qs.config
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property Session session
    property var device: null
    
    property Component headerComponent: null
    property list<Component> sections: []
    
    property Component topContent: null
    property Component bottomContent: null

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Appearance.spacing.normal

        Loader {
            id: headerLoader
            
            Layout.fillWidth: true
            sourceComponent: root.headerComponent
            visible: root.headerComponent !== null
        }

        Loader {
            id: topContentLoader
            
            Layout.fillWidth: true
            sourceComponent: root.topContent
            visible: root.topContent !== null
        }

        Repeater {
            model: root.sections
            
            Loader {
                required property Component modelData
                
                Layout.fillWidth: true
                sourceComponent: modelData
            }
        }

        Loader {
            id: bottomContentLoader
            
            Layout.fillWidth: true
            sourceComponent: root.bottomContent
            visible: root.bottomContent !== null
        }
    }
}

