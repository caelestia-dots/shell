pragma ComponentBehavior: Bound

import "../../components"
import qs.components
import qs.components.controls
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
            value: root.rootPane.paddingScale
            from: 0.5
            to: 2.0
            decimals: 1
            suffix: "×"
            validator: DoubleValidator {
                bottom: 0.5
                top: 2.0
            }

            onValueModified: newValue => {
                root.rootPane.paddingScale = newValue;
                root.rootPane.saveConfig();
            }
        }
    }

    SectionContainer {
        contentSpacing: Appearance.spacing.normal

        SliderInput {
            Layout.fillWidth: true

            label: qsTr("Rounding scale")
            value: root.rootPane.roundingScale
            from: 0.1
            to: 5.0
            decimals: 1
            suffix: "×"
            validator: DoubleValidator {
                bottom: 0.1
                top: 5.0
            }

            onValueModified: newValue => {
                root.rootPane.roundingScale = newValue;
                root.rootPane.saveConfig();
            }
        }
    }

    SectionContainer {
        contentSpacing: Appearance.spacing.normal

        SliderInput {
            Layout.fillWidth: true

            label: qsTr("Spacing scale")
            value: root.rootPane.spacingScale
            from: 0.1
            to: 2.0
            decimals: 1
            suffix: "×"
            validator: DoubleValidator {
                bottom: 0.1
                top: 2.0
            }

            onValueModified: newValue => {
                root.rootPane.spacingScale = newValue;
                root.rootPane.saveConfig();
            }
        }
    }
}
