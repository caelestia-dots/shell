pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Components
import Caelestia.Config
import Caelestia.Scheme
import qs.components
import qs.components.controls

StyledRect {
    id: root

    required property DialogState dState

    implicitHeight: Math.max(backButton.implicitHeight, upButton.implicitHeight, location.implicitHeight) + Tokens.padding.medium * 2

    color: Colours.tPalette.surfaceContainer

    NavButton {
        id: backButton

        disabled: root.dState.cwdStack.length === 0
        icon: "arrow_back"
        onClicked: root.dState.cdBack()
    }

    NavButton {
        id: upButton

        anchors.left: backButton.right
        anchors.leftMargin: Tokens.spacing.extraSmall / 2

        disabled: root.dState.cwd.length === 1
        icon: "arrow_upward"
        label.anchors.verticalCenterOffset: 0
        onClicked: root.dState.cdUp()
    }

    StyledRect {
        id: location

        anchors.left: upButton.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: Tokens.spacing.small
        anchors.margins: Tokens.padding.medium

        radius: Tokens.rounding.full
        color: Colours.tPalette.surfaceContainerHigh

        implicitHeight: pathComponents.implicitHeight + pathComponents.anchors.margins * 2

        ButtonRow {
            id: pathComponents

            anchors.fill: parent
            anchors.margins: Tokens.padding.extraSmall

            spacing: Tokens.spacing.extraSmall

            AnimatedRepeater {
                id: repeater

                // -1 so we don't show root unless it's the only one
                model: Math.max(root.dState.cwd.length - 1, 1)

                removeDuration: Tokens.anim.durations.expressiveSlowEffects

                TextButton {
                    id: folder

                    required property int index
                    readonly property bool ignoreLayout: AnimatedRepeater.removing // For ButtonRow

                    Component.onCompleted: {
                        text = root.dState.cwd[index + 1] || "/";
                        label.animate = true;
                    }

                    isRound: true
                    shapeMorph: true
                    font: Tokens.font.label.medium
                    horizontalPadding: Tokens.padding.large
                    disabled: index === repeater.count - 1
                    onClicked: root.dState.cdTo(root.dState.cwd.slice(0, index + 2))

                    topLeftRadius: index === 0 ? Tokens.rounding.full : undefined
                    bottomLeftRadius: index === 0 ? Tokens.rounding.full : undefined

                    inactiveColour: Qt.alpha(Colours.palette.primaryContainer, 0)
                    inactiveOnColour: Colours.palette.onSurfaceVariant
                    disabledColour: Colours.palette.primaryContainer
                    disabledOnColour: Colours.palette.onPrimaryContainer

                    opacity: AnimatedRepeater.adding || AnimatedRepeater.removing ? 0 : 1

                    Behavior on opacity {
                        Anim {
                            type: Anim.SlowEffects
                        }
                    }

                    Behavior on implicitWidth {
                        enabled: !folder.AnimatedRepeater.adding

                        Anim {}
                    }

                    Connections {
                        function onCwdChanged(): void {
                            const label = root.dState.cwd[folder.index + 1];
                            if (repeater.count === 1 || label !== undefined)
                                folder.text = label || "/";
                        }

                        target: root.dState
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }
        }
    }

    component NavButton: IconButton {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: Tokens.padding.medium
        implicitWidth: {
            const w = height - Tokens.padding.extraSmall * 2;
            return w + (w % 2);
        }

        type: IconButton.Text
        isRound: true
    }
}
