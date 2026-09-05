import QtQuick
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.nexus as Nexus

// Always-present slot in the taskbar that lights up while any watched device
// is in use. Collapses to zero height when idle so it costs no bar space.
Item {
    id: root

    readonly property bool shown: Config.privacy.enabled && Config.privacy.showBarIndicator && Privacy.anyActive
    readonly property var primary: Privacy.active[0] ?? null

    readonly property real size: Math.round(Tokens.font.body.large.pointSize * 1.1)

    // Vertical space this occupies on top of its own height, i.e. its layout
    // margin. Folded into nonAnimHeight below.
    property real reservedMargin: 0

    // ActiveWindow decides how far it may elide the window title by summing
    // the heights of the other bar children, filtering them on entryId. These
    // three make this dot visible to that sum: without them a long title is
    // elided as though the dot took no space, and the extra height pushes the
    // dot off the bottom of the screen.
    readonly property string entryId: "privacy"
    readonly property Item item: root
    readonly property real nonAnimHeight: shown ? size + reservedMargin : 0

    implicitWidth: size
    implicitHeight: shown ? size : 0
    opacity: shown ? 1 : 0

    Behavior on implicitHeight {
        Anim {}
    }

    Behavior on opacity {
        Anim {
            type: Anim.DefaultEffects
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.shown
        cursorShape: Qt.PointingHandCursor
        onClicked: Nexus.WindowFactory.create()
    }

    StyledRect {
        anchors.centerIn: parent

        implicitWidth: root.size * 0.55
        implicitHeight: root.size * 0.55
        radius: width / 2

        color: {
            const id = root.primary?.id ?? "";
            if (id === "microphone" || id === "camera")
                return Colours.palette.m3error;
            if (id === "screen")
                return Colours.palette.m3tertiary;
            return Colours.palette.m3secondary;
        }

        scale: root.shown ? 1 : 0.4

        Behavior on scale {
            Anim {}
        }

        // No Behavior on color: StyledRect already carries one.

        // Slow pulse so the dot reads as live rather than as a static badge.
        SequentialAnimation on opacity {
            running: root.shown
            loops: Animation.Infinite
            alwaysRunToEnd: true

            NumberAnimation {
                to: 0.45
                duration: 900
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                to: 1
                duration: 900
                easing.type: Easing.InOutQuad
            }
        }
    }
}
