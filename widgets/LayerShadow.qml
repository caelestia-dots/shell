import "root:/services"
import QtQuick.Effects

MultiEffect {
    anchors.fill: source
    shadowColor: Qt.alpha(Colours.palette.m3shadow, 0.7)
    shadowBlur: 10
}

