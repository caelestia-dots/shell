pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services

Loader {
    id: root

    required property var props
    required property matrix4x4 deformMatrix

    asynchronous: true
    anchors.fill: parent

    opacity: root.props.recordingConfirmDelete ? 1 : 0
    active: opacity > 0

    sourceComponent: MouseArea {
        id: deleteConfirmation

        property string path

        Component.onCompleted: path = root.props.recordingConfirmDelete

        hoverEnabled: true
        onClicked: root.props.recordingConfirmDelete = ""

        Item {
            anchors.fill: parent
            anchors.margins: -Tokens.padding.large
            anchors.rightMargin: -Tokens.padding.large - Config.border.thickness
            anchors.bottomMargin: -Tokens.padding.large - Config.border.thickness
            opacity: 0.5

            StyledRect {
                anchors.fill: parent
                anchors.rightMargin: -parent.width * (1 - root.deformMatrix.m11) / 2 // Additional bit to account for deform
                anchors.bottomMargin: -parent.height * 0.1 // Additional bit to account for overshoot
                topLeftRadius: Tokens.rounding.large
                color: Colours.palette.m3scrim
            }

            Shape {
                id: shape

                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                asynchronous: true

                // Bottom left
                ShapePath {
                    startX: -root.Config.border.smoothing * 2
                    startY: shape.height - root.Config.border.thickness
                    strokeWidth: 0
                    fillGradient: LinearGradient {
                        orientation: LinearGradient.Horizontal
                        x1: -root.Config.border.smoothing * 2

                        GradientStop {
                            position: 0
                            color: Qt.alpha(Colours.palette.m3scrim, 0)
                        }
                        GradientStop {
                            position: 1
                            color: Colours.palette.m3scrim
                        }
                    }

                    PathLine {
                        relativeX: root.Config.border.smoothing
                        relativeY: 0
                    }
                    PathCubic {
                        relativeX: root.Config.border.smoothing
                        relativeY: -root.Config.border.smoothing
                        relativeControl1X: root.Config.border.smoothing * 0.93
                        relativeControl1Y: -root.Config.border.smoothing * 0.07
                        relativeControl2X: root.Config.border.smoothing * 0.93
                        relativeControl2Y: -root.Config.border.smoothing * 0.07
                    }
                    PathLine {
                        relativeX: 0
                        relativeY: root.Config.border.smoothing + root.Config.border.thickness
                    }
                    PathLine {
                        relativeX: -root.Config.border.smoothing * 2
                        relativeY: 0
                    }
                }

                // Top right curve
                ShapePath {
                    startX: shape.width - root.Config.border.smoothing - root.Config.border.thickness + (1 - root.deformMatrix.m11) * shape.width / 2
                    strokeWidth: 0
                    fillGradient: LinearGradient {
                        orientation: LinearGradient.Vertical
                        y1: -root.Config.border.smoothing * 2

                        GradientStop {
                            position: 0
                            color: Qt.alpha(Colours.palette.m3scrim, 0)
                        }
                        GradientStop {
                            position: 1
                            color: Colours.palette.m3scrim
                        }
                    }

                    PathCubic {
                        relativeX: root.Config.border.smoothing
                        relativeY: -root.Config.border.smoothing
                        relativeControl1X: root.Config.border.smoothing * 0.93
                        relativeControl1Y: -root.Config.border.smoothing * 0.07
                        relativeControl2X: root.Config.border.smoothing * 0.93
                        relativeControl2Y: -root.Config.border.smoothing * 0.07
                    }
                    PathLine {
                        relativeX: 0
                        relativeY: -root.Config.border.smoothing
                    }
                    PathLine {
                        relativeX: root.Config.border.thickness
                        relativeY: 0
                    }
                    PathLine {
                        relativeX: 0
                    }
                }
            }
        }

        StyledRect {
            anchors.centerIn: parent
            radius: Tokens.rounding.large
            color: Colours.palette.m3surfaceContainerHigh

            scale: 0
            Component.onCompleted: scale = Qt.binding(() => root.props.recordingConfirmDelete ? 1 : 0)

            width: Math.min(parent.width - Tokens.padding.large * 2, implicitWidth)
            implicitWidth: deleteConfirmationLayout.implicitWidth + Tokens.padding.large * 3
            implicitHeight: deleteConfirmationLayout.implicitHeight + Tokens.padding.large * 3

            MouseArea {
                anchors.fill: parent
            }

            Elevation {
                anchors.fill: parent
                radius: parent.radius
                z: -1
                level: 3
            }

            ColumnLayout {
                id: deleteConfirmationLayout

                anchors.fill: parent
                anchors.margins: Tokens.padding.large * 1.5
                spacing: Tokens.spacing.normal

                StyledText {
                    text: qsTr("Delete recording?")
                    font.pointSize: Tokens.font.size.large
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Recording '%1' will be permanently deleted.").arg(deleteConfirmation.path)
                    color: Colours.palette.m3onSurfaceVariant
                    font.pointSize: Tokens.font.size.small
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                }

                RowLayout {
                    Layout.topMargin: Tokens.spacing.normal
                    Layout.alignment: Qt.AlignRight
                    spacing: Tokens.spacing.normal

                    TextButton {
                        text: qsTr("Cancel")
                        type: TextButton.Text
                        onClicked: root.props.recordingConfirmDelete = ""
                    }

                    TextButton {
                        text: qsTr("Delete")
                        type: TextButton.Text
                        onClicked: {
                            CUtils.deleteFile(Qt.resolvedUrl(root.props.recordingConfirmDelete));
                            root.props.recordingConfirmDelete = "";
                        }
                    }
                }
            }

            Behavior on scale {
                Anim {
                    type: Anim.DefaultSpatial
                }
            }
        }
    }

    Behavior on opacity {
        Anim {}
    }
}
