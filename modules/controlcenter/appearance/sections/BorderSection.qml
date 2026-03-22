pragma ComponentBehavior: Bound

import ".."
import "../../components"
import QtQuick
import QtQuick.Layouts
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services
import qs.config

CollapsibleSection {
    id: root

    required property var rootPane

    title: qsTr("Border")
    showBackground: true

    SectionContainer {
        contentSpacing: Appearance.spacing.normal

        SliderInput {
            Layout.fillWidth: true

            label: qsTr("Border rounding")
            value: rootPane.borderRounding
            from: 0.1
            to: 100
            decimals: 1
            suffix: "px"
            validator: DoubleValidator {
                bottom: 0.1
                top: 100
            }

            onValueModified: newValue => {
                rootPane.borderRounding = newValue;
                rootPane.saveConfig();
            }
        }
    }

    SectionContainer {
        contentSpacing: Appearance.spacing.normal

        SliderInput {
            Layout.fillWidth: true

            label: qsTr("Border thickness")
            value: rootPane.borderThickness
            from: 0
            to: 100
            decimals: 1
            suffix: "px"
            validator: DoubleValidator {
                bottom: 0.1
                top: 100
            }

            onValueModified: newValue => {
                rootPane.borderThickness = newValue;
                rootPane.saveConfig();
            }
        }
    }
}
