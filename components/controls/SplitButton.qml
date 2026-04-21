import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

Row {
    id: root

    enum Type {
        Filled,
        Tonal
    }

    property real horizontalPadding: Tokens.padding.normal
    property real verticalPadding: Tokens.padding.smaller
    property int type: SplitButton.Filled
    property bool disabled
    property bool menuOnTop
    property string fallbackIcon
    property string fallbackText

    property alias menuItems: menu.items
    property alias active: menu.active
    property alias expanded: menu.expanded
    property alias menu: menu
    property alias iconLabel: iconLabel
    property alias label: label
    property alias stateLayer: stateLayer

    property color colour: type == SplitButton.Filled ? Colours.palette.m3primary : Colours.palette.m3secondaryContainer
    property color textColour: type == SplitButton.Filled ? Colours.palette.m3onPrimary : Colours.palette.m3onSecondaryContainer
    property color disabledColour: Qt.alpha(Colours.palette.m3onSurface, 0.1)
    property color disabledTextColour: Qt.alpha(Colours.palette.m3onSurface, 0.38)

    spacing: Math.floor(Tokens.spacing.small / 2)

    StyledRect {
        radius: implicitHeight / 2 * Math.min(1, Tokens.rounding.scale)
        topRightRadius: Tokens.rounding.small / 2
        bottomRightRadius: Tokens.rounding.small / 2
        color: root.disabled ? root.disabledColour : root.colour

        implicitWidth: textRow.implicitWidth + root.horizontalPadding * 2
        implicitHeight: expandBtn.implicitHeight

        StateLayer {
            id: stateLayer

            rect.topRightRadius: parent.topRightRadius
            rect.bottomRightRadius: parent.bottomRightRadius
            color: root.textColour
            disabled: root.disabled
            onClicked: root.active?.clicked()
        }

        RowLayout {
            id: textRow

            anchors.centerIn: parent
            anchors.horizontalCenterOffset: Math.floor(root.verticalPadding / 4)
            spacing: Tokens.spacing.small

            MaterialIcon {
                id: iconLabel

                Layout.alignment: Qt.AlignVCenter
                animate: true
                text: root.active?.activeIcon ?? root.fallbackIcon
                color: root.disabled ? root.disabledTextColour : root.textColour
                fill: 1
            }

            StyledText {
                id: label

                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: implicitWidth
                animate: true
                text: root.active?.activeText ?? root.fallbackText
                color: root.disabled ? root.disabledTextColour : root.textColour
                clip: true

                Behavior on Layout.preferredWidth {
                    Anim {
                        type: Anim.Emphasized
                    }
                }
            }
        }
    }

    StyledRect {
        id: expandBtn

        property real rad: root.expanded ? implicitHeight / 2 * Math.min(1, Tokens.rounding.scale) : Tokens.rounding.small / 2

        radius: implicitHeight / 2 * Math.min(1, Tokens.rounding.scale)
        topLeftRadius: rad
        bottomLeftRadius: rad
        color: root.disabled ? root.disabledColour : root.colour

        implicitWidth: implicitHeight
        implicitHeight: expandIcon.implicitHeight + root.verticalPadding * 2

        StateLayer {
            id: expandStateLayer

            rect.topLeftRadius: parent.topLeftRadius
            rect.bottomLeftRadius: parent.bottomLeftRadius
            color: root.textColour
            disabled: root.disabled
            onClicked: root.expanded = !root.expanded
        }

        MaterialIcon {
            id: expandIcon

            anchors.centerIn: parent
            anchors.horizontalCenterOffset: root.expanded ? 0 : -Math.floor(root.verticalPadding / 4)

            text: "expand_more"
            color: root.disabled ? root.disabledTextColour : root.textColour
            rotation: root.expanded ? 180 : 0

            Behavior on anchors.horizontalCenterOffset {
                Anim {}
            }

            Behavior on rotation {
                Anim {}
            }
        }

        Behavior on rad {
            Anim {}
        }
    }

    Menu {
        id: menu

        attachTo: expandBtn
        attachSideY: root.menuOnTop ? Menu.Top : Menu.Bottom
        thisSideY: root.menuOnTop ? Menu.Bottom : Menu.Top
        marginY: Tokens.spacing.small * (root.menuOnTop ? -1 : 1)
    }
}
