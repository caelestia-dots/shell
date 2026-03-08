import QtQuick
import QtQuick.Shapes
import qs.services

Item {
    id: root

    implicitWidth: 128
    implicitHeight: 90.38

    property color accentColor: Colours.palette.m3primary
    property color primaryColor: Colours.palette.m3onSurface

    readonly property real designWidth: 128
    readonly property real designHeight: 90.38
    readonly property real aspectRatio: designWidth / designHeight

    Item {
        id: content
        width: root.designWidth
        height: root.designHeight
        anchors.centerIn: parent
        scale: Math.min(root.width / root.designWidth, root.height / root.designHeight)
        transformOrigin: Item.Center

        Shape {
            id: topShape
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: root.accentColor
                strokeColor: "transparent"

                PathSvg {
                    path: "m42.56,42.96c-7.76,1.6-16.36,4.22-22.44,6.22-.49.16-.88-.44-.53-.82,5.37-5.85,9.66-13.3,9.66-13.3,8.66-14.67,22.97-23.51,39.85-21.14,6.47.91,12.33,3.38,17.26,6.98.99.72,1.14,2.14.31,3.04-.4.44-.95.67-1.51.67-.34,0-.69-.09-1-.26-3.21-1.84-6.82-2.69-10.71-3.24-13.1-1.84-25.41,4.75-31.06,15.83-.94,1.84-.61,3.81.45,5.21.22.3.07.72-.29.8Z"
                }
            }
        }

        Shape {
            id: bottomShape
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: root.primaryColor
                strokeColor: "transparent"

                PathSvg {
                    path: "m103.02,51.8c-.65.11-1.26-.37-1.28-1.03-.06-1.96.15-3.89-.2-5.78-.28-1.48-1.66-2.5-3.16-2.34h-.05c-6.53.73-24.63,3.1-48,9.32-6.89,1.83-9.83,10-5.67,15.79,4.62,6.44,11.84,10.93,20.41,12.13,11.82,1.66,22.99-3.36,29.21-12.65.54-.81,1.54-1.17,2.47-.86.91.3,1.47,1.15,1.47,2.04,0,.33-.08.66-.24.98-7.23,14.21-22.91,22.95-39.59,20.6-7.84-1.1-14.8-4.5-20.28-9.43,0,0,0,0-.02-.01-7.28-5.14-14.7-9.99-27.24-11.98-18.82-2.98-9.53-8.75.46-13.78,7.36-3.13,25.17-7.9,36.24-10.73.16-.03.31-.06.47-.1,1.52-.4,3.2-.83,5.02-1.29,1.06-.26,1.93-.48,2.58-.64.09-.02.18-.04.26-.06.31-.08.56-.14.73-.18.03,0,.06-.01.08-.02.03,0,.05-.01.07-.02.02,0,.04,0,.06-.01.01,0,.03,0,.04-.01,0,0,.02,0,.03,0,.01,0,.02,0,.02,0,10.62-2.58,24.63-5.62,37.74-7.34,1.02-.13,2.03-.26,3.03-.37,7.49-.87,14.58-1.26,20.42-.81,25.43,1.95-4.71,16.77-15.12,18.61Z"
                }
            }
        }

        Shape {
            id: star1
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: root.accentColor
                strokeColor: "transparent"

                PathSvg {
                    path: "m98.12.06c-.29,2.08-1.72,8.42-8.36,9.19-.09,0-.09.13,0,.14,6.64.78,8.07,7.11,8.36,9.19.01.08.13.08.14,0,.29-2.08,1.72-8.42,8.36-9.19.09,0,.09-.13,0-.14-6.64-.78-8.07-7.11-8.36-9.19-.01-.08-.13-.08-.14,0Z"
                }
            }
        }

        Shape {
            id: star2
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: root.accentColor
                strokeColor: "transparent"

                PathSvg {
                    path: "m113.36,15.5c-.22,1.29-1.08,4.35-4.38,4.87-.08.01-.08.13,0,.14,3.3.52,4.17,3.58,4.38,4.87.01.08.13.08.14,0,.22-1.29,1.08-4.35,4.38-4.87.08-.01.08-.13,0-.14-3.3-.52-4.17-3.58-4.38-4.87-.01-.08-.13-.08-.14,0Z"
                }
            }
        }

        Shape {
            id: star3
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: root.accentColor
                strokeColor: "transparent"

                PathSvg {
                    path: "m112.69,65.22c-.19,1.01-.86,3.15-3.2,3.57-.08.01-.08.13,0,.14,2.34.42,3.01,2.56,3.2,3.57.01.08.13.08.14,0,.19-1.01.86-3.15,3.2-3.57.08-.01.08-.13,0-.14-2.34-.42-3.01-2.56-3.2-3.57-.01-.08-.13-.08-.14,0Z"
                }
            }
        }
    }
}
