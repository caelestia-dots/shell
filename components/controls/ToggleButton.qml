pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

StyledRect {
    id: root

    required property bool toggled
    property string icon
    property string label
    property string accent: "Secondary"
    property real iconSize: Tokens.font.size.large
    property real horizontalPadding: Tokens.padding.large
    property real verticalPadding: Tokens.padding.normal
    property string tooltip: ""
    property bool hovered: false

    signal clicked

    Component.onCompleted: hovered = toggleStateLayer.containsMouse

    Layout.preferredWidth: implicitWidth + (toggleStateLayer.pressed ? Tokens.padding.normal * 2 : toggled ? Tokens.padding.small * 2 : 0)
    implicitWidth: toggleBtnInner.implicitWidth + horizontalPadding * 2
    implicitHeight: toggleBtnIcon.implicitHeight + verticalPadding * 2
    radius: toggled || toggleStateLayer.pressed ? Tokens.rounding.small : Math.min(width, height) / 2 * Math.min(1, Tokens.rounding.scale)
    color: toggled ? Colours.palette[`m3${accent.toLowerCase()}`] : Colours.palette[`m3${accent.toLowerCase()}Container`]

    Connections {
        function onContainsMouseChanged() {
            const newHovered = toggleStateLayer.containsMouse;
            if (root.hovered !== newHovered) {
                root.hovered = newHovered;
            }
        }

        target: toggleStateLayer
    }

    StateLayer {
        id: toggleStateLayer

        color: root.toggled ? Colours.palette[`m3on${root.accent}`] : Colours.palette[`m3on${root.accent}Container`]
        onClicked: root.clicked()
    }

    RowLayout {
        id: toggleBtnInner

        anchors.centerIn: parent
        spacing: Tokens.spacing.normal

        MaterialIcon {
            id: toggleBtnIcon

            visible: !!text
            fill: root.toggled ? 1 : 0
            text: root.icon
            color: root.toggled ? Colours.palette[`m3on${root.accent}`] : Colours.palette[`m3on${root.accent}Container`]
            font.pointSize: root.iconSize

            Behavior on fill {
                Anim {}
            }
        }

        Loader {
            asynchronous: true
            active: !!root.label
            visible: active

            sourceComponent: StyledText {
                text: root.label
                color: root.toggled ? Colours.palette[`m3on${root.accent}`] : Colours.palette[`m3on${root.accent}Container`]
            }
        }
    }

    Behavior on radius {
        Anim {
            type: Anim.FastSpatial
        }
    }

    Behavior on Layout.preferredWidth {
        Anim {
            type: Anim.FastSpatial
        }
    }

    // Tooltip - positioned absolutely, doesn't affect layout
    Loader {
        id: tooltipLoader

        asynchronous: true
        active: root.tooltip !== ""
        z: 10000
        width: 0
        height: 0
        sourceComponent: Component {
            Tooltip {
                target: root
                text: root.tooltip
            }
        }
        // Completely remove from layout
        Layout.fillWidth: false
        Layout.fillHeight: false
        Layout.preferredWidth: 0
        Layout.preferredHeight: 0
        Layout.maximumWidth: 0
        Layout.maximumHeight: 0
        Layout.minimumWidth: 0
        Layout.minimumHeight: 0
    }
}
