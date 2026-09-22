import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property Props props
    required property ScreenState screenState
    property bool docked
    property bool dockedAbove

    ColumnLayout {
        id: layout

        anchors.fill: parent
        spacing: 0

        Separator {
            visible: root.docked && root.dockedAbove
            atTop: true
        }

        StyledRect {
            Layout.fillWidth: true
            Layout.fillHeight: true

            radius: Tokens.rounding.large
            color: Colours.tPalette.m3surfaceContainerLow

            NotifDock {
                objectName: "sidebarNotifications"

                props: root.props
                screenState: root.screenState
            }
        }

        Separator {
            visible: root.docked && !root.dockedAbove
        }
    }

    component Separator: Item {
        id: sep

        property bool atTop

        Layout.fillWidth: true
        implicitHeight: Tokens.padding.large + 1

        StyledRect {
            y: sep.atTop ? 0 : sep.height - height
            width: sep.width
            height: 1

            color: Colours.palette.m3outlineVariant
        }
    }
}
