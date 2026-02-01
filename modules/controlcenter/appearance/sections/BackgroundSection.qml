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
        label: qsTr("Background enabled")
        checked: root.rootPane.backgroundEnabled
        onToggled: checked => {
            root.rootPane.backgroundEnabled = checked;
            root.rootPane.saveConfig();
        }
    }

    StyledText {
        Layout.topMargin: Appearance.spacing.normal
        text: qsTr("Desktop Clock")
        font.pointSize: Appearance.font.size.larger
        font.weight: 500
    }

    SwitchRow {
        label: qsTr("Desktop Clock enabled")
        checked: root.rootPane.desktopClockEnabled
        onToggled: checked => {
            root.rootPane.desktopClockEnabled = checked;
            root.rootPane.saveConfig();
        }
    }

    SectionContainer {
        id: posContainer

        contentSpacing: Appearance.spacing.small
        z: 1

        readonly property var pos: (root.rootPane.desktopClockPosition || "top-left").split('-')
        readonly property string currentV: pos[0]
        readonly property string currentH: pos[1]

        function updateClockPos(v, h) {
            root.rootPane.desktopClockPosition = v + "-" + h;
            root.rootPane.saveConfig();
        }

        StyledText {
            text: qsTr("Positioning")
            font.pointSize: Appearance.font.size.larger
            font.weight: 500
        }

        SplitButtonRow {
            label: qsTr("Vertical Position")
            enabled: root.rootPane.desktopClockEnabled

            menuItems: [
                MenuItem {
                    text: qsTr("Top")
                    icon: "vertical_align_top"
                    property string val: "top"
                },
                MenuItem {
                    text: qsTr("Middle")
                    icon: "vertical_align_center"
                    property string val: "middle"
                },
                MenuItem {
                    text: qsTr("Bottom")
                    icon: "vertical_align_bottom"
                    property string val: "bottom"
                }
            ]

            Component.onCompleted: {
                for (let i = 0; i < menuItems.length; i++) {
                    if (menuItems[i].val === posContainer.currentV)
                        active = menuItems[i];
                }
            }

            // The signal from SplitButtonRow
            onSelected: item => posContainer.updateClockPos(item.val, posContainer.currentH)
        }

        SplitButtonRow {
            label: qsTr("Horizontal Position")
            enabled: root.rootPane.desktopClockEnabled
            expandedZ: 99

            menuItems: [
                MenuItem {
                    text: qsTr("Left")
                    icon: "align_horizontal_left"
                    property string val: "left"
                },
                MenuItem {
                    text: qsTr("Center")
                    icon: "align_horizontal_center"
                    property string val: "center"
                },
                MenuItem {
                    text: qsTr("Right")
                    icon: "align_horizontal_right"
                    property string val: "right"
                }
            ]

            Component.onCompleted: {
                for (let i = 0; i < menuItems.length; i++) {
                    if (menuItems[i].val === posContainer.currentH)
                        active = menuItems[i];
                }
            }

            onSelected: item => posContainer.updateClockPos(posContainer.currentV, item.val)
        }
    }

    SwitchRow {
        label: qsTr("Invert colors")
        checked: root.rootPane.desktopClockInvertColors
        onToggled: checked => {
            root.rootPane.desktopClockInvertColors = checked;
            root.rootPane.saveConfig();
        }
    }

    SectionContainer {
        contentSpacing: Appearance.spacing.small

        StyledText {
            text: qsTr("Shadow")
            font.pointSize: Appearance.font.size.larger
            font.weight: 500
        }

        SwitchRow {
            label: qsTr("Enabled")
            checked: root.rootPane.desktopClockShadowEnabled
            onToggled: checked => {
                root.rootPane.desktopClockShadowEnabled = checked;
                root.rootPane.saveConfig();
            }
        }

        SectionContainer {
            contentSpacing: Appearance.spacing.normal

            SliderInput {
                Layout.fillWidth: true

                label: qsTr("Opacity")
                value: root.rootPane.desktopClockShadowOpacity * 100
                from: 0
                to: 100
                suffix: "%"
                validator: IntValidator {
                    bottom: 0
                    top: 100
                }
                formatValueFunction: val => Math.round(val).toString()
                parseValueFunction: text => parseInt(text)

                onValueModified: newValue => {
                    root.rootPane.desktopClockShadowOpacity = newValue / 100;
                    root.rootPane.saveConfig();
                }
            }
        }

        SectionContainer {
            contentSpacing: Appearance.spacing.normal

            SliderInput {
                Layout.fillWidth: true

                label: qsTr("Blur")
                value: root.rootPane.desktopClockShadowBlur * 100
                from: 0
                to: 100
                suffix: "%"
                validator: IntValidator {
                    bottom: 0
                    top: 100
                }
                formatValueFunction: val => Math.round(val).toString()
                parseValueFunction: text => parseInt(text)

                onValueModified: newValue => {
                    root.rootPane.desktopClockShadowBlur = newValue / 100;
                    root.rootPane.saveConfig();
                }
            }
        }
    }

    SectionContainer {
        contentSpacing: Appearance.spacing.small

        StyledText {
            text: qsTr("Background")
            font.pointSize: Appearance.font.size.larger
            font.weight: 500
        }

        SwitchRow {
            label: qsTr("Enabled")
            checked: root.rootPane.desktopClockBackgroundEnabled
            onToggled: checked => {
                root.rootPane.desktopClockBackgroundEnabled = checked;
                root.rootPane.saveConfig();
            }
        }

        SwitchRow {
            label: qsTr("Blur enabled")
            checked: root.rootPane.desktopClockBackgroundBlur
            onToggled: checked => {
                root.rootPane.desktopClockBackgroundBlur = checked;
                root.rootPane.saveConfig();
            }
        }

        SectionContainer {
            contentSpacing: Appearance.spacing.normal

            SliderInput {
                Layout.fillWidth: true

                label: qsTr("Opacity")
                value: root.rootPane.desktopClockBackgroundOpacity * 100
                from: 0
                to: 100
                suffix: "%"
                validator: IntValidator {
                    bottom: 0
                    top: 100
                }
                formatValueFunction: val => Math.round(val).toString()
                parseValueFunction: text => parseInt(text)

                onValueModified: newValue => {
                    root.rootPane.desktopClockBackgroundOpacity = newValue / 100;
                    root.rootPane.saveConfig();
                }
            }
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
        checked: root.rootPane.visualiserEnabled
        onToggled: checked => {
            root.rootPane.visualiserEnabled = checked;
            root.rootPane.saveConfig();
        }
    }

    SwitchRow {
        label: qsTr("Visualiser auto hide")
        checked: root.rootPane.visualiserAutoHide
        onToggled: checked => {
            root.rootPane.visualiserAutoHide = checked;
            root.rootPane.saveConfig();
        }
    }

    SectionContainer {
        contentSpacing: Appearance.spacing.normal

        SliderInput {
            Layout.fillWidth: true

            label: qsTr("Visualiser rounding")
            value: root.rootPane.visualiserRounding
            from: 0
            to: 10
            stepSize: 1
            validator: IntValidator {
                bottom: 0
                top: 10
            }
            formatValueFunction: val => Math.round(val).toString()
            parseValueFunction: text => parseInt(text)

            onValueModified: newValue => {
                root.rootPane.visualiserRounding = Math.round(newValue);
                root.rootPane.saveConfig();
            }
        }
    }

    SectionContainer {
        contentSpacing: Appearance.spacing.normal

        SliderInput {
            Layout.fillWidth: true

            label: qsTr("Visualiser spacing")
            value: root.rootPane.visualiserSpacing
            from: 0
            to: 2
            validator: DoubleValidator {
                bottom: 0
                top: 2
            }

            onValueModified: newValue => {
                root.rootPane.visualiserSpacing = newValue;
                root.rootPane.saveConfig();
            }
        }
    }
}
