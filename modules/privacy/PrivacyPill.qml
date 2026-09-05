pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.services
import qs.modules.nexus as Nexus

// The pill itself: an icon per live sensor, plus a label that slides open on
// arrival and retracts to leave just the icons.
//
// Draws its own rounded background, since this lives on its own surface rather
// than on the shell's shared blob layer.
StyledRect {
    id: root

    // Expanded shows the labels; collapsed leaves only the icons.
    property bool expanded: true
    property bool hovered
    readonly property bool showLabels: expanded || hovered

    readonly property var sensors: Privacy.active
    readonly property var primary: sensors[0] ?? null

    // Tints the border, so the surface itself stays quiet enough to live on
    // screen for a whole call while still carrying the severity.
    readonly property color accent: colourFor(primary?.id ?? "")

    function colourFor(id: string): color {
        if (id === "microphone" || id === "camera")
            return Colours.palette.m3error;
        if (id === "screen")
            return Colours.palette.m3tertiary;
        return Colours.palette.m3secondary;
    }

    function expand(): void {
        expanded = true;
        collapse.restart();
    }

    implicitWidth: layout.implicitWidth + Tokens.padding.large * 2
    implicitHeight: layout.implicitHeight + Tokens.padding.medium * 2

    // Capsule via the rounding token rather than height / 2, so it tracks the
    // appearance scale like every other surface. tPalette honours the user's
    // transparency setting; StyledRect already animates colour through CAnim,
    // so a scheme change fades rather than snaps.
    radius: Tokens.rounding.full
    color: Colours.tPalette.m3surfaceContainer

    // Same treatment as a toast, which is the closest thing in the shell to a
    // floating surface over arbitrary windows.
    border.width: 1
    border.color: Qt.alpha(accent, 0.3)

    // No Behavior on implicitWidth: the width already follows the label's
    // animated Layout.preferredWidth below. Animating it a second time here
    // lets the centred row outrun the background, so the text spills past the
    // rounded edges for the length of the transition.

    onHoveredChanged: {
        if (hovered)
            expanded = true;
        else
            collapse.restart();
    }

    Elevation {
        anchors.fill: parent
        radius: parent.radius
        opacity: parent.opacity
        z: -1
        level: 3
    }

    Connections {
        // Re-expand when another device lights up while one is already on.
        function onActiveChanged(): void {
            root.expand();
        }

        target: Privacy
    }

    Timer {
        id: collapse

        // GlobalConfig rather than the attached Config: a Timer is not an Item
        // so it has no screen for the attached property to resolve against,
        // and this value is not per monitor anyway.
        interval: GlobalConfig.privacy.expandDuration
        onTriggered: if (!root.hovered)
            root.expanded = false
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onEntered: root.hovered = true
        onExited: root.hovered = false
        onClicked: Nexus.WindowFactory.create()
    }

    RowLayout {
        id: layout

        anchors.centerIn: parent
        spacing: Tokens.spacing.small

        Repeater {
            model: ScriptModel {
                values: root.sensors
            }

            MaterialIcon {
                required property var modelData

                text: modelData.icon
                color: root.colourFor(modelData.id)
                fill: 1
                // grade deliberately left at MaterialIcon's default
                // (Colours.light ? 0 : -25) so the icon reweights in light mode.
                fontStyle: Tokens.font.icon.medium
            }
        }

        // Width animates to zero so the pill can shrink to the icons without
        // the text reflowing on the way out.
        Item {
            Layout.preferredWidth: root.showLabels ? label.implicitWidth : 0
            Layout.preferredHeight: label.implicitHeight
            Layout.leftMargin: root.showLabels ? Tokens.spacing.small : 0
            clip: true
            opacity: root.showLabels ? 1 : 0

            Behavior on Layout.preferredWidth {
                Anim {}
            }

            Behavior on Layout.leftMargin {
                Anim {}
            }

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            RowLayout {
                id: label

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: Tokens.spacing.small

                StyledText {
                    text: root.primary ? Privacy.summary(root.primary) : ""
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurface
                }

                StyledText {
                    visible: root.primary && root.primary.apps.length > 0
                    text: root.primary ? Privacy.describe(root.primary) : ""
                    font: Tokens.font.label.small
                    color: Colours.palette.m3outline
                }

                // "+2" when several devices are live at once.
                StyledText {
                    visible: root.sensors.length > 1
                    text: `+${root.sensors.length - 1}`
                    font: Tokens.font.label.small
                    color: Colours.palette.m3outline
                }
            }
        }
    }
}
