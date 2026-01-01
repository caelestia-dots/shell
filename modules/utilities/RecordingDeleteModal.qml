pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.components.effects
import qs.services
import qs.config
import Caelestia
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes

Loader {
    id: root

    required property var props

    anchors.fill: parent

    opacity: root.props.recordingConfirmDelete ? 1 : 0
    active: opacity > 0
    asynchronous: true

    sourceComponent: MouseArea {
        id: deleteConfirmation

        property string path

        Component.onCompleted: path = root.props.recordingConfirmDelete

        hoverEnabled: true
        onClicked: root.props.recordingConfirmDelete = ""

        Item {
            anchors.fill: parent
            anchors.margins: -Appearance.padding.large
            anchors.rightMargin: -Appearance.padding.large - Config.border.thickness
            anchors.bottomMargin: -Appearance.padding.large - Config.border.thickness
            opacity: 0.5

            StyledRect {
                anchors.fill: parent
                topLeftRadius: Config.border.rounding
                color: Colours.palette.m3scrim
            }

            Shape {
                id: shape

                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                asynchronous: true

                ShapePath {
                    startX: -Config.border.rounding * 2
                    startY: shape.height - Config.border.thickness
                    strokeWidth: 0
                    fillGradient: LinearGradient {
                        orientation: LinearGradient.Horizontal
                        x1: -Config.border.rounding * 2

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
                        relativeX: Config.border.rounding
                        relativeY: 0
                    }
                    PathArc {
                        relativeY: -Config.border.rounding
                        radiusX: Config.border.rounding
                        radiusY: Config.border.rounding
                        direction: PathArc.Counterclockwise
                    }
                    PathLine {
                        relativeX: 0
                        relativeY: Config.border.rounding + Config.border.thickness
                    }
                    PathLine {
                        relativeX: -Config.border.rounding * 2
                        relativeY: 0
                    }
                }

                ShapePath {
                    startX: shape.width - Config.border.rounding - Config.border.thickness
                    strokeWidth: 0
                    fillGradient: LinearGradient {
                        orientation: LinearGradient.Vertical
                        y1: -Config.border.rounding * 2

                        GradientStop {
                            position: 0
                            color: Qt.alpha(Colours.palette.m3scrim, 0)
                        }
                        GradientStop {
                            position: 1
                            color: Colours.palette.m3scrim
                        }
                    }

                    PathArc {
                        relativeX: Config.border.rounding
                        relativeY: -Config.border.rounding
                        radiusX: Config.border.rounding
                        radiusY: Config.border.rounding
                        direction: PathArc.Counterclockwise
                    }
                    PathLine {
                        relativeX: 0
                        relativeY: -Config.border.rounding
                    }
                    PathLine {
                        relativeX: Config.border.thickness
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
            radius: Appearance.rounding.large
            color: Colours.palette.m3surfaceContainerHigh

            scale: 0
            Component.onCompleted: scale = Qt.binding(() => root.props.recordingConfirmDelete ? 1 : 0)

            width: Math.min(parent.width - Appearance.padding.large * 2, implicitWidth)
            implicitWidth: deleteConfirmationLayout.implicitWidth + Appearance.padding.large * 3
            implicitHeight: deleteConfirmationLayout.implicitHeight + Appearance.padding.large * 3

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
                anchors.margins: Appearance.padding.large * 1.5
                spacing: Appearance.spacing.normal

                StyledText {
                    text: qsTr("Delete recording?")
                    font.pointSize: Appearance.font.size.large
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Recording '%1' will be permanently deleted.").arg(deleteConfirmation.path)
                    color: Colours.palette.m3onSurfaceVariant
                    font.pointSize: Appearance.font.size.small
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                }

                RowLayout {
                    Layout.topMargin: Appearance.spacing.normal
                    Layout.alignment: Qt.AlignRight
                    spacing: Appearance.spacing.normal

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
                    duration: Appearance.anim.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                }
            }
        }
    }

    Behavior on opacity {
        Anim {}
    }
}
