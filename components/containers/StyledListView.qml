import QtQuick
import qs.components

ListView {
    id: root

    maximumFlickVelocity: 3000

    rebound: Transition {
        enabled: Math.abs(root.verticalOvershoot) >= 0.5 || Math.abs(root.horizontalOvershoot) >= 0.5

        onRunningChanged: {
            if (running)
                return;
            const x = root.contentX;
            const y = root.contentY;
            root.contentX = x + 1;
            root.contentY = y + 1;
            root.contentX = x;
            root.contentY = y;
        }

        Anim {
            properties: "x,y"
        }
    }
}
