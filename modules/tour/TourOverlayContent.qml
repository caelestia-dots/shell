import qs.components
import qs.config
import qs.services
import Quickshell
import QtQuick
import QtQuick.Shapes

Item {
    id: root
    
    property rect targetRect: Tour.targetRect
    
    opacity: 0
    
    Behavior on opacity {
        NumberAnimation {
            duration: Appearance.anim.durations.normal
            easing.type: Easing.InOutQuad
        }
    }

    Shape {
        id: dimShape
        anchors.fill: parent
        
        ShapePath {
            fillColor: Qt.rgba(0, 0, 0, 0.5)
            strokeColor: "transparent"
            
            PathSvg {
                path: {
                    const w = dimShape.width;
                    const h = dimShape.height;
                    const x = root.targetRect.x - Appearance.padding.large;
                    const y = root.targetRect.y - Appearance.padding.large;
                    const rw = root.targetRect.width + Appearance.padding.large * 2;
                    const rh = root.targetRect.height + Appearance.padding.large * 2;
                    const r = Appearance.rounding.normal;
                    
                    if (root.targetRect.width <= 0 || root.targetRect.height <= 0) {
                        return `M 0,0 L ${w},0 L ${w},${h} L 0,${h} Z`;
                    }
                    
                    return `M 0,0 L ${w},0 L ${w},${h} L 0,${h} Z 
                            M ${x + r},${y} 
                            L ${x + rw - r},${y} 
                            Q ${x + rw},${y} ${x + rw},${y + r} 
                            L ${x + rw},${y + rh - r} 
                            Q ${x + rw},${y + rh} ${x + rw - r},${y + rh} 
                            L ${x + r},${y + rh} 
                            Q ${x},${y + rh} ${x},${y + rh - r} 
                            L ${x},${y + r} 
                            Q ${x},${y} ${x + r},${y} Z`;
                }
            }
        }
    }

    Rectangle {
        id: highlightBorder
        x: root.targetRect.x - Appearance.padding.large
        y: root.targetRect.y - Appearance.padding.large
        width: root.targetRect.width + Appearance.padding.large * 2
        height: root.targetRect.height + Appearance.padding.large * 2
        color: "transparent"
        border.color: Colours.palette.m3primary
        border.width: 3
        radius: Appearance.rounding.normal
        visible: root.targetRect.width > 0

        Behavior on x { Anim { duration: Appearance.anim.durations.normal; easing.bezierCurve: Appearance.anim.curves.emphasized } }
        Behavior on y { Anim { duration: Appearance.anim.durations.normal; easing.bezierCurve: Appearance.anim.curves.emphasized } }
        Behavior on width { Anim { duration: Appearance.anim.durations.normal; easing.bezierCurve: Appearance.anim.curves.emphasized } }
        Behavior on height { Anim { duration: Appearance.anim.durations.normal; easing.bezierCurve: Appearance.anim.curves.emphasized } }

        SequentialAnimation on opacity {
            running: highlightBorder.visible
            loops: Animation.Infinite
            NumberAnimation { from: 1.0; to: 0.3; duration: 1000; easing.type: Easing.InOutQuad }
            NumberAnimation { from: 0.3; to: 1.0; duration: 1000; easing.type: Easing.InOutQuad }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.visible
        hoverEnabled: true
        acceptedButtons: Qt.AllButtons
        z: 1
        
        onClicked: mouse => {
            const rect = root.targetRect;
            const inTarget = mouse.x >= rect.x && mouse.x <= rect.x + rect.width &&
                           mouse.y >= rect.y && mouse.y <= rect.y + rect.height;
            const inCloseButton = mouse.x >= closeButton.x && mouse.x <= closeButton.x + closeButton.width &&
                                mouse.y >= closeButton.y && mouse.y <= closeButton.y + closeButton.height;
            
            if (!inTarget && !inCloseButton) {
                mouse.accepted = true;
            } else {
                mouse.accepted = false;
            }
        }
    }

    Rectangle {
        id: closeButton
        
        property real targetX: root.targetRect.x + root.targetRect.width + Appearance.padding.normal
        property real targetY: root.targetRect.y - Appearance.padding.large
        
        x: Math.max(Appearance.padding.normal, Math.min(targetX, parent.width - width - Appearance.padding.normal))
        y: Math.max(Appearance.padding.normal, Math.min(targetY, parent.height - height - Appearance.padding.normal))
        
        width: 40
        height: 40
        radius: Appearance.rounding.full
        color: Colours.palette.m3errorContainer
        visible: root.targetRect.width > 0
        z: 2
        
        Text {
            anchors.centerIn: parent
            text: "✕"
            font.pixelSize: 20
            font.bold: true
            color: Colours.palette.m3onErrorContainer
        }
        
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Quickshell.execDetached(["quickshell", "ipc", "-c", "caelestia", "call", "tour", "clear"])
        }
        
        Behavior on x { Anim { duration: Appearance.anim.durations.normal; easing.bezierCurve: Appearance.anim.curves.emphasized } }
        Behavior on y { Anim { duration: Appearance.anim.durations.normal; easing.bezierCurve: Appearance.anim.curves.emphasized } }
    }
}
