pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.services

// The privacy indicator gets its own layer-shell surface, one per screen.
//
// It deliberately does NOT live in modules/drawers alongside the other panels:
// those all share a single fullscreen window whose background is one merged
// metaball surface and whose input mask is derived from every panel's geometry.
// Adding a panel there changes how the rest of the shell is drawn and masked.
// This window owns only the few hundred pixels under the webcam and leaves the
// shell's own compositing completely alone.
Scope {
    Variants {
        model: Screens.screens

        StyledWindow {
            id: win

            required property ShellScreen modelData

            // Config is attached and does not resolve on the window itself,
            // so go through contentItem as the border thickness below does.
            readonly property bool shouldShow: contentItem.Config.privacy.enabled && contentItem.Config.privacy.showIndicator && Privacy.anyActive

            // 0 hidden above the top edge, 1 fully dropped.
            property real reveal: shouldShow ? 1 : 0

            // Clear the shell's border ring so the pill hangs just below it.
            readonly property real topInset: contentItem.Config.border.thickness + contentItem.Tokens.padding.small

            // The surface is sized to the pill, so the Elevation shadow would
            // be clipped at its edges without room to spill into.
            readonly property real shadowMargin: 20

            screen: modelData
            name: "privacy"

            // Never reserve space and never push other windows around.
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            // Anchoring only to the top centres the surface horizontally.
            anchors.top: true

            visible: reveal > 0
            implicitWidth: pill.implicitWidth + shadowMargin * 2
            implicitHeight: topInset + pill.implicitHeight + shadowMargin

            // Everything except the pill itself must stay click-through.
            mask: Region {
                item: win.reveal > 0.99 ? pill : null
            }

            Behavior on reveal {
                Anim {}
            }

            PrivacyPill {
                id: pill

                anchors.horizontalCenter: parent.horizontalCenter

                y: -implicitHeight + win.reveal * (win.topInset + implicitHeight)
                opacity: win.reveal
            }
        }
    }
}
