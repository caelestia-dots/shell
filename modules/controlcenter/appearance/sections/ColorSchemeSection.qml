pragma ComponentBehavior: Bound

import ".."
import "../../../launcher/services"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services

CollapsibleSection {
    title: qsTr("Color scheme")
    description: qsTr("Available color schemes")
    showBackground: true

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.small / 2

        Repeater {
            model: Schemes.list

            delegate: StyledRect {
                required property var modelData

                Layout.fillWidth: true

                readonly property string schemeKey: `${modelData.name} ${modelData.flavour}`
                readonly property bool isCurrent: schemeKey === Schemes.currentScheme

                color: Qt.alpha(Colours.tPalette.m3surfaceContainer, isCurrent ? Colours.tPalette.m3surfaceContainer.a : 0)
                radius: Tokens.rounding.normal
                border.width: isCurrent ? 1 : 0
                border.color: Colours.palette.m3primary
                implicitHeight: schemeRow.implicitHeight + Tokens.padding.normal * 2

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
                    anchors.margins: Tokens.padding.normal

                    spacing: Tokens.spacing.normal

                    StyledRect {
                        id: preview

                        Layout.alignment: Qt.AlignVCenter

                        border.width: 1
                        border.color: Qt.alpha(`#${modelData.colours?.outline}`, 0.5)

                        color: `#${modelData.colours?.surface}`
                        radius: Tokens.rounding.full
                        implicitWidth: iconPlaceholder.implicitWidth
                        implicitHeight: iconPlaceholder.implicitWidth

                        MaterialIcon {
                            id: iconPlaceholder

                            visible: false
                            text: "circle"
                            font.pointSize: Tokens.font.size.large
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
                                radius: Tokens.rounding.full
                            }
                        }
                    }

                    Column {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            text: modelData.flavour ?? ""
                            font.pointSize: Tokens.font.size.normal
                        }

                        StyledText {
                            text: modelData.name ?? ""
                            font.pointSize: Tokens.font.size.small
                            color: Colours.palette.m3outline

                            elide: Text.ElideRight
                            anchors.left: parent.left
                            anchors.right: parent.right
                        }
                    }

                    Loader {
                        asynchronous: true
                        active: isCurrent

                        sourceComponent: MaterialIcon {
                            text: "check"
                            color: Colours.palette.m3onSurfaceVariant
                            font.pointSize: Tokens.font.size.large
                        }
                    }
                }
            }
        }
    }
}
