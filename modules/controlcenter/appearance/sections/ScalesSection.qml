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

    title: qsTr("Scales")
    showBackground: true

    SectionContainer {
        contentSpacing: Appearance.spacing.normal

        SliderInput {
            Layout.fillWidth: true
            
            label: qsTr("Padding scale")
            value: rootPane.paddingScale
            from: 0.5
            to: 2.0
            decimals: 1
            suffix: "×"
            validator: DoubleValidator { bottom: 0.5; top: 2.0 }
            
            onValueModified: (newValue) => {
                rootPane.paddingScale = newValue;
                rootPane.saveConfig();
            }
        }
    }

    SectionContainer {
        contentSpacing: Appearance.spacing.normal

        SliderInput {
            Layout.fillWidth: true
            
            label: qsTr("Rounding scale")
            value: rootPane.roundingScale
            from: 0.1
            to: 5.0
            decimals: 1
            suffix: "×"
            validator: DoubleValidator { bottom: 0.1; top: 5.0 }
            
            onValueModified: (newValue) => {
                rootPane.roundingScale = newValue;
                rootPane.saveConfig();
            }
        }
    }

    SectionContainer {
        contentSpacing: Appearance.spacing.normal

        SliderInput {
            Layout.fillWidth: true
            
            label: qsTr("Spacing scale")
            value: rootPane.spacingScale
            from: 0.1
            to: 2.0
            decimals: 1
            suffix: "×"
            validator: DoubleValidator { bottom: 0.1; top: 2.0 }
            
            onValueModified: (newValue) => {
                rootPane.spacingScale = newValue;
                rootPane.saveConfig();
            }
        }
    }
}

