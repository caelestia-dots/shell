import QtQuick
import QtQuick.Shapes

Item {
    id: root

    implicitWidth: 128
    implicitHeight: 90.32

    property bool lightTheme: true

    readonly property alias topShape: topShape
    readonly property alias bottomShape: bottomShape
    readonly property alias star1: star1
    readonly property alias star2: star2
    readonly property alias star3: star3

    Shape {
        id: topShape
        width: 128
        height: 90.32
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: root.lightTheme ? "#3b4656" : "#6ae5e1"
            strokeColor: "transparent"
            scale: Qt.size(0.08939103, 0.08939103)

            PathSvg {
                path: "m 475.79,480.32 c -86.73,17.9 -182.84,47.16 -250.83,69.53 -5.5,1.81 -9.8,-4.87 -5.89,-9.13 60.07,-65.44 108.05,-148.67 108.05,-148.67 96.79,-164.04 256.76,-262.84 445.51,-236.29 72.29,10.17 137.85,37.79 192.94,78.01 11.05,8.07 12.75,23.9 3.52,34 -4.45,4.87 -10.63,7.45 -16.89,7.45 -3.82,0 -7.66,-0.96 -11.16,-2.96 C 905.11,251.68 864.76,242.2 821.3,236.08 674.89,215.49 537.25,289.19 474.05,413.1 c -10.51,20.6 -6.82,42.54 5.03,58.29 2.5,3.32 0.78,8.1 -3.29,8.94 z"
            }
        }
    }

    Shape {
        id: bottomShape
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: root.lightTheme ? "#e8e8e8" : "#e8e8e8"
            strokeColor: "transparent"

            PathSvg {
                path: "M 102.94,51.76 c -0.65,0.11 -1.26,-0.37 -1.28,-1.03 -0.06,-1.96 0.15,-3.89 -0.20,-5.78 -0.28,-1.48 -1.66,-2.50 -3.16,-2.34 l -0.05,0.01 c -6.53,0.72 -24.61,3.09 -47.97,9.31 -6.89,1.83 -9.82,9.99 -5.66,15.78 4.62,6.43 11.83,10.92 20.40,12.13 11.81,1.66 22.98,-3.36 29.20,-12.64 0.54,-0.81 1.54,-1.17 2.46,-0.86 0.91,0.30 1.47,1.15 1.47,2.04 0,0.33 -0.08,0.66 -0.24,0.97 -7.23,14.20 -22.90,22.93 -39.56,20.59 -7.84,-1.10 -14.79,-4.50 -20.27,-9.42 0,-0 -0.01,-0.01 -0.02,-0.01 C 30.80,75.37 23.39,70.52 10.87,68.55 -7.95,65.59 1.34,59.77 11.33,54.76 c 7.36,-3.13 25.16,-7.90 36.21,-10.73 0.16,-0.03 0.31,-0.06 0.47,-0.10 1.52,-0.40 3.20,-0.83 5.02,-1.29 1.06,-0.26 1.93,-0.48 2.58,-0.64 0.09,-0.02 0.18,-0.04 0.26,-0.06 0.31,-0.08 0.56,-0.14 0.73,-0.18 0.03,-0.01 0.06,-0.01 0.08,-0.02 0.03,-0.01 0.05,-0.01 0.07,-0.02 0.02,0 0.04,-0.01 0.06,-0.01 0.01,0 0.03,-0.01 0.04,-0.01 0.01,0 0.02,0 0.03,-0.01 0.01,0 0.02,0 0.02,0 10.62,-2.58 24.61,-5.62 37.71,-7.34 1.02,-0.13 2.03,-0.26 3.03,-0.37 7.49,-0.87 14.57,-1.26 20.41,-0.81 25.41,1.94 -4.70,16.76 -15.11,18.60 z"
            }
        }
    }

    Shape {
        id: star1
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        opacity: 0.0

        ShapePath {
            fillColor: root.lightTheme ? "#3b4656" : "#6ae5e1"
            strokeColor: "transparent"

            PathSvg {
                path: "M 98.04,0.06 C 97.75,2.14 96.32,8.47 89.69,9.24 c -0.08,0.01 -0.08,0.13 0,0.14 6.63,0.78 8.06,7.10 8.36,9.19 0.01,0.08 0.13,0.08 0.14,0 0.29,-2.08 1.72,-8.41 8.36,-9.19 0.08,-0.01 0.08,-0.13 0,-0.14 -6.63,-0.78 -8.06,-7.10 -8.36,-9.19 -0.01,-0.08 -0.13,-0.08 -0.14,0 z"
            }
        }
    }

    Shape {
        id: star2
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        opacity: 0.0

        ShapePath {
            fillColor: root.lightTheme ? "#3b4656" : "#6ae5e1"
            strokeColor: "transparent"

            PathSvg {
                path: "M 113.27,15.48 c -0.22,1.29 -1.08,4.35 -4.38,4.86 -0.08,0.01 -0.08,0.13 0,0.14 3.3,0.52 4.16,3.58 4.38,4.86 0.01,0.08 0.13,0.08 0.14,0 0.22,-1.29 1.08,-4.35 4.38,-4.86 0.08,-0.01 0.08,-0.13 0,-0.14 -3.3,-0.52 -4.16,-3.58 -4.38,-4.86 -0.01,-0.08 -0.13,-0.08 -0.14,0 z"
            }
        }
    }

    Shape {
        id: star3
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        opacity: 0.0

        ShapePath {
            fillColor: root.lightTheme ? "#3b4656" : "#6ae5e1"
            strokeColor: "transparent"

            PathSvg {
                path: "M 112.60,65.16 c -0.19,1.01 -0.86,3.15 -3.20,3.57 -0.08,0.01 -0.08,0.13 0,0.14 2.34,0.42 3.01,2.56 3.20,3.57 0.01,0.08 0.13,0.08 0.14,0 0.19,-1.01 0.86,-3.15 3.20,-3.57 0.08,-0.01 0.08,-0.13 0,-0.14 -2.34,-0.42 -3.01,-2.56 -3.20,-3.57 -0.01,-0.08 -0.13,-0.08 -0.14,0 z"
            }
        }
    }
}
