import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property ShellScreen screen
    required property HyprlandToplevel client

    implicitWidth: child.implicitWidth
    implicitHeight: screen.height * Tokens.sizes.winfo.heightMult

    RowLayout {
        id: child

        anchors.fill: parent
        anchors.margins: Tokens.padding.large

        spacing: Tokens.spacing.medium

        Preview {
            screen: root.screen
            client: root.client
        }

        ColumnLayout {
            spacing: Tokens.spacing.medium

            Layout.preferredWidth: Tokens.sizes.winfo.detailsWidth
            Layout.fillHeight: true

            StyledRect {
                Layout.fillWidth: true
                Layout.fillHeight: true

                color: Colours.tPalette.m3surfaceContainer
                radius: Tokens.rounding.large

                Details {
                    client: root.client
                }
            }

            StyledRect {
                Layout.fillWidth: true
                Layout.preferredHeight: buttons.implicitHeight

                color: Colours.tPalette.m3surfaceContainer
                radius: Tokens.rounding.large

                Buttons {
                    id: buttons

                    client: root.client
                }
            }
        }
    }
}
