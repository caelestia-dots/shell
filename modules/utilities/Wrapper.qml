pragma ComponentBehavior: Bound

import qs.components
import qs.config
import Quickshell
import QtQuick

Item {
    id: root

    required property var visibilities
    required property Item sidebar

    readonly property PersistentProperties props: PersistentProperties {
        property bool recordingListExpanded: false
        property string recordingConfirmDelete
        property string recordingMode

        reloadableId: "utilities"
    }
    readonly property bool shouldBeActive: visibilities.sidebar || (visibilities.utilities && Config.utilities.enabled && !(visibilities.session && Config.session.enabled))

    visible: height > 0
    implicitHeight: 0
    implicitWidth: sidebar.visible ? sidebar.width : Config.utilities.sizes.width

    onStateChanged: {
        if (state === "visible" && timer.running) {
            timer.triggered();
            timer.stop();
        }
    }

    states: State {
        name: "visible"
        when: root.shouldBeActive

        PropertyChanges {
            root.implicitHeight: content.implicitHeight + Appearance.padding.large * 2
        }
    }

    transitions: [
        Transition {
            from: ""
            to: "visible"

            Anim {
                target: root
                property: "implicitHeight"
                duration: Appearance.anim.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
            }
        },
        Transition {
            from: "visible"
            to: ""

            Anim {
                target: root
                property: "implicitHeight"
                easing.bezierCurve: Appearance.anim.curves.emphasized
            }
        }
    ]

    Timer {
        id: timer

        running: true
        interval: Appearance.anim.durations.extraLarge
        onTriggered: {
            content.active = Qt.binding(() => root.shouldBeActive || root.visible);
            content.visible = true;
        }
    }

    Loader {
        id: content

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: Appearance.padding.large

        visible: false
        active: true

        sourceComponent: Content {
            implicitWidth: root.implicitWidth - Appearance.padding.large * 2
            props: root.props
            visibilities: root.visibilities
        }
    }
}
