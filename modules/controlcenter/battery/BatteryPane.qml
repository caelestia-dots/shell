pragma ComponentBehavior: Bound

import ".."
import "../components"
import "." as Power
import qs.components
import qs.components.controls
import qs.components.effects
import qs.components.containers
import qs.services
import qs.config
import qs.utils
import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property Session session

    property bool enabled: Config.general.battery.powerManagement.enabled ?? false

    anchors.fill: parent

    function saveConfig() {
        Config.general.battery.powerManagement.enabled = root.enabled;
        Config.save();
    }

    ClippingRectangle {
        id: powerClippingRect
        anchors.fill: parent
        anchors.margins: Appearance.padding.normal
        anchors.leftMargin: 0
        anchors.rightMargin: Appearance.padding.normal

        radius: powerBorder.innerRadius
        color: "transparent"

        Loader {
            id: powerLoader

            anchors.fill: parent
            anchors.margins: Appearance.padding.large + Appearance.padding.normal
            anchors.leftMargin: Appearance.padding.large
            anchors.rightMargin: Appearance.padding.large

            sourceComponent: powerContentComponent
        }
    }

    InnerBorder {
        id: powerBorder
        leftThickness: 0
        rightThickness: Appearance.padding.normal
    }

    Component {
        id: powerContentComponent

        StyledFlickable {
            id: powerFlickable
            flickableDirection: Flickable.VerticalFlick
            contentHeight: powerLayout.height

            StyledScrollBar.vertical: StyledScrollBar {
                flickable: powerFlickable
            }

            ColumnLayout {
                id: powerLayout
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top

                spacing: Appearance.spacing.normal

                RowLayout {
                    spacing: Appearance.spacing.smaller

                    StyledText {
                        text: qsTr("Power Management")
                        font.pointSize: Appearance.font.size.large
                        font.weight: 500
                    }
                }

                SectionContainer {
                    Layout.fillWidth: true
                    alignTop: true

                    SwitchRow {
                        label: qsTr("Enable power management")
                        checked: root.enabled
                        onToggled: checked => {
                            root.enabled = checked;
                            root.saveConfig();
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.normal
                    
                    Power.ChargingBehaviorSection {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: 0
                        Layout.alignment: Qt.AlignTop
                        rootItem: root
                    }
                    
                    Power.ThresholdsSection {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: 0
                        Layout.maximumWidth: parent.width * 0.4
                        Layout.alignment: Qt.AlignTop
                        rootItem: root
                    }
                }

                Power.ProfileBehaviorsSection {
                    Layout.fillWidth: true
                    rootItem: root
                }
            }
        }
    }
}
