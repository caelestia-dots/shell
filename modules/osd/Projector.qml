pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property ShellScreen screen
    required property PersistentProperties visibilities

    readonly property bool shouldBeActive: visibilities.projector

    visible: width > 0
    implicitWidth: 0
    implicitHeight: layout.implicitHeight + Appearance.padding.large * 2

    states: State {
        name: "visible"
        when: root.shouldBeActive

        PropertyChanges {
            root.implicitWidth: layout.implicitWidth + Appearance.padding.large * 2
        }
    }

    transitions: [
        Transition {
            from: ""
            to: "visible"

            Anim {
                target: root
                property: "implicitWidth"
                easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
            }
        },
        Transition {
            from: "visible"
            to: ""

            Anim {
                target: root
                property: "implicitWidth"
                easing.bezierCurve: Appearance.anim.curves.emphasized
            }
        }
    ]

    StyledRect {
        anchors.fill: parent
        radius: Appearance.rounding.large
        color: Colours.tPalette.m3surfaceContainer
        
        // Block mouse events
        CustomMouseArea { anchors.fill: parent }
    }

    ColumnLayout {
        id: layout
        anchors.centerIn: parent
        spacing: Appearance.spacing.normal

        ProjectorButton {
            id: internalBtn
            icon: "laptop"
            label: "PC screen only"
            mode: Display.DisplayMode.InternalOnly
            KeyNavigation.down: mirrorBtn
            Component.onCompleted: if (root.shouldBeActive) forceActiveFocus()
        }

        ProjectorButton {
            id: mirrorBtn
            icon: "content_copy"
            label: "Duplicate"
            mode: Display.DisplayMode.Mirror
            KeyNavigation.up: internalBtn
            KeyNavigation.down: extendBtn
        }

        ProjectorButton {
            id: extendBtn
            icon: "cast"
            label: "Extend"
            mode: Display.DisplayMode.Extend
            KeyNavigation.up: mirrorBtn
            KeyNavigation.down: externalBtn
        }

        ProjectorButton {
            id: externalBtn
            icon: "monitor"
            label: "Second screen only"
            mode: Display.DisplayMode.ExternalOnly
            KeyNavigation.up: extendBtn
        }
    }

    component ProjectorButton: StyledRect {
        id: button
        required property string icon
        required property string label
        required property int mode

        implicitWidth: 320
        implicitHeight: 74
        radius: Appearance.rounding.normal
        color: button.activeFocus ? Colours.palette.m3secondaryContainer : "transparent"

        RowLayout {
            anchors.fill: parent
            anchors.margins: Appearance.padding.large
            spacing: Appearance.spacing.large

            MaterialIcon {
                text: button.icon
                color: button.activeFocus ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                font.pointSize: Appearance.font.size.extraLarge
            }

            StyledText {
                text: button.label
                Layout.fillWidth: true
                color: button.activeFocus ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                font.pointSize: Appearance.font.size.normal
                font.weight: button.activeFocus ? 600 : 400
            }
        }

        StateLayer {
            radius: parent.radius
            onClicked: {
                Display.setMode(button.mode);
                root.visibilities.projector = false;
            }
        }

        Keys.onEnterPressed: {
            Display.setMode(button.mode);
            root.visibilities.projector = false;
        }
        Keys.onReturnPressed: {
            Display.setMode(button.mode);
            root.visibilities.projector = false;
        }
        Keys.onEscapePressed: root.visibilities.projector = false
    }
    
    onShouldBeActiveChanged: {
        if (shouldBeActive) {
            internalBtn.forceActiveFocus();
        }
    }
}
