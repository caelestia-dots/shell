pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Quickshell
import M3Shapes
import Caelestia
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

    required property var owner
    required property string image
    required property string icon
    required property int urgency
    required property string summary
    required property color lowFillColour
    property real progress: 0
    property string shownImage
    property string shownIcon

    readonly property color fillColour: urgency === NotifData.Critical ? Colours.palette.primary : urgency === NotifData.Low ? lowFillColour : Colours.palette.secondaryContainer
    readonly property color iconColour: urgency === NotifData.Critical ? Colours.palette.onPrimary : urgency === NotifData.Low ? Colours.palette.onSurfaceVariant : Colours.palette.onSecondaryContainer

    implicitWidth: TokenConfig.sizes.notifs.image
    implicitHeight: TokenConfig.sizes.notifs.image

    onImageChanged: {
        if (image && !owner.isSameImage(shownImage))
            shownImage = image;
    }
    onIconChanged: {
        if (icon && !owner.isSameAppIcon(shownIcon))
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
        anchors.fill: parent
        active: root.progress > 0

        sourceComponent: Shape {
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                id: progressShape

                property real sweep: root.progress * 360
                property real spacing: root.urgency === NotifData.Critical ? root.Tokens.spacing.extraSmall : 0

                capStyle: ShapePath.RoundCap
                fillColor: "transparent"
                strokeWidth: 2
                strokeColor: Colours.palette.primary

                PathPolyline {
                    function pointAt(angle: real): point {
                        const dist = bgShape.distanceAtAngle(angle) + progressShape.strokeWidth / 2 + progressShape.spacing;
                        const rad = angle * Math.PI / 180;
                        return Qt.point(root.width / 2 + dist * Math.sin(rad), root.height / 2 - dist * Math.cos(rad));
                    }

                    path: {
                        CUtils.dependency(bgShape.morphProgress);
                        const points = [];
                        for (let angle = 0; angle < progressShape.sweep; angle += 3)
                            points.push(pointAt(angle));
                        points.push(pointAt(progressShape.sweep));
                        return points;
                    }
                }

                Behavior on sweep {
                    Anim {
                        easing: Tokens.anim.emphasizedDecel
                    }
                }

                Behavior on spacing {
                    Anim {}
                }

                Behavior on strokeColor {
                    CAnim {}
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
