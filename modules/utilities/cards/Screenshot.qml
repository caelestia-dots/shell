pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import qs.config
import qs.utils
import Quickshell
import QtQuick
import QtQuick.Layouts

StyledRect {
    id: root

    required property var props
    required property var visibilities

    Layout.fillWidth: true
    implicitHeight: layout.implicitHeight + layout.anchors.margins * 2

    radius: Appearance.rounding.normal
    color: Colours.tPalette.m3surfaceContainer

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Appearance.padding.large
        spacing: Appearance.spacing.normal

        RowLayout {
            spacing: Appearance.spacing.normal
            z: 1

            StyledRect {
                implicitWidth: implicitHeight
                implicitHeight: {
                    const h = icon.implicitHeight + Appearance.padding.smaller * 2;
                    return h - (h % 2);
                }

                radius: Appearance.rounding.full
                color: Colours.palette.m3secondaryContainer

                MaterialIcon {
                    id: icon

                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: -0.5
                    anchors.verticalCenterOffset: 1.5
                    text: "screenshot_monitor"
                    color: Colours.palette.m3onSecondaryContainer
                    font.pointSize: Appearance.font.size.large
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Screenshots")
                    font.pointSize: Appearance.font.size.normal
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Capture an area or the screen and edit in Swappy")
                    color: Colours.palette.m3onSurfaceVariant
                    font.pointSize: Appearance.font.size.small
                    elide: Text.ElideRight
                }
            }

            SplitButton {
                id: screenshotSplit
                // Ensure the main action area stays interactive and above potential siblings
                z: 2
                disabled: false
                active: menuItems.find(m => root.props.screenshotMode === m.icon + m.text) ?? menuItems[0]
                menu.onItemSelected: item => root.props.screenshotMode = item.icon + item.text
                // Be explicit: the primary click target is enabled
                stateLayer.disabled: false

                menuItems: [
                    MenuItem {
                        icon: "screenshot"
                        text: qsTr("Area (edit)")
                        activeText: qsTr("Area")
                        onClicked: {
                            root.visibilities.utilities = false;
                            root.visibilities.sidebar = false;
                            pendingCommand = ["caelestia", "shell", "picker", "openFreeze"];
                            delayTimer.start();
                        }
                    },
                    MenuItem {
                        icon: "screenshot_region"
                        text: qsTr("Active window (edit)")
                        activeText: qsTr("Window")
                        onClicked: {
                            root.visibilities.utilities = false;
                            root.visibilities.sidebar = false;
                            pendingCommand = ["caelestia", "shell", "picker", "open"];
                            delayTimer.start();
                        }
                    }
                ]
            }
        }

        Loader {
            id: screenshotLoader

            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
            sourceComponent: screenshotList

            Behavior on Layout.preferredHeight {
                id: screenshotHeightAnim

                enabled: false

                Anim {}
            }
        }
    }

    Component {
        id: screenshotList

        ScreenshotList {
            props: root.props
            visibilities: root.visibilities
        }
    }

    property var pendingCommand: []

    Timer {
        id: delayTimer

        interval: 300

        onTriggered: {
            if (pendingCommand.length > 0) {
                Quickshell.execDetached(pendingCommand);
                pendingCommand = [];
            }
        }
    }
}
