import "../"
import qs.components
import qs.components.controls
import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts

// Base component for all config items to reduce code duplication
Item {
    id: root

    required property var configObject
    required property var propertyData
    required property var sectionPath

    readonly property var fullPath: [...sectionPath, propertyData.name]
    property var currentValue: configObject[propertyData.name]
    
    implicitHeight: 56

    Connections {
        target: ConfigParser
        function onValueChanged(path) {
            if (path.length === root.fullPath.length && 
                path.every((v, i) => v === root.fullPath[i])) {
                root.currentValue = root.configObject[root.propertyData.name];
            }
        }
    }

    function updateValue(value) {
        console.log("Updating value at path:", JSON.stringify(root.fullPath), "to:", value);
        ConfigParser.updateValue(root.fullPath, value);
    }
}
