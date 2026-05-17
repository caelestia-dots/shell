pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

StackLayout {
    id: root

    property int animateDuration: 200
    property real inactiveScale: 0.98

    property int __prevCurrentIndex: 0

    function __animateProperty(target, propertyName, toValue) {
        const anim = Qt.createQmlObject('import qs.components; Anim {}', target, 'anim');
        anim.target = target;
        anim.property = propertyName;
        anim.to = toValue;
        anim.start(); //qmllint disable missing-property
    }

    clip: true

    onCurrentIndexChanged: {
        const oldChild = root.children[__prevCurrentIndex];
        const newChild = root.children[currentIndex];

        if (oldChild) {
            __animateProperty(oldChild, "opacity", 0);
            __animateProperty(oldChild, "scale", inactiveScale);
        }
        if (newChild) {
            __animateProperty(newChild, "opacity", 1);
            __animateProperty(newChild, "scale", 1);
        }

        __prevCurrentIndex = currentIndex;
    }

    Component.onCompleted: {
        for (let i = 0; i < root.children.length; i++) {
            const child = root.children[i];
            child.opacity = (i === currentIndex) ? 1 : 0;
            child.scale = (i === currentIndex) ? 1 : inactiveScale;
            child.visible = true;
        }
        __prevCurrentIndex = currentIndex;
    }
}
