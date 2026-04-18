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
    title: qsTr("Color variant")
    description: qsTr("Material theme variant")
    showBackground: true

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.small / 2

        Repeater {
            model: M3Variants.list

            delegate: StyledRect {
                required property var modelData

                Layout.fillWidth: true

                color: Qt.alpha(Colours.tPalette.m3surfaceContainer, modelData.variant === Schemes.currentVariant ? Colours.tPalette.m3surfaceContainer.a : 0)
                radius: Tokens.rounding.normal
                border.width: modelData.variant === Schemes.currentVariant ? 1 : 0
                border.color: Colours.palette.m3primary
                implicitHeight: variantRow.implicitHeight + Tokens.padding.normal * 2

                StateLayer {
                    onClicked: {
                        const variant = modelData.variant;

                        Schemes.currentVariant = variant;
                        Quickshell.execDetached(["caelestia", "scheme", "set", "-v", variant]);

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
                    id: variantRow

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Tokens.padding.normal

                    spacing: Tokens.spacing.normal

                    MaterialIcon {
                        text: modelData.icon
                        font.pointSize: Tokens.font.size.large
                        fill: modelData.variant === Schemes.currentVariant ? 1 : 0
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: modelData.name
                        font.weight: modelData.variant === Schemes.currentVariant ? 500 : 400
                    }

                    MaterialIcon {
                        visible: modelData.variant === Schemes.currentVariant
                        text: "check"
                        color: Colours.palette.m3primary
                        font.pointSize: Tokens.font.size.large
                    }
                }
            }
        }
    }
}
