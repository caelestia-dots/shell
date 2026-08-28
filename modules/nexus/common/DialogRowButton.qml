pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Blobs
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services

Item {
    id: root

    required property Item rootParent
    required property string icon
    required property string label
    required property string header
    required property Component content
    required property string acceptLabel
    property bool acceptAllowed: true
    property bool separateContent
    property int horizontalContentMargin

    property real openWidth: Math.min(rootParent.width * 0.8, Tokens.sizes.nexus.maxDialogWidth)
    property real openHeight: Math.min(rootParent.height * 0.8, Tokens.sizes.nexus.maxDialogHeight)
    property bool open

    signal accepted
    signal cancelled

    function reparentWrapper(): void {
        const newParent = open ? rootParent : root;
        const pos = dialogWrapper.mapToItem(newParent, 0, 0);
        dialogWrapper.parent = newParent;
        dialogWrapper.x = pos.x;
        dialogWrapper.y = pos.y;
    }

    Layout.fillWidth: true
    implicitHeight: openButton.implicitHeight
    z: open || dialogTransition.running ? 2 : 0

    BlobGroup {
        id: blobGroup

        color: root.open ? Colours.palette.m3surfaceContainerHighest : Colours.tPalette.m3surfaceContainer

        Behavior on color {
            CAnim {}
        }
    }

    MouseArea {
        id: backdrop

        anchors.fill: parent
        parent: root.open ? root.rootParent : root
        enabled: false
        hoverEnabled: enabled
        onClicked: root.open = false
    }

    Item {
        id: dialogWrapper

        z: 1
        width: root.width
        height: openButton.implicitHeight

        states: State {
            name: "open"
            when: root.open

            PropertyChanges {
                backdrop.enabled: true
                elevation.opacity: 1
                openButton.opacity: 0
                dialogContent.opacity: 1
                dialogBg.radius: root.Tokens.rounding.extraLargeIncreased
                dialogBg.bottomLeftRadius: root.Tokens.rounding.extraLargeIncreased
                dialogBg.bottomRightRadius: root.Tokens.rounding.extraLargeIncreased
                dialogWrapper.x: (root.rootParent.width - root.openWidth) / 2
                dialogWrapper.y: (root.rootParent.height - root.openHeight) / 2
                dialogWrapper.width: root.openWidth
                dialogWrapper.height: root.openHeight
            }
        }

        transitions: Transition {
            id: dialogTransition

            SequentialAnimation {
                ScriptAction {
                    script: root.reparentWrapper()
                }
                Anim {
                    properties: "x,y"
                }
            }
            PropertyAction {
                property: "enabled"
            }
            Anim {
                properties: "opacity,radius,bottomLeftRadius,bottomRightRadius"
                type: Anim.DefaultEffects
            }
            Anim {
                properties: "width,height"
            }
        }

        Elevation {
            id: elevation

            transform: Matrix4x4 {
                matrix: dialogBg.deformMatrix
            }

            anchors.fill: parent
            radius: dialogBg.radius
            bottomLeftRadius: dialogBg.bottomLeftRadius
            bottomRightRadius: dialogBg.bottomRightRadius
            level: 4
            opacity: 0
        }

        BlobRect {
            id: dialogBg

            anchors.fill: parent

            deformScale: 0.00005
            group: blobGroup
            opacity: blobGroup.color.a

            radius: Tokens.rounding.extraSmall
            bottomLeftRadius: Tokens.rounding.extraLarge
            bottomRightRadius: Tokens.rounding.extraLarge
        }

        RowButton {
            id: openButton

            transform: Matrix4x4 {
                matrix: dialogBg.deformMatrix
            }

            anchors.left: parent.left
            anchors.right: parent.right
            height: Math.min(implicitHeight, parent.height) // Clamp to parent height due to overshoot anim
            color: "transparent"

            last: true
            icon: root.icon
            text: root.label
            onClicked: root.open = true
        }

        Loader {
            id: dialogContent

            transform: Matrix4x4 {
                matrix: dialogBg.deformMatrix
            }

            anchors.fill: parent

            opacity: 0
            active: opacity > 0
            asynchronous: true

            sourceComponent: MouseArea {
                onWheel: event => event.accepted = true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Tokens.padding.extraLarge
                    anchors.bottomMargin: Tokens.padding.largeIncreased
                    spacing: 0

                    StyledText {
                        text: root.header
                        font: Tokens.font.title.builders.large.weight(Font.Normal).build()
                    }

                    Loader {
                        Layout.topMargin: Tokens.spacing.medium
                        Layout.fillWidth: true
                        active: root.separateContent
                        sourceComponent: StyledRect {
                            implicitHeight: 1
                            color: Colours.palette.m3outline
                        }
                    }

                    Loader {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.leftMargin: root.horizontalContentMargin
                        Layout.rightMargin: root.horizontalContentMargin
                        sourceComponent: root.content
                    }

                    Loader {
                        Layout.bottomMargin: Tokens.spacing.medium
                        Layout.fillWidth: true
                        active: root.separateContent
                        sourceComponent: StyledRect {
                            implicitHeight: 1
                            color: Colours.palette.m3outline
                        }
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignRight
                        spacing: Tokens.spacing.extraSmall

                        TextButton {
                            type: TextButton.Text
                            isRound: true
                            horizontalPadding: Tokens.padding.largeIncreased
                            verticalPadding: Tokens.padding.medium
                            text: qsTr("Cancel")
                            onClicked: {
                                root.cancelled();
                                root.open = false;
                            }
                        }

                        TextButton {
                            type: TextButton.Text
                            isRound: true
                            horizontalPadding: Tokens.padding.largeIncreased
                            verticalPadding: Tokens.padding.medium
                            disabled: !root.acceptAllowed
                            text: root.acceptLabel
                            onClicked: {
                                root.accepted();
                                root.open = false;
                            }
                        }
                    }
                }
            }
        }
    }
}
