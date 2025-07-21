pragma ComponentBehavior: Bound

import qs.widgets
import qs.services
import qs.utils
import qs.config
import QtQuick

Item {
    id: root

    required property Brightness.Monitor monitor
    property color colour: Colours.palette.m3primary
    readonly property Item child: child

    implicitWidth: child.implicitWidth
    implicitHeight: child.implicitHeight

    CustomMouseArea {
        anchors.top: parent.top
        anchors.bottom: child.top
        anchors.left: parent.left
        anchors.right: parent.right

        function onWheel(event: WheelEvent): void {
            if (event.angleDelta.y > 0)
                Audio.setVolume(Audio.volume + 0.1);
            else if (event.angleDelta.y < 0)
                Audio.setVolume(Audio.volume - 0.1);
        }
    }

    CustomMouseArea {
        anchors.top: child.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right

        function onWheel(event: WheelEvent): void {
            const monitor = root.monitor;
            if (event.angleDelta.y > 0)
                monitor.setBrightness(monitor.brightness + 0.1);
            else if (event.angleDelta.y < 0)
                monitor.setBrightness(monitor.brightness - 0.1);
        }
    }

    Item {
        id: child

        property Item current: text1

        anchors.centerIn: parent

        clip: true
        implicitWidth: Math.max(icon.implicitWidth, current.implicitHeight)
        implicitHeight: icon.implicitHeight + current.implicitWidth + current.anchors.topMargin

        MaterialIcon {
            id: icon

            animate: true
            text: Icons.getAppCategoryIcon(Hyprland.activeToplevel?.lastIpcObject.class, "desktop_windows")
            color: root.colour

            anchors.horizontalCenter: parent.horizontalCenter
        }

        Title {
            id: text1
        }

        Title {
            id: text2
        }

        TextMetrics {
            id: metrics

            text: Hyprland.activeToplevel?.title ?? qsTr("Desktop")
            font.pointSize: Appearance.font.size.smaller
            font.family: Appearance.font.family.mono
            elide: Qt.ElideRight
            elideWidth: root.height - icon.height

            onTextChanged: {
                const next = child.current === text1 ? text2 : text1;
                next.text = elidedText;
                child.current = next;
            }
            onElideWidthChanged: child.current.text = elidedText
        }

        Behavior on implicitWidth {
            NumberAnimation {
                duration: Appearance.anim.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.anim.curves.emphasized
            }
        }

        Behavior on implicitHeight {
            NumberAnimation {
                duration: Appearance.anim.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.anim.curves.emphasized
            }
        }
    }

    component Title: StyledText {
        id: text

        anchors.horizontalCenter: icon.horizontalCenter
        anchors.top: icon.bottom
        anchors.topMargin: Appearance.spacing.small

        font.pointSize: metrics.font.pointSize
        font.family: metrics.font.family
        color: root.colour
        opacity: child.current === this ? 1 : 0

        transform: Rotation {
            angle: 90
            origin.x: text.implicitHeight / 2
            origin.y: text.implicitHeight / 2
        }

        width: implicitHeight
        height: implicitWidth

        Behavior on opacity {
            NumberAnimation {
                duration: Appearance.anim.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.anim.curves.standard
            }
        }
    }
}
