import ".."
import QtQuick

Flickable {
    id: root

    maximumFlickVelocity: 3000

    rebound: Transition {
        Anim {
            properties: "x,y"
        }
    }
}
