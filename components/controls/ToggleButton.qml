import ".."
import qs.components
import qs.components.effects
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

StyledRect {
    id: root

    required property bool toggled
    property string icon
    property string label
    property string accent: "Secondary"

    signal clicked

    Layout.preferredWidth: implicitWidth + (toggleStateLayer.pressed ? Appearance.padding.normal * 2 : toggled ? Appearance.padding.small * 2 : 0)
    implicitWidth: toggleBtnInner.implicitWidth + Appearance.padding.large * 2
    implicitHeight: toggleBtnIcon.implicitHeight + Appearance.padding.normal * 2

    radius: toggled || toggleStateLayer.pressed ? Appearance.rounding.small : Math.min(width, height) / 2 * Math.min(1, Appearance.rounding.scale)
    color: toggled ? Colours.palette[`m3${accent.toLowerCase()}`] : Colours.palette[`m3${accent.toLowerCase()}Container`]

    StateLayer {
        id: toggleStateLayer

        color: root.toggled ? Colours.palette[`m3on${root.accent}`] : Colours.palette[`m3on${root.accent}Container`]

        function onClicked(): void {
            root.clicked();
        }
    }

    RowLayout {
        id: toggleBtnInner

        anchors.centerIn: parent
        spacing: Appearance.spacing.normal

        MaterialIcon {
            id: toggleBtnIcon

            visible: !!text
            fill: root.toggled ? 1 : 0
            text: root.icon
            color: root.toggled ? Colours.palette[`m3on${root.accent}`] : Colours.palette[`m3on${root.accent}Container`]
            font.pointSize: Appearance.font.size.large

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
            duration: Appearance.anim.durations.expressiveFastSpatial
            easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
        }
    }

    Behavior on Layout.preferredWidth {
        Anim {
            duration: Appearance.anim.durations.expressiveFastSpatial
            easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
        }
    }
}

