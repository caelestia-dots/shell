pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Quickshell
import Caelestia.Config
import Caelestia.Models
import Caelestia.Scheme
import qs.components
import qs.components.effects
import qs.utils

Item {
    id: root

    required property string image
    required property string icon
    required property int urgency
    required property string summary
    property real progress: 0

    readonly property color fillColour: urgency === NotifData.Critical ? Colours.palette.error : urgency === NotifData.Low ? Colours.layer(Colours.palette.surfaceContainerHighest, 2) : Colours.palette.secondaryContainer
    readonly property color iconColour: urgency === NotifData.Critical ? Colours.palette.onError : urgency === NotifData.Low ? Colours.palette.onSurface : Colours.palette.onSecondaryContainer

    implicitWidth: TokenConfig.sizes.notifs.image
    implicitHeight: TokenConfig.sizes.notifs.image

    Component {
        id: imageComp

        Image {
            source: Qt.resolvedUrl(root.image)
            fillMode: Image.PreserveAspectCrop
            sourceSize: {
                const size = TokenConfig.sizes.notifs.image * ((QsWindow.window as QsWindow)?.devicePixelRatio ?? 1);
                return Qt.size(size, size);
            }
            cache: false
            asynchronous: true
            width: TokenConfig.sizes.notifs.image
            height: TokenConfig.sizes.notifs.image
        }
    }

    Component {
        id: appIconComp

        ColouredIcon {
            implicitSize: Math.round(TokenConfig.sizes.notifs.image * 0.6)
            source: Quickshell.iconPath(root.icon)
            colour: root.iconColour
            layer.enabled: root.icon.endsWith("symbolic")
        }
    }

    Component {
        id: materialIconComp

        MaterialIcon {
            text: Icons.getNotifIcon(root.summary, root.urgency)
            color: root.iconColour
            fontStyle: Tokens.font.icon.medium
        }
    }

    ClipRect {
        anchors.fill: parent
        color: root.fillColour
        radius: Tokens.rounding.full

        Loader {
            asynchronous: true
            anchors.centerIn: parent
            anchors.verticalCenterOffset: sourceComponent === materialIconComp ? 1 : 0
            sourceComponent: root.image ? imageComp : root.icon ? appIconComp : materialIconComp
        }
    }

    Loader {
        asynchronous: true
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        active: root.icon && root.image

        sourceComponent: StyledRect {
            implicitWidth: Tokens.sizes.notifs.badge
            implicitHeight: Tokens.sizes.notifs.badge

            color: root.fillColour
            radius: Tokens.rounding.full

            ColouredIcon {
                anchors.centerIn: parent
                implicitSize: Math.round(Tokens.sizes.notifs.badge * 0.6)
                source: Quickshell.iconPath(root.icon)
                colour: root.iconColour
                layer.enabled: root.icon.endsWith("symbolic")
            }
        }
    }

    Loader {
        asynchronous: true
        anchors.centerIn: parent
        active: root.progress > 0

        sourceComponent: Shape {
            id: progressIndicator

            width: root.width + progressShape.strokeWidth * 2
            height: root.height + progressShape.strokeWidth * 2
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                id: progressShape

                capStyle: ShapePath.RoundCap
                fillColor: "transparent"
                strokeWidth: 2
                strokeColor: Colours.palette.primary

                PathAngleArc {
                    radiusX: progressIndicator.width / 2 - root.Tokens.padding.extraSmall / 2
                    centerX: progressIndicator.width / 2
                    radiusY: progressIndicator.height / 2 - root.Tokens.padding.extraSmall / 2
                    centerY: progressIndicator.height / 2

                    startAngle: -90
                    sweepAngle: root.progress * 360

                    Behavior on sweepAngle {
                        Anim {
                            easing: Tokens.anim.emphasizedDecel
                        }
                    }
                }
            }
        }
    }
}
