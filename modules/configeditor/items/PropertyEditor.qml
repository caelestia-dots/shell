import "../"
import qs.components
import qs.components.controls
import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts

// Reusable property editor that handles all types using Loader for dynamic components
Loader {
    id: root

    required property var configObject
    required property var propertyData
    required property var sectionPath
    
    Layout.fillWidth: true
    Layout.preferredHeight: item?.implicitHeight ?? 0

    sourceComponent: {
        if (!propertyData?.name || !ConfigParser.formatPropertyName(propertyData.name).trim()) {
            return null;
        }

        switch (propertyData?.type) {
            case "bool": return boolComponent;
            case "int":
            case "real": return numberComponent;
            case "string": return stringComponent;
            case "object": return objectComponent;
            default: return null;
        }
    }

    Component {
        id: boolComponent

        BoolConfigItem {
            configObject: root.configObject
            propertyData: root.propertyData
            sectionPath: root.sectionPath
        }
    }

    Component {
        id: stringComponent

        StringConfigItem {
            configObject: root.configObject
            propertyData: root.propertyData
            sectionPath: root.sectionPath
        }
    }

    Component {
        id: numberComponent

        NumberConfigItem {
            configObject: root.configObject
            propertyData: root.propertyData
            sectionPath: root.sectionPath
        }
    }

    Component {
        id: objectComponent

        Loader {
            id: objectLoader
            
            Component.onCompleted: {
                setSource("ObjectHeader.qml", {
                    "configObject": root.configObject,
                    "propertyData": root.propertyData,
                    "sectionPath": root.sectionPath
                });
            }
        }
    }
}
