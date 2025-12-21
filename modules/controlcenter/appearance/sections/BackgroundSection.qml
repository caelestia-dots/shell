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

    title: qsTr("Background")
    showBackground: true

    SwitchRow {
        label: qsTr("Desktop clock")
        checked: rootPane.desktopClockEnabled
        onToggled: checked => {
            rootPane.desktopClockEnabled = checked;
            rootPane.saveConfig();
        }
    }

    SwitchRow {
        label: qsTr("Background enabled")
        checked: rootPane.backgroundEnabled
        onToggled: checked => {
            rootPane.backgroundEnabled = checked;
            rootPane.saveConfig();
        }
    }

    StyledText {
        Layout.topMargin: Appearance.spacing.normal
        text: qsTr("Visualiser")
        font.pointSize: Appearance.font.size.larger
        font.weight: 500
    }

    SwitchRow {
        label: qsTr("Visualiser enabled")
        checked: rootPane.visualiserEnabled
        onToggled: checked => {
            rootPane.visualiserEnabled = checked;
            rootPane.saveConfig();
        }
    }

    SwitchRow {
        label: qsTr("Visualiser auto hide")
        checked: rootPane.visualiserAutoHide
        onToggled: checked => {
            rootPane.visualiserAutoHide = checked;
            rootPane.saveConfig();
        }
    }

    SectionContainer {
        contentSpacing: Appearance.spacing.normal

        SliderInput {
            Layout.fillWidth: true
            
            label: qsTr("Visualiser rounding")
            value: rootPane.visualiserRounding
            from: 0
            to: 10
            stepSize: 1
            validator: IntValidator { bottom: 0; top: 10 }
            formatValueFunction: (val) => Math.round(val).toString()
            parseValueFunction: (text) => parseInt(text)
            
            onValueModified: (newValue) => {
                rootPane.visualiserRounding = Math.round(newValue);
                rootPane.saveConfig();
            }
        }
    }

    SectionContainer {
        contentSpacing: Appearance.spacing.normal

        SliderInput {
            Layout.fillWidth: true
            
            label: qsTr("Visualiser spacing")
            value: rootPane.visualiserSpacing
            from: 0
            to: 2
            validator: DoubleValidator { bottom: 0; top: 2 }
            
            onValueModified: (newValue) => {
                rootPane.visualiserSpacing = newValue;
                rootPane.saveConfig();
            }
        }
    }
}

