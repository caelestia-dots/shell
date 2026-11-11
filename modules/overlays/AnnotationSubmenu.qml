pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import M3Shapes
import Caelestia
import Caelestia.Components
import Caelestia.Config
import Caelestia.Scheme
import qs.components
import qs.components.controls

AnimLoader {
    id: root

    required property AnnotationDocument document

    sourceComp: penControls

    Component {
        id: penControls

        RowLayout {
            spacing: Tokens.spacing.small

            Swatches {
                selectedColour: root.document.color
                onSelected: c => root.document.color = c
            }

            StyledText {
                Layout.leftMargin: Tokens.spacing.small
                text: "1"
                color: Colours.palette.onSecondaryContainer
                font: Tokens.font.label.small
            }

            StyledSlider {
                handleHeight: dragging ? 2.8 : 2.4
                bgColour: Colours.palette.primaryContainer
                from: 1
                to: 10
                stepSize: 1
                value: root.document.strokeWidth
                onInteraction: v => root.document.strokeWidth = valueAt(v)
            }

            StyledText {
                Layout.rightMargin: Tokens.padding.extraSmall
                text: "10"
                color: Colours.palette.onSecondaryContainer
                font: Tokens.font.label.small
            }
        }
    }

    component Swatches: RowLayout {
        id: swatches

        required property color selectedColour

        signal selected(colour: color)

        spacing: Tokens.spacing.extraSmall

        Repeater {
            id: swatchRepeater

            model: [Colours.palette.primary, Colours.palette.secondary, Colours.palette.tertiary, Colours.palette.error]

            Swatch {
                selected: modelData === swatches.selectedColour
                onClicked: swatches.selected(modelData)
            }
        }

        Swatch {
            modelData: selected ? swatches.selectedColour : Colours.palette.surface
            selected: !swatchRepeater.model.includes(swatches.selectedColour)
            onClicked: swatches.selected(Colours.palette.tertiary) // TODO: open colour picker
        }
    }

    component Swatch: MouseArea {
        id: swatch

        required property color modelData
        required property bool selected

        readonly property real spacing: Tokens.spacing.extraSmall

        implicitWidth: swatchShape.implicitSize + (spacing + swatchOutline.strokeWidth) * 2
        implicitHeight: swatchShape.implicitSize + (spacing + swatchOutline.strokeWidth) * 2

        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true

        MaterialShape {
            id: swatchShape

            anchors.centerIn: parent
            implicitSize: Tokens.padding.large
            shape: swatch.selected ? MaterialShape.VerySunny : MaterialShape.Circle
            color: swatch.modelData

            Behavior on color {
                CAnim {}
            }
        }

        Shape {
            preferredRendererType: Shape.CurveRenderer
            opacity: swatch.selected || swatch.pressed ? 1 : swatch.containsMouse ? 0.7 : 0

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            ShapePath {
                id: swatchOutline

                capStyle: ShapePath.RoundCap
                fillColor: "transparent"
                strokeWidth: 2
                strokeColor: Colours.palette.primary

                PathPolyline {
                    function pointAt(angle: real): point {
                        const dist = swatchShape.distanceAtAngle(angle) + swatchOutline.strokeWidth / 2 + swatch.spacing;
                        const rad = angle * Math.PI / 180;
                        return Qt.point(swatch.width / 2 + dist * Math.sin(rad), swatch.height / 2 - dist * Math.cos(rad));
                    }

                    path: {
                        CUtils.dependency(swatchShape.morphProgress);
                        const points = [];
                        for (let angle = 0; angle < 360; angle += 3)
                            points.push(pointAt(angle));
                        points.push(pointAt(360));
                        return points;
                    }
                }

                Behavior on strokeColor {
                    CAnim {}
                }
            }
        }
    }
}
