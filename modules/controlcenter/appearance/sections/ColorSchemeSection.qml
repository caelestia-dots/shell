pragma ComponentBehavior: Bound

import ".."
import "../../../launcher/services"
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts

CollapsibleSection {
    title: qsTr("Color scheme")
    description: qsTr("Available color schemes")
    showBackground: true

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.small / 2

        Repeater {
            model: Schemes.list

            delegate: StyledRect {
                required property var modelData

                Layout.fillWidth: true

                readonly property string schemeKey: `${modelData.name} ${modelData.flavour}`
                readonly property bool isCurrent: schemeKey === Schemes.currentScheme

                color: Qt.alpha(Colours.tPalette.m3surfaceContainer, isCurrent ? Colours.tPalette.m3surfaceContainer.a : 0)
                radius: Appearance.rounding.normal
                border.width: isCurrent ? 1 : 0
                border.color: Colours.palette.m3primary

                StateLayer {
                    function onClicked(): void {
                        const name = modelData.name;
                        const flavour = modelData.flavour;
                        const schemeKey = `${name} ${flavour}`;

                        Schemes.currentScheme = schemeKey;
                        Quickshell.execDetached(["caelestia", "scheme", "set", "-n", name, "-f", flavour]);

                        Qt.callLater(() => {
                            reloadTimer.restart();
                        });
                    }
                }

                Timer {
                    id: reloadTimer
                    interval: 300
                    onTriggered: {
                        Schemes.reload();
                    }
                }

                RowLayout {
                    id: schemeRow

                    anchors.fill: parent
                    anchors.margins: Appearance.padding.normal

                    spacing: Appearance.spacing.normal

                    StyledRect {
                        id: preview

                        Layout.alignment: Qt.AlignVCenter

                        border.width: 1
                        border.color: Qt.alpha(`#${modelData.colours?.outline}`, 0.5)

                        color: `#${modelData.colours?.surface}`
                        radius: Appearance.rounding.full
                        implicitWidth: iconPlaceholder.implicitWidth
                        implicitHeight: iconPlaceholder.implicitWidth

                        MaterialIcon {
                            id: iconPlaceholder
                            visible: false
                            text: "circle"
                            font.pointSize: Appearance.font.size.large
                        }

                        Item {
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.right: parent.right

                            implicitWidth: parent.implicitWidth / 2
                            clip: true

                            StyledRect {
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                anchors.right: parent.right

                                implicitWidth: preview.implicitWidth
                                color: `#${modelData.colours?.primary}`
                                radius: Appearance.rounding.full
                            }
                        }
                    }

                    Column {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            text: modelData.flavour ?? ""
                            font.pointSize: Appearance.font.size.normal
                        }

                        StyledText {
                            text: modelData.name ?? ""
                            font.pointSize: Appearance.font.size.small
                            color: Colours.palette.m3outline

                            elide: Text.ElideRight
                            anchors.left: parent.left
                            anchors.right: parent.right
                        }
                    }

                    Loader {
                        active: isCurrent
                        asynchronous: true

                        sourceComponent: MaterialIcon {
                            text: "check"
                            color: Colours.palette.m3onSurfaceVariant
                            font.pointSize: Appearance.font.size.large
                        }
                    }
                }

                implicitHeight: schemeRow.implicitHeight + Appearance.padding.normal * 2
            }
        }
    }
}

