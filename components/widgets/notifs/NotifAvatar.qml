pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Quickshell
import M3Shapes
import Caelestia.Config
import Caelestia.Models
import Caelestia.Multimedia
import Caelestia.Scheme
import qs.components
import qs.components.effects
import qs.components.widgets
import qs.utils

Item {
    id: root

    required property string image
    required property string icon
    required property int urgency
    required property string summary
    required property color lowFillColour
    property real progress: 0
    property string shownImage
    property string shownIcon

    readonly property color fillColour: urgency === NotifData.Critical ? Colours.palette.error : urgency === NotifData.Low ? lowFillColour : Colours.palette.secondaryContainer
    readonly property color iconColour: urgency === NotifData.Critical ? Colours.palette.onError : urgency === NotifData.Low ? Colours.palette.onSurfaceVariant : Colours.palette.onSecondaryContainer

    implicitWidth: TokenConfig.sizes.notifs.image
    implicitHeight: TokenConfig.sizes.notifs.image

    onImageChanged: {
        if (image)
            shownImage = image;
    }
    onIconChanged: {
        if (icon)
            shownIcon = icon;
    }
    Component.onCompleted: {
        shownImage = image;
        shownIcon = icon;
    }

    Component {
        id: imageComp

        FadeImage {
            source: Qt.resolvedUrl(root.shownImage)
            width: TokenConfig.sizes.notifs.image
            height: TokenConfig.sizes.notifs.image
            fadeInLargeAnim: Anim.DefaultEffects
        }
    }

    Component {
        id: appIconComp

        FadeIcon {
            size: Math.round(TokenConfig.sizes.notifs.image * 0.6)
        }
    }

    Component {
        id: materialIconComp

        MaterialIcon {
            animate: true
            text: Icons.getNotifIcon(root.summary, root.urgency)
            color: root.iconColour
            fontStyle: Tokens.font.icon.medium
        }
    }

    MaterialShape {
        id: bgShape

        anchors.fill: parent
        shape: contentLoader.sourceComponent === materialIconComp && root.urgency === NotifData.Critical ? MaterialShape.SoftBurst : MaterialShape.Circle
        color: Qt.alpha(root.fillColour, 1)
        layer.enabled: true
        opacity: root.fillColour.a

        Behavior on color {
            CAnim {}
        }

        Behavior on opacity {
            Anim {
                type: Anim.SlowEffects
            }
        }
    }

    Item {
        anchors.fill: parent
        layer.enabled: true
        layer.effect: Mask {
            maskSource: bgShape
        }

        AnimLoader {
            id: contentLoader

            anchors.centerIn: parent
            anchors.verticalCenterOffset: sourceComponent === materialIconComp ? 1 : 0
            sourceComp: root.image ? imageComp : root.icon ? appIconComp : materialIconComp
        }
    }

    Loader {
        asynchronous: true
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        active: opacity > 0
        opacity: root.icon && root.image ? 1 : 0

        sourceComponent: StyledRect {
            implicitWidth: Tokens.sizes.notifs.badge
            implicitHeight: Tokens.sizes.notifs.badge

            color: root.fillColour
            radius: Tokens.rounding.full

            FadeIcon {
                anchors.centerIn: parent
                size: Math.round(Tokens.sizes.notifs.badge * 0.6)
            }
        }

        Behavior on opacity {
            Anim {
                type: root.icon && root.image ? Anim.DefaultEffects : Anim.FastEffects
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

    component FadeIcon: FadeImage {
        id: fadeIcon

        required property int size

        width: size
        height: size
        source: Quickshell.iconPath(root.shownIcon)
        fillMode: Image.PreserveAspectFit
        fadeInLargeAnim: Anim.DefaultEffects

        layer.enabled: root.shownIcon.endsWith("symbolic")
        layer.effect: Colouriser {
            sourceColor: analyser.dominantColour
            colorizationColor: root.iconColour

            VisualAnalyser {
                id: analyser

                source: fadeIcon.source
            }
        }
    }
}
