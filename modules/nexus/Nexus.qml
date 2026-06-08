pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Blobs
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus

Item {
    id: root

    readonly property NexusState nState: NexusState {
        id: nState

        onClose: root.close()
    }
    property color blobColour: Colours.tPalette.m3surfaceContainerLow

    signal close

    implicitWidth: implicitHeight * Tokens.sizes.nexus.ratio
    implicitHeight: nState.screen.height * Tokens.sizes.nexus.heightMult

    Behavior on blobColour {
        CAnim {}
    }

    BlobGroup {
        id: blobGroup

        smoothing: root.Tokens.rounding.medium
        color: root.blobColour
    }

    BlobInvertedRect {
        anchors.fill: parent
        group: blobGroup
        opacity: root.blobColour.a
        radius: Tokens.rounding.large

        borderLeft: navPane.width + navPane.anchors.margins * 2
        borderRight: Tokens.padding.medium
        borderTop: Tokens.padding.medium
        borderBottom: Tokens.padding.medium
    }

    BlobRect {
        id: windowBtnRect

        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: root.nState.isWindow ? 0 : Tokens.padding.extraSmall

        group: blobGroup
        opacity: root.blobColour.a
        radius: Tokens.rounding.medium

        implicitWidth: windowBtn.implicitWidth + (root.nState.isWindow ? Tokens.padding.extraSmall : Tokens.padding.small) * 2
        implicitHeight: windowBtn.implicitHeight + (root.nState.isWindow ? Tokens.padding.extraSmall : Tokens.padding.small)
    }

    IconButton {
        id: windowBtn

        anchors.centerIn: windowBtnRect
        icon: nState.isWindow ? "close" : "pip"
        type: IconButton.Text
        label.fill: 0
        inactiveOnColour: hovered ? nState.isWindow ? Colours.palette.m3error : Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
        stateLayer.opacity: 0
        onClicked: {
            if (!nState.isWindow)
                WindowFactory.create();
            root.close();
        }

        label.scale: pressed ? 0.8 : 1
        label.renderType: Text.QtRendering

        Behavior on label.scale {
            Anim {}
        }
    }

    NavPane {
        id: navPane

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.margins: Tokens.padding.large

        nState: nState
        width: Math.min(Tokens.sizes.nexus.maxNavWidth, Math.round(root.width / 3))
    }

    Pages {
        anchors.left: navPane.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: navPane.anchors.margins + anchors.margins
        anchors.margins: Tokens.padding.extraLarge

        nState: nState
    }
}
