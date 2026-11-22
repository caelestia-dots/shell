import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Caelestia.Config
import qs.components
import qs.components.hallownest
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

            HkCard {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ornate: true
                clip: true

                Details {
                    client: root.client
                }
            }

            HkCard {
                Layout.fillWidth: true
                Layout.preferredHeight: buttons.implicitHeight

                Buttons {
                    id: buttons

                    client: root.client
                }
            }
        }
    }
}
