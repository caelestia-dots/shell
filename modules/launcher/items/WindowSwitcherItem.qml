import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Caelestia.Config
import Caelestia.Models
import qs.components
import qs.components.images
import qs.components.controls
import qs.services

Item {
    id: root

    required property var modelData
    required property var list

    scale: 0.5
    opacity: 0
    z: PathView.z ?? 0

    Component.onCompleted: {
        scale = Qt.binding(() => PathView.isCurrentItem ? 1 : PathView.onPath ? 0.8 : 0);
        opacity = Qt.binding(() => PathView.onPath ? 1 : 0);
    }

    implicitWidth: previewBox.width + Tokens.padding.larger * 2
    implicitHeight: previewBox.height + label.height + Tokens.spacing.small / 2 + Tokens.padding.large + Tokens.padding.normal

    StateLayer {
        radius: Tokens.rounding.normal
        onClicked: root.clicked()
    }

    function clicked(): void {
        Hyprland.dispatch(`focuswindow address:0x${root.modelData.address}`);
        root.list.visibilities.launcher = false;
    }

    StyledRect {
        id: shadowRect

        anchors.fill: previewBox
        radius: previewBox.radius
        color: Colours.layer(Colours.palette.m3surfaceContainerHighest, root.PathView.isCurrentItem ? 1 : 0)
        opacity: root.PathView.isCurrentItem ? 1 : 0

        Behavior on opacity {
            Anim {}
        }
    }

    StyledClippingRect {
        id: previewBox

        anchors.horizontalCenter: parent.horizontalCenter
        y: Tokens.padding.large
        color: Colours.tPalette.m3surfaceContainer
        radius: Tokens.rounding.normal

        implicitWidth: Tokens.sizes.launcher.windowSwitcherWidth
        implicitHeight: implicitWidth / 16 * 9

        ScreencopyView {
            anchors.fill: parent
            captureSource: root.modelData?.wayland ?? null
            live: true
            smooth: !(root.PathView.view?.moving ?? false)
        }
    }

    StyledText {
        id: label

        anchors.top: previewBox.bottom
        anchors.topMargin: Tokens.spacing.small / 2
        anchors.horizontalCenter: parent.horizontalCenter

        width: previewBox.width - Tokens.padding.normal * 2
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        renderType: Text.QtRendering
        text: root.modelData?.title ?? ""
        font.pointSize: Tokens.font.size.normal
    }

    Behavior on scale {
        Anim {}
    }

    Behavior on opacity {
        Anim {}
    }
}