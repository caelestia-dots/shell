pragma ComponentBehavior: Bound

import "../../../launcher/services"
import qs.components
import qs.components.controls
import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts

CollapsibleSection {
    title: qsTr("Color variant")
    description: qsTr("Material theme variant")
    showBackground: true

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.small / 2

        Repeater {
            model: M3Variants.list

            delegate: StyledRect {
                id: colorVariant

                required property var modelData

                Layout.fillWidth: true

                color: Qt.alpha(Colours.tPalette.m3surfaceContainer, modelData.variant === Schemes.currentVariant ? Colours.tPalette.m3surfaceContainer.a : 0)
                radius: Appearance.rounding.normal
                border.width: modelData.variant === Schemes.currentVariant ? 1 : 0
                border.color: Colours.palette.m3primary

                StateLayer {
                    function onClicked(): void {
                        const variant = colorVariant.modelData.variant;

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
                    anchors.margins: Appearance.padding.normal

                    spacing: Appearance.spacing.normal

                    MaterialIcon {
                        text: colorVariant.modelData.icon
                        font.pointSize: Appearance.font.size.large
                        fill: colorVariant.modelData.variant === Schemes.currentVariant ? 1 : 0
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: colorVariant.modelData.name
                        font.weight: colorVariant.modelData.variant === Schemes.currentVariant ? 500 : 400
                    }

                    MaterialIcon {
                        visible: colorVariant.modelData.variant === Schemes.currentVariant
                        text: "check"
                        color: Colours.palette.m3primary
                        font.pointSize: Appearance.font.size.large
                    }
                }

                implicitHeight: variantRow.implicitHeight + Appearance.padding.normal * 2
            }
        }
    }
}
