import qs.widgets
import qs.services
import qs.config
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property var list
    readonly property string math: list.search.text.slice(`${Config.launcher.actionPrefix}calc `.length)

    function onClicked(): void {
        Quickshell.execDetached(["sh", "-c", `qalc -t -m 100 '${root.math}' | wl-copy`]);
        root.list.visibilities.launcher = false;
    }

    implicitHeight: Config.launcher.sizes.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    onMathChanged: {
        if (math) {
            qalcProc.command = ["qalc", "-m", "100", math];
            qalcProc.running = true;
        }
    }

    StateLayer {
        radius: Appearance.rounding.full

        function onClicked(): void {
            root.onClicked();
        }
    }

    Binding {
        id: binding

        when: root.math.length > 0
        target: metrics
        property: "text"
    }

    Process {
        id: qalcProc

        stdout: StdioCollector {
            onStreamFinished: binding.value = text.trim()
        }
    }

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: Appearance.padding.larger

        spacing: Appearance.spacing.normal

        MaterialIcon {
            text: "function"
            font.pointSize: Appearance.font.size.extraLarge
            Layout.alignment: Qt.AlignVCenter
        }

        StyledText {
            id: result

            color: {
                if (metrics.text.includes("error: "))
                    return Colours.palette.m3error;
                if (!root.math)
                    return Colours.palette.m3onSurfaceVariant;
                return Colours.palette.m3onSurface;
            }

            text: metrics.elidedText
            font.pointSize: Appearance.font.size.normal

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter

            TextMetrics {
                id: metrics

                text: qsTr("Type an expression to calculate")
                font.family: result.font.family
                font.pointSize: result.font.pointSize
                elide: Text.ElideRight
                elideWidth: result.width
            }
        }

        StyledRect {
            color: Colours.palette.m3tertiary
            radius: Appearance.rounding.normal
            clip: true

            implicitWidth: (stateLayer.containsMouse ? label.implicitWidth + label.anchors.rightMargin : 0) + icon.implicitWidth + Appearance.padding.normal * 2
            implicitHeight: Math.max(label.implicitHeight, icon.implicitHeight) + Appearance.padding.small * 2

            Layout.alignment: Qt.AlignVCenter

            StateLayer {
                id: stateLayer

                color: Colours.palette.m3onTertiary

                function onClicked(): void {
                    Quickshell.execDetached(["app2unit", "--", "foot", "fish", "-C", `exec qalc -i '${root.math}'`]);
                    root.list.visibilities.launcher = false;
                }
            }

            StyledText {
                id: label

                anchors.verticalCenter: parent.verticalCenter
                anchors.right: icon.left
                anchors.rightMargin: Appearance.spacing.small

                text: qsTr("Open in calculator")
                color: Colours.palette.m3onTertiary
                font.pointSize: Appearance.font.size.normal

                opacity: stateLayer.containsMouse ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Appearance.anim.durations.normal
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.anim.curves.standard
                    }
                }
            }

            MaterialIcon {
                id: icon

                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: Appearance.padding.normal

                text: "open_in_new"
                color: Colours.palette.m3onTertiary
                font.pointSize: Appearance.font.size.large
            }

            Behavior on implicitWidth {
                NumberAnimation {
                    duration: Appearance.anim.durations.normal
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.anim.curves.emphasized
                }
            }
        }
    }
}
