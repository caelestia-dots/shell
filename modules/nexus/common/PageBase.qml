pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services
import qs.modules.nexus

ColumnLayout {
    id: root

    required property string title
    required property NexusState nState
    property bool isSubPage
    readonly property int cappedWidth: Math.min(800, width)

    default property Item contentChild

    spacing: Tokens.spacing.extraLargeIncreased

    RowLayout {
        spacing: Tokens.spacing.largeIncreased

        Loader {
            visible: active
            active: root.isSubPage
            asynchronous: true
            sourceComponent: IconButton {
                icon: "arrow_back"
                font: Tokens.font.icon.medium
                type: IconButton.Tonal
                isRound: true
                inactiveColour: Colours.tPalette.m3surfaceContainerHigh
                inactiveOnColour: Colours.palette.m3onSurfaceVariant
                onClicked: root.nState.closeSubPage()
            }
        }

        StyledText {
            text: root.title
            font: Tokens.font.title.large
        }
    }

    VerticalFadeFlickable {
        id: flickable

        Layout.fillWidth: true
        Layout.fillHeight: true

        Layout.topMargin: -topMargin
        topMargin: Tokens.padding.large
        bottomMargin: Tokens.padding.extraLarge

        contentHeight: root.contentChild?.implicitHeight ?? 0
        contentItem.children: [root.contentChild]
    }
}
