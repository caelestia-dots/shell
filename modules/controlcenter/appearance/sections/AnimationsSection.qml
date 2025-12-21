pragma ComponentBehavior: Bound

import ".."
import "../../components"
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

CollapsibleSection {
    id: root

    required property var rootPane

    title: qsTr("Animations")
    showBackground: true

    SectionContainer {
        contentSpacing: Appearance.spacing.normal

        SliderInput {
            Layout.fillWidth: true
            
            label: qsTr("Animation duration scale")
            value: rootPane.animDurationsScale
            from: 0.1
            to: 5.0
            decimals: 1
            suffix: "×"
            validator: DoubleValidator { bottom: 0.1; top: 5.0 }
            
            onValueModified: (newValue) => {
                rootPane.animDurationsScale = newValue;
                rootPane.saveConfig();
            }
        }
    }
}

