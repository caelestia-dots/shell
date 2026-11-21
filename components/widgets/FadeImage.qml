import QtQuick
import Quickshell
import qs.components

Image {
    id: root

    property bool hadPrevious
    property bool fadingOut
    property bool preventInit
    property int fadeOutAnim: Anim.FastEffects
    property int fadeInAnim: Anim.DefaultEffects
    property int fadeInLargeAnim: Anim.StandardLarge

    function maybeStartInAnim(): void {
        if (!preventInit && !opacityInAnim.running && status === Image.Ready) {
            opacityInAnim.type = hadPrevious ? fadeInAnim : fadeInLargeAnim;
            opacityInAnim.start();
        }
    }

    asynchronous: true
    fillMode: Image.PreserveAspectCrop

    sourceSize: {
        const dpr = (QsWindow.window as QsWindow)?.devicePixelRatio ?? 1;
        return Qt.size(width * dpr, height * dpr);
    }

    retainWhileLoading: true
    opacity: 0

    onStatusChanged: maybeStartInAnim()
    onPreventInitChanged: maybeStartInAnim()

    Anim on opacity {
        id: opacityInAnim

        running: false
        to: 1
    }

    Behavior on source {
        SequentialAnimation {
            ScriptAction {
                script: opacityInAnim.stop()
            }
            PropertyAction {
                target: root
                property: "fadingOut"
                value: true
            }
            Anim {
                target: root
                property: "opacity"
                to: 0
                type: root.fadeOutAnim
            }
            PropertyAction {
                target: root
                property: "fadingOut"
                value: false
            }
            PropertyAction {
                target: root
                property: "hadPrevious"
                value: root.source
            }
            PropertyAction {}
            ScriptAction {
                script: root.maybeStartInAnim()
            }
        }
    }
}
